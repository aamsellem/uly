# ULY - Makefile
# Usage: make <commande>

.PHONY: help start onboarding tunnel-start tunnel-stop tunnel-status tunnel-setup tunnel-logs tunnel-run \
        setup-google setup-atlassian setup-notion setup-slack setup-ms365 setup-telegram setup-parallel-search \
        clean sync install-deps

# Couleurs
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

# Défaut
.DEFAULT_GOAL := help

help: ## Afficher cette aide
	@echo ""
	@echo "$(BLUE)╔════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║$(NC)     $(GREEN)ULY - Commandes disponibles$(NC)       $(BLUE)║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════╝$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-25s$(NC) %s\n", $$1, $$2}'
	@echo ""

# ===========================================
# DÉMARRAGE
# ===========================================

start: ## Lancer ULY avec /uly (session interactive)
	@claude --append-system-prompt "IMPORTANT: Commence immédiatement par exécuter la commande /uly pour faire le briefing de l'utilisateur. Ne dis rien d'autre avant d'avoir exécuté /uly."

onboarding: ## Lancer l'onboarding (première configuration)
	@claude --append-system-prompt "IMPORTANT: L'utilisateur veut configurer ULY pour la première fois. Lis .uly/onboarding.md et guide-le dans la configuration étape par étape."

# ===========================================
# TUNNEL
# ===========================================

tunnel-start: ## Démarrer le tunnel en arrière-plan
	@./.uly/integrations/cloudflare-tunnel/start-daemon.sh

tunnel-stop: ## Arrêter le tunnel
	@./.uly/integrations/cloudflare-tunnel/stop-daemon.sh

tunnel-status: ## Vérifier si le tunnel tourne
	@if curl -s --max-time 2 http://localhost:8787/health >/dev/null 2>&1; then \
		echo "$(GREEN)✓ API + Tunnel actifs$(NC)"; \
	elif lsof -i :8787 -sTCP:LISTEN >/dev/null 2>&1; then \
		echo "$(YELLOW)⚠ Port 8787 occupé mais API ne répond pas$(NC)"; \
	else \
		echo "$(YELLOW)✗ Tunnel inactif$(NC)"; \
	fi

tunnel-setup: ## Configurer le tunnel Cloudflare (première fois)
	@./.uly/integrations/cloudflare-tunnel/setup.sh

tunnel-logs: ## Afficher les logs du tunnel
	@if [ -f .uly/integrations/cloudflare-tunnel/daemon.log ]; then \
		tail -50 .uly/integrations/cloudflare-tunnel/daemon.log; \
	else \
		echo "Pas de logs disponibles"; \
	fi

tunnel-run: ## Lancer le tunnel en mode interactif (avec logs)
	@./.uly/integrations/cloudflare-tunnel/run.sh

# ===========================================
# INTÉGRATIONS
# ===========================================

setup-google: ## Configurer Google Workspace (Gmail, Calendar, Drive)
	@./.uly/integrations/google-workspace/setup.sh

setup-atlassian: ## Configurer Atlassian (Jira, Confluence)
	@./.uly/integrations/atlassian/setup.sh

setup-notion: ## Configurer Notion
	@./.uly/integrations/notion/setup.sh

setup-slack: ## Configurer Slack
	@./.uly/integrations/slack/setup.sh

setup-ms365: ## Configurer Microsoft 365 (Outlook, Teams, OneDrive)
	@./.uly/integrations/ms365/setup.sh

setup-telegram: ## Configurer Telegram
	@./.uly/integrations/telegram/setup.sh

setup-parallel-search: ## Configurer Parallel Search (recherche web)
	@./.uly/integrations/parallel-search/setup.sh

setup-all: ## Configurer toutes les intégrations (interactif)
	@echo "$(BLUE)Configuration des intégrations ULY$(NC)"
	@echo ""
	@echo "Intégrations disponibles :"
	@echo "  1) Google Workspace"
	@echo "  2) Atlassian"
	@echo "  3) Notion"
	@echo "  4) Slack"
	@echo "  5) Microsoft 365"
	@echo "  6) Telegram"
	@echo "  7) Parallel Search"
	@echo "  8) Cloudflare Tunnel"
	@echo ""
	@echo "Lancez 'make setup-<nom>' pour configurer une intégration"

# ===========================================
# MAINTENANCE
# ===========================================

clean: ## Nettoyer les fichiers temporaires
	@echo "Nettoyage..."
	@find . -type f -name "*.pyc" -delete
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".DS_Store" -delete
	@rm -f .uly/integrations/cloudflare-tunnel/daemon.log
	@rm -f .uly/integrations/cloudflare-tunnel/.daemon.pid
	@echo "$(GREEN)✓ Nettoyé$(NC)"

sync: ## Synchroniser avec le template ULY officiel
	@if [ -f .uly-source ]; then \
		echo "Synchronisation depuis $$(cat .uly-source)..."; \
		claude --dangerously-skip-permissions -p "/sync"; \
	else \
		echo "$(YELLOW)Pas de source configurée$(NC)"; \
	fi

# ===========================================
# DEV
# ===========================================

install-deps: ## Installer les dépendances du tunnel
	@cd .uly/integrations/cloudflare-tunnel && \
		python3 -m venv venv && \
		. venv/bin/activate && \
		pip install -r requirements.txt
	@echo "$(GREEN)✓ Dépendances installées$(NC)"

status: ## Afficher le statut général d'ULY
	@echo ""
	@echo "$(BLUE)Statut ULY$(NC)"
	@echo ""
	@printf "  API:           "
	@if curl -s --max-time 2 http://localhost:8787/health >/dev/null 2>&1; then \
		echo "$(GREEN)actif$(NC)"; \
	else \
		echo "$(YELLOW)inactif$(NC)"; \
	fi
	@printf "  Configuration: "
	@if grep -q "NON CONFIGURÉ" CLAUDE.md 2>/dev/null; then \
		echo "$(YELLOW)incomplète$(NC) (lancez 'make onboarding')"; \
	else \
		echo "$(GREEN)OK$(NC)"; \
	fi
	@echo ""
