# oh-my-opencode

Docker Compose wrapper for [OpenCode](https://opencode.ai) + [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent). No application source code — the container image (`ghcr.io/anomalyco/opencode:latest`) holds the runtime. This repo only orchestrates it.

## Execution flow

```
opencode (shell fn)
  → scripts/opencode-run.sh     # wrapper: proxy, --vanilla, docker compose
    → docker compose run --rm opencode
```

`opencode.sh` and `opencode.fish` define a shell function that delegates to `opencode-run.sh`. The wrapper auto-starts `ollama-proxy.py` for LAN Ollama access, handles the `--vanilla` flag, then invokes `docker compose run`.

## Structure

```
docker-compose.yml       # 2 services: opencode, opencode-nvidia (profile-gated)
install.sh               # Delegates to scripts/shell-setup.sh
scripts/
  shell-setup.sh         # Install/uninstall shell wrapper (bash/zsh/fish)
  opencode.sh            # Bash/Zsh: `opencode` fn + tab completion
  opencode.fish          # Fish: `opencode` fn + completion
  opencode-run.sh        # Core entrypoint — wraps docker compose with proxy + --vanilla
  ollama-proxy.py        # TCP proxy for Docker Desktop Mac → LAN Ollama
examples/                # Reference configs — copy to data/home/.config/opencode/ to use
  opencode.json          # Provider definitions (vLLM MLX, Ollama local/remote)
  oh-my-openagent.json   # Agent + category model assignments
  package.json           # Plugin dependency
data/home/               # Bind-mounted as /root (gitignored)
  .config/opencode/      # Live configs, plugins, oh-my-openagent.json
  .local/share/          # auth.json, sessions DB, logs, MCP auth
  .local/state/          # Lock files, prompt history, model state
  .cache/                # npm package cache
.env                     # API keys (gitignored, copy from .env.example)
```

## Where to look

| Task | Location | Notes |
|------|----------|-------|
| Add/change AI provider | `data/home/.config/opencode/opencode.json` | Schema: `https://opencode.ai/config.json` |
| Change agent model assignments | `data/home/.config/opencode/oh-my-openagent.json` | Schema in file `$schema` field |
| Add API key | `.env` | Copy from `.env.example` — compose passes `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GOOGLE_GENERATIVE_AI_API_KEY` |
| Modify shell wrapper behavior | `scripts/opencode.sh` or `opencode.fish` | Both delegate to `opencode-run.sh` |
| Change docker/proxy behavior | `scripts/opencode-run.sh` | Ollama proxy, --vanilla flag, compose invocation |
| Add/remove shell support | `scripts/shell-setup.sh` | Fish uses symlink; bash/zsh use source injection |
| Enable GPU | `docker compose --profile nvidia run --rm opencode-nvidia` | Requires nvidia-container-toolkit |
| Debug sessions | `data/home/.local/share/log/` | Session logs |
| Reset all state | Delete `data/` directory | Recreated on next run |

## Commands

```bash
./install.sh                        # Install shell wrapper
./scripts/shell-setup.sh uninstall  # Remove shell wrapper
opencode                            # Run OpenCode (after install)
opencode --vanilla                  # Run without oh-my-openagent plugin
opencode providers                  # Auth/configure providers
opencode plugin oh-my-openagent@latest  # Install agent plugin
opencode run "prompt"               # One-shot command
```

## Environment variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `OPENCODE_COMPOSE_FILE` | `scripts/../docker-compose.yml` | Override compose file path |
| `OPENCODE_WORKSPACE` | `$PWD` | Host directory mounted at `/workspace` (set by opencode-run.sh) |
| `OLLAMA_HOST` | `192.168.1.100:11434` | Remote Ollama address for proxy |
| `OLLAMA_PROXY_PORT` | `11435` | Local port for ollama-proxy.py |

## Conventions

- **POSIX shell**: `shell-setup.sh`, `install.sh`, `opencode-run.sh` target `/bin/sh` — no bashisms
- **Shell wrappers**: `opencode.sh` uses `BASH_SOURCE` + zsh `%x` fallback for portability
- **Fish separate**: Fish has its own file (`opencode.fish`) — never mixed with POSIX scripts
- **Config schema validation**: Both JSON configs use `$schema` for IDE autocompletion
- **Bind mounts over volumes**: `data/home/` is a host directory mounted as `/root` — enables host-side inspection/editing
- **Profile-gated GPU**: NVIDIA service requires explicit `--profile nvidia` — never starts by default
- **`--vanilla` flag**: Strips oh-my-openagent plugin at runtime by generating a temp config without the `plugin` key

## Anti-patterns

- Do NOT add named Docker volumes — project uses bind mounts to `data/home/` for host access
- Do NOT hardcode LAN IPs in docker-compose.yml — they go in `data/home/.config/opencode/opencode.json`
- Do NOT put secrets in docker-compose.yml — use `.env` (gitignored)
- Do NOT edit files under `data/home/.cache/`, `data/home/.local/share/`, or `data/home/.local/state/` manually — managed by OpenCode runtime
- Do NOT use bashisms in `shell-setup.sh`, `install.sh`, or `opencode-run.sh` — they run under `/bin/sh`

## Gotchas

- **Docker Desktop Mac/Windows**: `network_mode: host` requires enabling "Host networking" in Docker Desktop settings. Without it, OAuth callbacks fail and LAN devices are unreachable.
- **LAN Ollama access**: `opencode-run.sh` auto-starts `ollama-proxy.py` to forward traffic from the container to a LAN Ollama host. Configure via `OLLAMA_HOST` and `OLLAMA_PROXY_PORT`.
- **examples/ vs live config**: `examples/` are reference templates. Live config is in `data/home/.config/opencode/` (populated on first run). Copy examples there to use them.
