# rldyourmcrft

Minecraft 1.12.2 Forge modded server setup and configuration.

## Requirements

- **Java 8** (JDK or JRE) - Forge 1.12.2 is not compatible with Java 9+
- **4GB+ RAM** recommended (configurable in `.env`)
- Linux/macOS (Windows: use Git Bash or WSL)

## Quick Start

```bash
# 1. Clone the repository
git clone git@github.com:rldyourmnd/rldyourmcrft.git
cd rldyourmcrft

# 2. Install Forge server
chmod +x scripts/*.sh
./scripts/install.sh

# 3. Configure
cp .env.example .env
# Edit .env - adjust RAM, Java path
# Edit server.properties - adjust server settings

# 4. Add mods to mods/ directory

# 5. Start the server
./scripts/start.sh
```

## Project Structure

```
rldyourmcrft/
├── scripts/
│   ├── install.sh       # Download and install Forge server
│   ├── start.sh         # Launch server (Aikar's JVM flags)
│   ├── backup.sh        # World backup with rotation
│   └── restore.sh       # Restore world from backup
├── config/              # Mod configuration files
├── mods/                # Mod JAR files (not tracked in git)
├── server.properties    # Server configuration
├── .env.example         # Environment template
├── ops.json.example     # Operator list template
└── whitelist.json.example
```

## Server Management

### Backups

```bash
# Create a backup
./scripts/backup.sh

# List available backups
./scripts/restore.sh

# Restore a specific backup (stop the server first!)
./scripts/restore.sh world_backup_2026-03-15_12-00-00.tar.gz
```

### Configuration

All runtime settings are in `.env`:

| Variable | Default | Description |
|----------|---------|-------------|
| `MIN_RAM` | `4G` | Minimum JVM heap |
| `MAX_RAM` | `4G` | Maximum JVM heap |
| `JAVA_PATH` | (system) | Path to Java 8 binary |
| `FORGE_VERSION` | `1.12.2-14.23.5.2860` | Forge build |
| `BACKUP_KEEP_COUNT` | `10` | Max backups to retain |

## Forge Version

- Minecraft: **1.12.2**
- Forge: **14.23.5.2860** (latest recommended)
- Forge installer: auto-downloaded by `install.sh`

## Adding Mods

1. Download mod `.jar` files compatible with **Minecraft 1.12.2**
2. Place them in the `mods/` directory
3. Restart the server
4. Mod configs will appear in `config/` after first launch

## Notes

- Always stop the server before restoring backups
- Mod JARs are excluded from git (too large). Document your modlist separately
- The `config/` directory is tracked - commit config changes to keep server reproducible
- `online-mode=true` by default for security. Disable only for offline/LAN play
