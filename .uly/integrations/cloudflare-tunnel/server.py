"""Serveur API ULY pour Cloudflare Tunnel.

Expose ULY via une API REST sécurisée.
Appelle Claude Code localement avec tout le contexte ULY.
"""

import asyncio
import json
import logging
import os
import re
import subprocess
import time
import uuid
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

def get_daily_session_id() -> str:
    """Génère un UUID déterministe basé sur la date du jour.

    Utilise UUID v5 (SHA-1) avec un namespace fixe.
    Même date = même UUID, chaque jour = nouvel UUID.
    """
    # Namespace fixe pour ULY (UUID v4 arbitraire)
    ULY_NAMESPACE = uuid.UUID("a1b2c3d4-e5f6-7890-abcd-ef1234567890")
    date_str = datetime.now().strftime("%Y-%m-%d")
    return str(uuid.uuid5(ULY_NAMESPACE, date_str))

# IP Whitelist (optionnel) - séparées par des virgules
# Ex: "192.168.1.100,10.0.0.50" ou vide pour autoriser tout
IP_WHITELIST_RAW = os.environ.get("ULY_IP_WHITELIST", "").strip()
IP_WHITELIST = [ip.strip() for ip in IP_WHITELIST_RAW.split(",") if ip.strip()] if IP_WHITELIST_RAW else []

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
    session_id: Optional[str] = None  # Pour reprendre une conversation existante
    timeout: int = 120  # secondes


class AskResponse(BaseModel):
    """Réponse de ULY."""
    response: str
    session_id: Optional[str] = None  # ID de session pour continuer la conversation
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


def get_client_ip(request: Request) -> str:
    """
    Récupère l'IP réelle du client.
    Gère les headers Cloudflare et les proxies.
    """
    # Cloudflare envoie l'IP réelle dans CF-Connecting-IP
    cf_ip = request.headers.get("CF-Connecting-IP")
    if cf_ip:
        return cf_ip

    # Fallback sur X-Forwarded-For (premier IP de la chaîne)
    forwarded = request.headers.get("X-Forwarded-For")
    if forwarded:
        return forwarded.split(",")[0].strip()

    # Fallback sur X-Real-IP
    real_ip = request.headers.get("X-Real-IP")
    if real_ip:
        return real_ip

    # Dernier recours : IP directe
    return request.client.host if request.client else "unknown"


def check_ip_whitelist(request: Request) -> bool:
    """
    Vérifie si l'IP du client est dans la whitelist.
    Si la whitelist est vide, autorise tout.
    """
    if not IP_WHITELIST:
        return True  # Pas de whitelist = tout autorisé

    client_ip = get_client_ip(request)

    if client_ip in IP_WHITELIST:
        return True

    # Log la tentative bloquée
    logger.warning(f"IP bloquée: {client_ip} (whitelist: {IP_WHITELIST})")
    return False


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


