"""Serveur API ULY pour Cloudflare Tunnel.

Expose ULY via une API REST securisee pour integration avec N8N,
Make, Zapier, et autres outils d'automatisation.
"""

import json
import logging
import os
import re
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

import anthropic

# Configuration des chemins
SCRIPT_DIR = Path(__file__).parent
ULY_ROOT = Path(os.environ.get("ULY_WORKSPACE", SCRIPT_DIR.parent.parent.parent))

# Charger les variables d'environnement
load_dotenv(SCRIPT_DIR / ".env")
load_dotenv(ULY_ROOT / ".env")

# Configuration
API_TOKEN = os.environ.get("ULY_API_TOKEN", "")
SERVER_PORT = int(os.environ.get("SERVER_PORT", "8787"))
CLAUDE_MD_PATH = ULY_ROOT / "CLAUDE.md"

# Rate limiting
RATE_LIMIT = 100  # requetes par minute
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
    description="API pour interagir avec ULY via Cloudflare Tunnel",
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
# Modeles Pydantic
# ========================================

class AskRequest(BaseModel):
    """Requete pour poser une question a Claude."""
    message: str
    context: Optional[str] = None
    workspace_access: bool = True
    max_tokens: int = 4096


class AskResponse(BaseModel):
    """Reponse de Claude."""
    response: str
    files_accessed: list[str] = []
    files_modified: list[str] = []
    tokens_used: int = 0


class HealthResponse(BaseModel):
    """Statut de sante du service."""
    status: str
    timestamp: str
    workspace: str
    version: str


# ========================================
# Outils pour Claude
# ========================================

TOOLS = [
    {
        "name": "read_file",
        "description": "Lire le contenu d'un fichier dans l'espace de travail ULY.",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Chemin relatif au workspace (ex: 'state/current.md', 'content/notes.md')"
                }
            },
            "required": ["path"]
        }
    },
    {
        "name": "write_file",
        "description": "Creer ou mettre a jour un fichier dans l'espace de travail ULY.",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Chemin relatif au workspace"
                },
                "content": {
                    "type": "string",
                    "description": "Contenu a ecrire"
                }
            },
            "required": ["path", "content"]
        }
    },
    {
        "name": "search_files",
        "description": "Rechercher des fichiers par nom ou contenu.",
        "input_schema": {
            "type": "object",
            "properties": {
                "query": {
                    "type": "string",
                    "description": "Terme de recherche"
                },
                "file_pattern": {
                    "type": "string",
                    "description": "Pattern glob (defaut: **/*.md)",
                    "default": "**/*.md"
                }
            },
            "required": ["query"]
        }
    },
    {
        "name": "list_directory",
        "description": "Lister le contenu d'un repertoire.",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Chemin du repertoire (defaut: racine)",
                    "default": "."
                }
            },
            "required": []
        }
    },
    {
        "name": "append_to_file",
        "description": "Ajouter du contenu a la fin d'un fichier existant.",
        "input_schema": {
            "type": "object",
            "properties": {
                "path": {
                    "type": "string",
                    "description": "Chemin relatif au workspace"
                },
                "content": {
                    "type": "string",
                    "description": "Contenu a ajouter"
                }
            },
            "required": ["path", "content"]
        }
    }
]


