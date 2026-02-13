.PHONY: lint shellcheck version install-tools hooks

# Lint shell scripts
shellcheck:
	shellcheck scripts/*.sh

# Lint everything
lint: shellcheck

# Version management
version:
	@grep '^metadata:' SKILL.md | grep -oP '"version":\s*"\K[^"]+'

# Developer setup
install-tools:
	@echo "Checking lefthook..."
	@command -v lefthook >/dev/null 2>&1 || (echo "Install lefthook: https://github.com/evilmartians/lefthook#install" && exit 1)
	@echo "Checking shellcheck..."
	@command -v shellcheck >/dev/null 2>&1 || (echo "Install shellcheck: https://github.com/koalaman/shellcheck#installing" && exit 1)
	@echo "All tools installed."

hooks:
	lefthook install
