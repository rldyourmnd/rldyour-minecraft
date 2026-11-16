# Minecraft 1.12.2 Forge server

A persistent Forge server using pinned publisher containers and a verified, owner-provided mod/configuration bundle. World data and account stores are never imported from the client bundle. Python 3.11+ and Docker Compose are required.

The runtime configuration is in deployment/server.env. It selects Java 8, Forge, a smaller initial heap, Java maximum, process CPU/memory ceilings and view distance. The host provisions the data filesystem at DATA_DIRECTORY before installation. A named volume binds to that mount; container replacement preserves the world.

## Install and run

Run scripts/install.sh with the client-input ZIP and its independently declared SHA-256, then scripts/start.sh. Installation verifies the ZIP and every member, excludes client-only mods from deployment/pack-policy.json, checks the Forge installer digest and seeds the selected offline operator. It refuses unknown existing worlds or changed files. Stop the service before changing its pack.

The bundle is an external deployment input. This repository redistributes no mod JARs or personal world/account data. The owning infrastructure records the exact input location/digest and host filesystem/service declaration.

A stream edge publishes the game port. The game container publishes only a loopback backend. RCON and query are disabled. Commands use the packaged console pipe:

    docker compose --env-file deployment/server.env -f deployment/compose.yaml exec --user 10000 minecraft mc-send-to-console forge tps

The selected login policy allows offline accounts without a whitelist or password and grants the configured owner OP. Anyone choosing that name can receive its permissions. This is an explicit deployment choice, not identity verification.

## Lifecycle and data

One instance owns the stateful Forge world. scripts/stop.sh requests a graceful stop. A native service starts the Compose project after Docker and the data mount. Native qualification checks the loaded pack, actual cgroup limits, external protocol access, client join and save/restart behavior.

Automatic backups are disabled. No backup/restore command is installed. Keep worlds out of source control and generic cleanup. Bound Docker logs separately from game logs and monitor filesystem capacity.

## Source checks

Run just check for shell/workflow/history checks and Python syntax. just test covers installation input validation without running Minecraft. just verify composes the checks. Native server/client qualification and its limits are recorded separately.