async def call_claude(
    message: str,
    timeout: int = 120,
    session_id: Optional[str] = None
) -> tuple[str, Optional[str]]:
    """
    Appelle Claude Code en mode non-interactif.
    Utilise le workspace ULY avec tout son contexte.

    Args:
        message: Le message à envoyer
        timeout: Timeout en secondes
        session_id: ID de session pour reprendre une conversation

    Returns:
        Tuple (response, session_id)
    """
    try:
        # Utiliser le session_id quotidien si non fourni
        effective_session_id = session_id or get_daily_session_id()

        # Essayer d'abord --resume (session existe)
        # Si échec, utiliser --session-id (créer nouvelle session)
        for attempt, session_flag in enumerate(["--resume", "--session-id"]):
            args = ["claude", "-p", message, session_flag, effective_session_id]

            process = await asyncio.create_subprocess_exec(
                *args,
                cwd=str(ULY_ROOT),
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                env={**os.environ, "NO_COLOR": "1"}
            )

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

            error_msg = stderr.decode().strip() if stderr else ""

            # Si --resume échoue car session n'existe pas, essayer --session-id
            if process.returncode != 0 and "No conversation found" in error_msg and attempt == 0:
                logger.info(f"Session {effective_session_id} n'existe pas, création...")
                continue

            if process.returncode != 0:
                logger.error(f"Claude Code a retourné une erreur: {error_msg}")
                raise HTTPException(
                    status_code=502,
                    detail=f"Erreur Claude Code: {error_msg}"
                )

            # Succès
            break

        response = stdout.decode().strip()

        if not response:
            response = "Je n'ai pas pu générer de réponse."

        return response, effective_session_id

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
            "GET /health": "Vérifier le statut du service",
            "GET /pending": "Tâches en attente de retour (N8N)",
            "POST /command/{cmd}": "Exécuter une commande slash",
            "POST /raw": "Exécuter une commande brute"
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

    # Vérifier l'IP whitelist
    if not check_ip_whitelist(request):
        raise HTTPException(
            status_code=403,
            detail=f"IP non autorisée: {get_client_ip(request)}"
        )

    # Vérifier l'authentification
    verify_token(authorization)

    # Vérifier le rate limiting
    client_ip = get_client_ip(request)
    if not check_rate_limit(client_ip):
        raise HTTPException(
            status_code=429,
            detail="Rate limit dépassé. Maximum 100 requêtes par minute."
        )

    logger.info(f"Requête de {client_ip}: {body.message[:100]}...")
    if body.session_id:
        logger.info(f"  Session: {body.session_id}")

    # Mesurer le temps
    start_time = time.time()

    # Appeler Claude Code (avec session si fournie)
    response, session_id = await call_claude(
        body.message,
        timeout=body.timeout,
        session_id=body.session_id
    )

    # Calculer la durée
    duration_ms = int((time.time() - start_time) * 1000)

    logger.info(f"Réponse générée en {duration_ms}ms (session: {session_id})")

    return AskResponse(
        response=response,
        session_id=session_id,
        duration_ms=duration_ms
    )


class CommandRequest(BaseModel):
    """Requête pour exécuter une commande."""
    args: Optional[str] = None
    timeout: int = 180


@app.post("/command/{command:path}")
async def run_command(
    command: str,
    request: Request,
    body: Optional[CommandRequest] = None,
    authorization: str = Header(None)
):
    """
    Exécute n'importe quelle commande Claude Code.

    Exemples:
    - POST /command/uly → /uly
    - POST /command/update → /update
    - POST /command/commit → /commit
    - POST /command/help → /help

    Avec arguments dans le body:
    - POST /command/ask {"args": "recherche dans mes notes"}
    """

    # Vérifier l'IP whitelist
    if not check_ip_whitelist(request):
        raise HTTPException(
            status_code=403,
            detail=f"IP non autorisée: {get_client_ip(request)}"
        )

    verify_token(authorization)

    # Construire la commande complète
    full_command = f"/{command}"
    if body and body.args:
        full_command = f"{full_command} {body.args}"

    timeout = body.timeout if body else 180

    logger.info(f"Exécution: {full_command}")

    start_time = time.time()
    response, _ = await call_claude(full_command, timeout=timeout)
    duration_ms = int((time.time() - start_time) * 1000)

    return {
        "command": command,
        "full_command": full_command,
        "response": response,
        "duration_ms": duration_ms
    }


@app.post("/raw")
async def raw_command(
    request: Request,
    body: AskRequest,
    authorization: str = Header(None)
):
    """
    Exécute une commande brute telle quelle.

    Permet d'envoyer n'importe quoi à Claude Code :
    - Des commandes slash : "/uly", "/commit -m 'message'"
    - Des questions : "Quel est mon état ?"
    - Des instructions : "Crée un fichier test.md"
    """

    # Vérifier l'IP whitelist
    if not check_ip_whitelist(request):
        raise HTTPException(
            status_code=403,
            detail=f"IP non autorisée: {get_client_ip(request)}"
        )

    verify_token(authorization)

    client_ip = get_client_ip(request)
    if not check_rate_limit(client_ip):
        raise HTTPException(
            status_code=429,
            detail="Rate limit dépassé. Maximum 100 requêtes par minute."
        )

    logger.info(f"Commande brute de {client_ip}: {body.message[:100]}...")
    if body.session_id:
        logger.info(f"  Session: {body.session_id}")

    start_time = time.time()
    response, session_id = await call_claude(
        body.message,
        timeout=body.timeout,
        session_id=body.session_id
    )
    duration_ms = int((time.time() - start_time) * 1000)

    return {
        "input": body.message,
        "response": response,
        "session_id": session_id,
        "duration_ms": duration_ms
    }