class ToolExecutor:
    """Executeur d'outils pour Claude."""

    def __init__(self, workspace: Path, allow_write: bool = True):
        self.workspace = workspace
        self.allow_write = allow_write
        self.files_accessed = []
        self.files_modified = []

    def _validate_path(self, path: str) -> Path:
        """Valide et resout un chemin de fichier."""
        file_path = self.workspace / path
        try:
            file_path.resolve().relative_to(self.workspace.resolve())
        except ValueError:
            raise ValueError(f"Acces refuse: chemin hors du workspace - {path}")
        return file_path

    def execute(self, tool_name: str, tool_input: dict) -> str:
        """Execute un outil et retourne le resultat."""
        try:
            if tool_name == "read_file":
                return self._read_file(tool_input["path"])
            elif tool_name == "write_file":
                return self._write_file(tool_input["path"], tool_input["content"])
            elif tool_name == "search_files":
                return self._search_files(
                    tool_input["query"],
                    tool_input.get("file_pattern", "**/*.md")
                )
            elif tool_name == "list_directory":
                return self._list_directory(tool_input.get("path", "."))
            elif tool_name == "append_to_file":
                return self._append_to_file(tool_input["path"], tool_input["content"])
            else:
                return f"Outil inconnu: {tool_name}"
        except Exception as e:
            logger.error(f"Erreur d'execution de l'outil {tool_name}: {e}")
            return f"Erreur: {str(e)}"

    def _read_file(self, path: str) -> str:
        """Lire un fichier."""
        file_path = self._validate_path(path)
        if not file_path.exists():
            return f"Fichier non trouve: {path}"
        if not file_path.is_file():
            return f"N'est pas un fichier: {path}"

        self.files_accessed.append(path)
        content = file_path.read_text()

        if len(content) > 10000:
            return f"Contenu (tronque, {len(content)} caracteres total):\n{content[:10000]}..."
        return content

    def _write_file(self, path: str, content: str) -> str:
        """Ecrire dans un fichier."""
        if not self.allow_write:
            return "Erreur: l'ecriture de fichiers est desactivee pour cette requete"

        file_path = self._validate_path(path)
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(content)
        self.files_modified.append(path)
        return f"Fichier ecrit: {path} ({len(content)} caracteres)"

    def _search_files(self, query: str, file_pattern: str = "**/*.md") -> str:
        """Rechercher dans les fichiers."""
        results = []
        query_lower = query.lower()

        for path in self.workspace.glob(file_pattern):
            if not path.is_file():
                continue
            # Ignorer les fichiers caches et venv
            if any(part.startswith('.') or part in ('venv', 'node_modules', '__pycache__')
                   for part in path.parts):
                continue

            rel_path = path.relative_to(self.workspace)

            # Verifier le nom du fichier
            if query_lower in path.name.lower():
                results.append(f"* {rel_path} (nom)")
                self.files_accessed.append(str(rel_path))
                continue

            # Verifier le contenu
            try:
                if path.stat().st_size < 100000:
                    content = path.read_text()
                    if query_lower in content.lower():
                        idx = content.lower().find(query_lower)
                        start = max(0, idx - 40)
                        end = min(len(content), idx + len(query) + 40)
                        snippet = content[start:end].replace('\n', ' ')
                        results.append(f"* {rel_path}: ...{snippet}...")
                        self.files_accessed.append(str(rel_path))
            except Exception:
                pass

        if not results:
            return f"Aucun resultat pour '{query}'"

        return f"Resultats ({len(results)}):\n" + "\n".join(results[:15])

    def _list_directory(self, path: str = ".") -> str:
        """Lister un repertoire."""
        dir_path = self._validate_path(path)
        if not dir_path.exists():
            return f"Repertoire non trouve: {path}"
        if not dir_path.is_dir():
            return f"N'est pas un repertoire: {path}"

        items = []
        for item in sorted(dir_path.iterdir()):
            if item.name.startswith('.') or item.name in ('venv', 'node_modules', '__pycache__'):
                continue
            if item.is_dir():
                items.append(f"[dir] {item.name}/")
            else:
                items.append(f"[file] {item.name}")

        return f"Contenu de {path}:\n" + "\n".join(items[:30])

    def _append_to_file(self, path: str, content: str) -> str:
        """Ajouter a un fichier."""
        if not self.allow_write:
            return "Erreur: l'ecriture de fichiers est desactivee pour cette requete"

        file_path = self._validate_path(path)
        if file_path.exists():
            existing = file_path.read_text()
            file_path.write_text(existing + "\n" + content)
        else:
            file_path.parent.mkdir(parents=True, exist_ok=True)
            file_path.write_text(content)

        self.files_modified.append(path)
        return f"Contenu ajoute a {path} ({len(content)} caracteres)"


# ========================================
# Middleware et securite
# ========================================

def check_rate_limit(client_ip: str) -> bool:
    """Verifie le rate limiting."""
    now = time.time()
    minute_ago = now - 60

    # Nettoyer les anciennes entrees
    rate_limit_store[client_ip] = [
        t for t in rate_limit_store[client_ip] if t > minute_ago
    ]

    # Verifier la limite
    if len(rate_limit_store[client_ip]) >= RATE_LIMIT:
        return False

    rate_limit_store[client_ip].append(now)
    return True


def verify_token(authorization: str = Header(None)) -> bool:
    """Verifie le token d'authentification."""
    if not API_TOKEN:
        logger.warning("Aucun token API configure - acces ouvert!")
        return True

    if not authorization:
        raise HTTPException(status_code=401, detail="Token d'authentification requis")

    # Format: "Bearer <token>"
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(status_code=401, detail="Format d'authentification invalide. Utilisez: Bearer <token>")

    if parts[1] != API_TOKEN:
        raise HTTPException(status_code=401, detail="Token invalide")

    return True


def build_system_prompt() -> str:
    """Construit le prompt systeme avec le contexte ULY."""
    today = datetime.now().strftime("%Y-%m-%d")

    prompt = f"""Tu es ULY, un assistant IA accessible via API.

**Date du jour**: {today}

## Tes Capacites

Tu as acces a des outils pour :
- **Lire des fichiers** de l'espace de travail ULY
- **Ecrire/creer des fichiers** pour sauvegarder du contenu
- **Rechercher** des fichiers par nom ou contenu
- **Lister** le contenu des repertoires

## Structure du Workspace

- `state/` - Etat actuel et objectifs (current.md, goals.md)
- `content/` - Notes, brouillons, contenu
- `sessions/` - Logs des sessions
- `skills/` - Skills personnalises

## Consignes

- Sois concis et direct
- Utilise les outils quand c'est pertinent
- Si on te demande l'etat actuel, lis state/current.md
- Reponds toujours en francais sauf indication contraire
"""

    # Ajouter le contexte de CLAUDE.md si disponible
    if CLAUDE_MD_PATH.exists():
        try:
            claude_md = CLAUDE_MD_PATH.read_text()
            if "## User Profile" in claude_md:
                match = re.search(r"## User Profile.*?(?=##|\Z)", claude_md, re.DOTALL)
                if match:
                    prompt += f"\n## Contexte Utilisateur\n{match.group(0)[:800]}"
        except Exception:
            pass

    return prompt


