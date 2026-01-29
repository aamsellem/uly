"""Serveur API ULY pour Cloudflare Tunnel.

Expose ULY via une API REST sécurisée.
Appelle Claude Code localement avec tout le contexte ULY.
"""

import asyncio
import json
import logging
import os
import subprocess
import time
from collections import defaultdict
from datetime import datetime
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException, Header, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import uvicorn

# Configuration des chemins
SCRIPT_DIR = Path(__file__).parent
ULY_ROOT = Path(os.environ.get("ULY_WORKSPACE", SCRIPT_DIR.parent.parent.parent))

# Charger les variables d'environnement
load_dotenv(SCRIPT_DIR / ".env")
load_dotenv(ULY_ROOT / ".env")

# Configuration
API_TOKEN = os.environ.get("ULY_API_TOKEN", "")
SERVER_PORT = int(os.environ.get("ULY_SERVER_PORT", "8787"))

# Rate limiting
RATE_LIMIT = 100  # requêtes par minute
rate_limit_store = defaultdict(list)

# Logging
logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)

# Application FastAPI
app = FastAPI(
    title="ULY API",
    description="API pour interagir avec ULY (Claude Code) via Cloudflare Tunnel",
    version="1.0.0",
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ========================================
# Modèles Pydantic
# ========================================

class AskRequest(BaseModel):
    """Requête pour poser une question à ULY."""
    message: str
    conversation_id: Optional[str] = None
    timeout: int = 120  # secondes


class AskResponse(BaseModel):
    """Réponse de ULY."""
    response: str
    conversation_id: Optional[str] = None
    duration_ms: int = 0


class HealthResponse(BaseModel):
    """Statut de santé du service."""
    status: str
    timestamp: str
    workspace: str
    claude_available: bool
    version: str


# ========================================
# Utilitaires
# ========================================

def check_rate_limit(client_ip: str) -> bool:
    """Vérifie le rate limiting."""
    now = time.time()
    minute_ago = now - 60

    # Nettoyer les anciennes entrées
    rate_limit_store[client_ip] = [
        t for t in rate_limit_store[client_ip] if t > minute_ago
    ]

    # Vérifier la limite
    if len(rate_limit_store[client_ip]) >= RATE_LIMIT:
        return False

    rate_limit_store[client_ip].append(now)
    return True


def verify_token(authorization: str = Header(None)) -> bool:
    """Vérifie le token d'authentification."""
    if not API_TOKEN:
        logger.warning("Aucun token API configuré - accès ouvert!")
        return True

    if not authorization:
        raise HTTPException(status_code=401, detail="Token d'authentification requis")

    # Format: "Bearer <token>"
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(
            status_code=401,
            detail="Format d'authentification invalide. Utilisez: Bearer <token>"
        )

    if parts[1] != API_TOKEN:
        raise HTTPException(status_code=401, detail="Token invalide")

    return True


def check_claude_available() -> bool:
    """Vérifie si Claude Code est disponible."""
    try:
        result = subprocess.run(
            ["claude", "--version"],
            capture_output=True,
            text=True,
            timeout=5
        )
        return result.returncode == 0
    except Exception:
        return False


async def call_claude(message: str, timeout: int = 120) -> str:
    """
    Appelle Claude Code en mode non-interactif.
    Utilise le workspace ULY avec tout son contexte.
    """
    try:
        # Créer le process Claude Code
        process = await asyncio.create_subprocess_exec(
            "claude",
            "-p", message,  # Mode print (non-interactif)
            "--no-spinner",  # Pas de spinner
            cwd=str(ULY_ROOT),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            env={**os.environ, "NO_COLOR": "1"}  # Désactiver les couleurs
        )

        # Attendre la réponse avec timeout
        try:
            stdout, stderr = await asyncio.wait_for(
                process.communicate(),
                timeout=timeout
            )
        except asyncio.TimeoutError:
            process.kill()
            await process.wait()
            raise HTTPException(
                status_code=504,
                detail=f"Timeout après {timeout} secondes"
            )

        if process.returncode != 0:
            error_msg = stderr.decode().strip() if stderr else "Erreur inconnue"
            logger.error(f"Claude Code a retourné une erreur: {error_msg}")
            raise HTTPException(
                status_code=502,
                detail=f"Erreur Claude Code: {error_msg}"
            )

        response = stdout.decode().strip()

        if not response:
            return "Je n'ai pas pu générer de réponse."

        return response

    except HTTPException:
        raise
    except FileNotFoundError:
        raise HTTPException(
            status_code=503,
            detail="Claude Code n'est pas installé ou accessible"
        )
    except Exception as e:
        logger.error(f"Erreur lors de l'appel à Claude: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Erreur serveur: {str(e)}"
        )


# ========================================
# Endpoints
# ========================================

@app.get("/", response_class=JSONResponse)
async def root():
    """Endpoint racine."""
    return {
        "service": "ULY API",
        "version": "1.0.0",
        "description": "API pour interagir avec ULY (Claude Code local)",
        "endpoints": {
            "POST /ask": "Envoyer un message à ULY",
            "GET /health": "Vérifier le statut du service"
        },
        "documentation": "/docs"
    }


@app.get("/health", response_model=HealthResponse)
async def health():
    """Vérification de santé du service."""
    claude_ok = check_claude_available()

    return HealthResponse(
        status="healthy" if claude_ok else "degraded",
        timestamp=datetime.now().isoformat(),
        workspace=str(ULY_ROOT),
        claude_available=claude_ok,
        version="1.0.0"
    )


@app.post("/ask", response_model=AskResponse)
async def ask(
    request: Request,
    body: AskRequest,
    authorization: str = Header(None)
):
    """
    Envoie un message à ULY et retourne la réponse.

    ULY est Claude Code qui tourne localement avec tout le contexte :
    - La personnalité configurée
    - L'état actuel (state/)
    - Les objectifs
    - L'historique des sessions
    """

    # Vérifier l'authentification
    verify_token(authorization)

    # Vérifier le rate limiting
    client_ip = request.client.host if request.client else "unknown"
    if not check_rate_limit(client_ip):
        raise HTTPException(
            status_code=429,
            detail="Rate limit dépassé. Maximum 100 requêtes par minute."
        )

    logger.info(f"Requête de {client_ip}: {body.message[:100]}...")

    # Mesurer le temps
    start_time = time.time()

    # Appeler Claude Code
    response = await call_claude(body.message, timeout=body.timeout)

    # Calculer la durée
    duration_ms = int((time.time() - start_time) * 1000)

    logger.info(f"Réponse générée en {duration_ms}ms")

    return AskResponse(
        response=response,
        conversation_id=body.conversation_id,
        duration_ms=duration_ms
    )


@app.post("/command/{command}")
async def run_command(
    command: str,
    request: Request,
    authorization: str = Header(None)
):
    """
    Exécute une commande ULY spécifique.

    Commandes disponibles:
    - /uly : Démarrer avec briefing
    - /update : Sauvegarde rapide
    - /end : Terminer la session
    - /report : Rapport hebdomadaire
    """

    verify_token(authorization)

    valid_commands = ["uly", "update", "end", "report", "help"]

    if command not in valid_commands:
        raise HTTPException(
            status_code=400,
            detail=f"Commande inconnue. Commandes valides: {', '.join(valid_commands)}"
        )

    logger.info(f"Exécution de la commande /{command}")

    start_time = time.time()
    response = await call_claude(f"/{command}", timeout=180)
    duration_ms = int((time.time() - start_time) * 1000)

    return {
        "command": command,
        "response": response,
        "duration_ms": duration_ms
    }


# ========================================
# Point d'entrée
# ========================================

if __name__ == "__main__":
    logger.info(f"Démarrage du serveur ULY API sur le port {SERVER_PORT}")
    logger.info(f"Workspace: {ULY_ROOT}")

    if not API_TOKEN:
        logger.warning("⚠️  ATTENTION: Aucun token API configuré - l'API est ouverte!")

    if not check_claude_available():
        logger.error("❌ Claude Code n'est pas disponible!")
        logger.error("   Installez-le avec: npm install -g @anthropic-ai/claude-code")
    else:
        logger.info("✓ Claude Code disponible")

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=SERVER_PORT,
        log_level="info"
    )
