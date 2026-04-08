# oh-my-opencode

Docker Compose wrapper for [OpenCode](https://opencode.ai) + [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent). Not a traditional codebase — no app source code. Container image `ghcr.io/anomalyco/opencode:1.4.0` holds the runtime.

## STRUCTURE

```
.
├── docker-compose.yml        # 2 services: opencode, opencode-nvidia (profile-gated)
├── install.sh                # Delegates to scripts/shell-setup.sh
├── scripts/
│   ├── shell-setup.sh        # Install/uninstall shell wrapper (bash/zsh/fish)
│   ├── opencode.sh           # Bash/Zsh: `opencode` fn + tab completion
│   └── opencode.fish         # Fish: `opencode` fn + completion
├── examples/                 # Reference configs — copy to data/config/ to use
│   ├── opencode.json         # Provider definitions (vLLM MLX, Ollama local/remote)
│   ├── oh-my-openagent.json  # Agent + category model assignments
│   └── package.json          # Plugin dependency
├── data/                     # Bind-mounted runtime state (gitignored)
│   ├── config/               # → /root/.config/opencode/ (live configs, plugins)
│   ├── share/                # → /root/.local/share/opencode/ (auth, sessions, logs)
│   ├── state/                # → /root/.local/state/opencode/ (lock files)
│   └── cache/                # → /root/.cache/opencode/ (npm package cache)
├── .env.example              # API keys template (most providers use OAuth instead)
└── .gitignore                # Excludes .env and data/
```

## WHERE TO LOOK

| Task | Location | Notes |
|------|----------|-------|
| Add/change AI provider | `data/config/opencode.json` | Schema: `https://opencode.ai/config.json` |
| Change agent model assignments | `data/config/oh-my-openagent.json` | Schema in file `$schema` field |
| Add API key | `.env` | Copy from `.env.example` first |
| Modify shell wrapper behavior | `scripts/opencode.sh` or `opencode.fish` | `OPENCODE_COMPOSE_FILE` env var overrides compose path |
| Add/remove shell support | `scripts/shell-setup.sh` | Fish uses symlink; bash/zsh use source injection |
| Enable GPU | `docker compose --profile nvidia run --rm opencode-nvidia` | Requires nvidia-container-toolkit |
| Debug container | `data/share/log/` | Session logs live here |
| Reset all state | Delete `data/` directory | Recreated on next run |

## CONVENTIONS

- **POSIX shell**: All scripts target `/bin/sh` — no bashisms in `shell-setup.sh` or `install.sh`
- **Shell wrappers**: `opencode.sh` uses `BASH_SOURCE` + zsh `%x` fallback for portability
- **Fish separate**: Fish has its own file (`opencode.fish`) — never mixed with POSIX scripts
- **Config schema validation**: Both JSON configs use `$schema` for IDE autocompletion
- **Bind mounts over volumes**: `data/` is a host directory, not Docker named volumes — enables host-side inspection/editing
- **Profile-gated GPU**: NVIDIA service requires explicit `--profile nvidia` — never starts by default

## ANTI-PATTERNS

- Do NOT add named Docker volumes — project uses bind mounts to `data/` for host access
- Do NOT hardcode LAN IPs in docker-compose.yml — they go in `data/config/opencode.json`
- Do NOT put secrets in docker-compose.yml — use `.env` (gitignored)
- Do NOT edit files under `data/cache/` or `data/share/` manually — managed by OpenCode runtime
- Do NOT use bashisms in `shell-setup.sh` or `install.sh` — they run under `/bin/sh`

## COMMANDS

```bash
./install.sh                    # Install shell wrapper
./scripts/shell-setup.sh uninstall  # Remove shell wrapper
opencode                       # Run OpenCode (after install)
opencode providers             # Auth/configure providers
opencode plugin oh-my-openagent@latest  # Install agent plugin
opencode run "prompt"          # One-shot command
```

## NOTES

- **Docker Desktop Mac/Windows**: `network_mode: host` requires enabling "Host networking" in Docker Desktop settings. Without it, OAuth callbacks fail and LAN devices are unreachable.
- **LAN workaround**: If host networking doesn't work, use `socat TCP-LISTEN:11434,fork,reuseaddr TCP:<LAN_IP>:11434 &` on host, then `localhost` in provider config.
- **Container image is external**: All application logic lives in `ghcr.io/anomalyco/opencode:1.4.0`. This repo only orchestrates it.
- **examples/ vs data/config/**: `examples/` are reference templates. Live config is in `data/config/` (created on first run). The examples have fewer entries than the live config may accumulate.