# ========================================
# Endpoints
# ========================================

@app.get("/", response_class=JSONResponse)
async def root():
    """Endpoint racine."""
    return {
        "service": "ULY API",
        "version": "1.0.0",
        "endpoints": {
            "POST /ask": "Poser une question a Claude",
            "GET /health": "Verifier le statut du service"
        }
    }


@app.get("/health", response_model=HealthResponse)
async def health():
    """Verification de sante du service."""
    return HealthResponse(
        status="healthy",
        timestamp=datetime.now().isoformat(),
        workspace=str(ULY_ROOT),
        version="1.0.0"
    )


@app.post("/ask", response_model=AskResponse)
async def ask(
    request: Request,
    body: AskRequest,
    authorization: str = Header(None)
):
    """Envoie une question a Claude et retourne la reponse."""

    # Verifier l'authentification
    verify_token(authorization)

    # Verifier le rate limiting
    client_ip = request.client.host
    if not check_rate_limit(client_ip):
        raise HTTPException(
            status_code=429,
            detail="Rate limit depasse. Maximum 100 requetes par minute."
        )

    # Verifier la cle API Anthropic
    if not os.environ.get("ANTHROPIC_API_KEY"):
        raise HTTPException(
            status_code=500,
            detail="ANTHROPIC_API_KEY non configuree sur le serveur"
        )

    logger.info(f"Requete de {client_ip}: {body.message[:100]}...")

    # Preparer les outils
    tools = TOOLS if body.workspace_access else []
    executor = ToolExecutor(ULY_ROOT, allow_write=body.workspace_access)

    # Construire le prompt systeme
    system_prompt = build_system_prompt()
    if body.context:
        system_prompt += f"\n\n## Contexte additionnel\n{body.context}"

    # Appel a Claude
    try:
        client = anthropic.Anthropic()

        messages = [{"role": "user", "content": body.message}]

        response = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=body.max_tokens,
            system=system_prompt,
            tools=tools if tools else None,
            messages=messages,
        )

        # Boucle d'utilisation d'outils
        max_iterations = 10
        iteration = 0
        total_tokens = response.usage.input_tokens + response.usage.output_tokens

        while response.stop_reason == "tool_use" and iteration < max_iterations:
            iteration += 1
            logger.info(f"Iteration d'outil {iteration}/{max_iterations}")

            # Extraire et executer les outils
            tool_uses = [block for block in response.content if block.type == "tool_use"]
            tool_results = []

            for tool_use in tool_uses:
                logger.info(f"Execution de l'outil: {tool_use.name}")
                result = executor.execute(tool_use.name, tool_use.input)
                tool_results.append({
                    "type": "tool_result",
                    "tool_use_id": tool_use.id,
                    "content": result,
                })

            # Continuer la conversation
            messages.append({"role": "assistant", "content": response.content})
            messages.append({"role": "user", "content": tool_results})

            response = client.messages.create(
                model="claude-sonnet-4-20250514",
                max_tokens=body.max_tokens,
                system=system_prompt,
                tools=tools,
                messages=messages,
            )

            total_tokens += response.usage.input_tokens + response.usage.output_tokens

        # Extraire la reponse finale
        text_blocks = [block.text for block in response.content if hasattr(block, 'text')]
        final_response = "\n".join(text_blocks) if text_blocks else "Tache terminee."

        logger.info(f"Reponse generee ({total_tokens} tokens)")

        return AskResponse(
            response=final_response,
            files_accessed=list(set(executor.files_accessed)),
            files_modified=list(set(executor.files_modified)),
            tokens_used=total_tokens
        )

    except anthropic.APIError as e:
        logger.error(f"Erreur API Anthropic: {e}")
        raise HTTPException(status_code=502, detail=f"Erreur API Claude: {str(e)}")
    except Exception as e:
        logger.error(f"Erreur inattendue: {e}")
        raise HTTPException(status_code=500, detail=f"Erreur serveur: {str(e)}")


# ========================================
# Point d'entree
# ========================================

if __name__ == "__main__":
    logger.info(f"Demarrage du serveur ULY API sur le port {SERVER_PORT}")
    logger.info(f"Workspace: {ULY_ROOT}")

    if not API_TOKEN:
        logger.warning("ATTENTION: Aucun token API configure - l'API est ouverte!")

    uvicorn.run(
        app,
        host="0.0.0.0",
        port=SERVER_PORT,
        log_level="info"
    )
