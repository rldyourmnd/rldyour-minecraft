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
    python3 -c 'import ast,pathlib; [ast.parse(p.read_text()) for p in pathlib.Path("scripts").glob("*.py")]'

# Tests installation boundaries without starting the server.
test:
    python3 -B -m unittest discover -s tests

# Runs every source check for this configuration repository.
verify: check test
