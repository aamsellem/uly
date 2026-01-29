# ULY - Makefile
# Usage: make <commande>

.PHONY: help tunnel-start tunnel-stop tunnel-status tunnel-setup tunnel-logs clean

# Couleurs
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Afficher cette aide
	@echo ""
	@echo "$(BLUE)ULY - Commandes disponibles$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

# ===========================================
# TUNNEL
# ===========================================

tunnel-start: ## Démarrer le tunnel en arrière-plan
	@./.uly/integrations/cloudflare-tunnel/start-daemon.sh

tunnel-stop: ## Arrêter le tunnel
	@./.uly/integrations/cloudflare-tunnel/stop-daemon.sh

tunnel-status: ## Vérifier si le tunnel tourne
	@if lsof -i :8787 -sTCP:LISTEN >/dev/null 2>&1; then \
		echo "$(GREEN)✓ Tunnel actif$(NC) (port 8787)"; \
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

setup-google: ## Configurer Google Workspace
	@./.uly/integrations/google-workspace/setup.sh

setup-atlassian: ## Configurer Atlassian (Jira, Confluence)
	@./.uly/integrations/atlassian/setup.sh

setup-notion: ## Configurer Notion
	@./.uly/integrations/notion/setup.sh

setup-slack: ## Configurer Slack
	@./.uly/integrations/slack/setup.sh

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