class PendingResponse(BaseModel):
    """Réponse pour les tâches en attente."""
    has_pending: bool
    message: str  # Vide si rien en attente


def check_pending_tasks() -> bool:
    """
    Vérifie s'il y a des tâches ACTIVES en attente dans state/current.md.
    Ne regarde que la sous-section "### Actif", pas "### En pause".
    Retourne True si au moins une ligne "- [ ]" existe dans Actif.
    """
    state_file = ULY_ROOT / "state" / "current.md"

    if not state_file.exists():
        return False

    content = state_file.read_text()

    # Chercher la sous-section "### Actif" dans "## En Attente de Retour"
    in_attente = False
    in_actif = False

    for line in content.split("\n"):
        # Entrer dans "En Attente de Retour"
        if "## En Attente de Retour" in line:
            in_attente = True
            continue

        # Sortir si nouvelle section ##
        if in_attente and line.strip().startswith("## ") and "En Attente" not in line:
            break

        # Entrer dans "### Actif"
        if in_attente and "### Actif" in line:
            in_actif = True
            continue

        # Sortir de Actif si nouvelle sous-section ###
        if in_actif and line.strip().startswith("### "):
            in_actif = False
            continue

        # Chercher les tâches uniquement dans Actif
        if in_actif and line.strip().startswith("- [ ]"):
            return True

    return False


@app.get("/pending", response_model=PendingResponse)
async def get_pending(
    request: Request,
    authorization: str = Header(None),
    timeout: int = 120
):
    """
    Récupère les tâches en attente de retour utilisateur.

    Vérifie d'abord s'il y a des tâches, puis appelle Claude pour la personnalité.

    Endpoint optimisé pour N8N :
    - Retourne has_pending=false et message="" si rien en attente
    - Retourne has_pending=true et un message de relance avec la personnalité

    Idéal pour déclencher des notifications conditionnelles.
    """

    # Vérifier l'IP whitelist
    if not check_ip_whitelist(request):
        raise HTTPException(
            status_code=403,
            detail=f"IP non autorisée: {get_client_ip(request)}"
        )

    verify_token(authorization)

    client_ip = get_client_ip(request)
    if not check_rate_limit(client_ip):
        raise HTTPException(
            status_code=429,
            detail="Rate limit dépassé. Maximum 100 requêtes par minute."
        )

    logger.info(f"Vérification pending de {client_ip}")

    # Vérifier d'abord s'il y a des tâches (sans appeler Claude)
    if not check_pending_tasks():
        logger.info("Aucune tâche en attente")
        return PendingResponse(has_pending=False, message="")

    # Il y a des tâches : appeler Claude pour avoir le message avec personnalité
    logger.info("Tâches en attente détectées, appel de Claude")
    response, _ = await call_claude("/pending", timeout=timeout)

    return PendingResponse(has_pending=True, message=response.strip())


# ========================================
# Point d'entrée
# ========================================

if __name__ == "__main__":
    logger.info(f"Démarrage du serveur ULY API sur le port {SERVER_PORT}")
    logger.info(f"Workspace: {ULY_ROOT}")

    if not API_TOKEN:
        logger.warning("⚠️  ATTENTION: Aucun token API configuré - l'API est ouverte!")
    else:
        logger.info("✓ Token API configuré")

    if IP_WHITELIST:
        logger.info(f"✓ IP Whitelist active: {IP_WHITELIST}")
    else:
        logger.warning("⚠️  IP Whitelist désactivée - toutes les IPs autorisées")

    if not check_claude_available():
        logger.error("❌ Claude Code n'est pas disponible!")
        logger.error("   Installez-le avec: npm install -g @anthropic-ai/claude-code")
    else:
        logger.info("✓ Claude Code disponible")

    logger.info(f"✓ Session quotidienne: {get_daily_session_id()}")

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=SERVER_PORT,
        log_level="info"
    )
