set shell := ["bash", "-euo", "pipefail", "-c"]

# Lists the commands.
default:
    @just --list

# Checks scripts, workflows and source history without executing server operations.
check:
    just --fmt --check
    shellcheck --severity=warning scripts/*.sh
    actionlint
    zizmor --offline --no-progress .github
    gitleaks git --no-banner --redact .

# Runs every source check for this configuration repository.
verify: check
