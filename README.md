# oh-my-opencode

Docker Compose setup for [OpenCode](https://opencode.ai) with [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent).

Config, auth, and plugin data lives in `data/home/` so you can inspect and edit it from the host.

## Setup

### 1. Install the shell wrapper

```bash
./install.sh
source ~/.zshrc  # or ~/.bashrc
```

This adds the `opencode` command with tab completion to your shell.

### 2. Create `.env`

```bash
cp .env.example .env
# Add API keys if needed (most providers use OAuth instead)
```

### 3. Docker Desktop for Mac/Windows

Enable **"Host networking"** in Docker Desktop settings for `network_mode: host` to work. Without this, OAuth callbacks can't reach the container.

### 4. First run — authenticate and install the plugin

```bash
# Authenticate your providers
opencode providers

# Install oh-my-openagent
opencode plugin oh-my-openagent@latest
```

The installer will ask about your subscriptions (Claude, OpenAI, Gemini, etc.) and configure agent-model assignments. See the [oh-my-openagent install guide](https://github.com/code-yeongyu/oh-my-openagent/blob/dev/docs/guide/installation.md) for details.

### 5. Run

```bash
opencode
```

Type `ultrawork` (or `ulw`) to activate the Sisyphus orchestrator.

## Usage

Run from any project directory — the current directory is mounted as the workspace:

```bash
cd ~/my-project
opencode
```

Other commands:

```bash
opencode --vanilla            # Run without the oh-my-openagent plugin
opencode run "explain this codebase"
opencode models
opencode agent list
```

## NVIDIA GPU support

For hosts with CUDA GPUs (requires [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)):

```bash
docker compose --profile nvidia run --rm opencode-nvidia
```

## Local model providers

Configure Ollama or vLLM endpoints inside the container:

```bash
opencode providers
```

Or edit `data/home/.config/opencode/opencode.json` directly. Reference templates are in `examples/`.

```json
{
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama",
      "options": { "baseURL": "http://192.168.1.100:11434/v1" },
      "models": {
        "gemma4:31b": { "name": "Gemma 4 31B" }
      }
    }
  }
}
```

### LAN Ollama from Docker Desktop

Docker Desktop for Mac/Windows can't route to LAN IPs from inside containers. The `opencode` wrapper auto-starts `scripts/ollama-proxy.py` which forwards container traffic to a remote Ollama host.

Configure via env vars:

| Variable | Default | Purpose |
|----------|---------|---------|
| `OLLAMA_HOST` | `192.168.1.100:11434` | Remote Ollama address |
| `OLLAMA_PROXY_PORT` | `11435` | Local port the proxy listens on |

### Networking

The container uses `network_mode: host` so it has direct access to the host network and LAN.

**Note:** On Docker Desktop for Mac/Windows, `host` networking requires enabling **"Host networking"** in Docker Desktop settings. Without it, the container runs in a VM and cannot reach LAN devices or receive OAuth callbacks. See [Docker docs](https://docs.docker.com/engine/network/drivers/host/#docker-desktop) for details.

## Data

All state is bind-mounted to `data/home/` in the project directory (mapped to `/root` inside the container):

| Path | Container path | Purpose |
|------|---------------|---------|
| `data/home/.config/opencode/` | `/root/.config/opencode/` | Config, plugins, agent definitions |
| `data/home/.local/share/` | `/root/.local/share/` | Auth, sessions DB, logs, MCP auth |
| `data/home/.local/state/` | `/root/.local/state/` | Lock files, prompt history, model state |
| `data/home/.cache/` | `/root/.cache/` | npm package cache |

To start fresh, delete the `data/` directory.

## Portability

### Transfer setup to another machine

Copy `data/` and `.env` to the new machine — everything is self-contained:

```bash
# Machine A: after setup, auth, and plugin install
tar czf opencode-portable.tar.gz data/ .env

# Machine B: clone the repo, extract, run
git clone <this-repo> && cd omo-docker
tar xzf opencode-portable.tar.gz
opencode   # ready to go
```

No re-authentication (until OAuth tokens expire), no reconfiguring providers, no reinstalling plugins or MCPs.

**Caveats:**
- OAuth tokens have a lifetime — they'll work immediately but will eventually need re-auth via `opencode providers`
- LAN IP endpoints in `data/home/.config/opencode/opencode.json` must be reachable from the new machine
- `data/home/.local/state/` is just lock files — safe to skip, they regenerate

### Migrate from Claude Code

OpenCode reads Claude Code's command and skill files directly — no conversion needed. It loads from these locations (in priority order):

| Priority | Location (container) | Host path | Scope |
|----------|---------------------|-----------|-------|
| 1 | `<workspace>/.opencode/commands/*.md` | your project dir | Project (OpenCode native) |
| 2 | `/root/.config/opencode/commands/*.md` | `data/home/.config/opencode/commands/*.md` | Global (OpenCode native) |
| 3 | `<workspace>/.claude/commands/*.md` | your project dir | Project (Claude Code compat) |
| 4 | `/root/.claude/commands/*.md` | `data/home/.claude/commands/*.md` | Global (Claude Code compat) |

**Important — container isolation:** the container only sees the workspace (your current directory) and `data/home/` (mapped to `/root`). It **cannot** read your host's `~/.claude/` directory. Project-level `.claude/` works because the workspace is mounted; global Claude commands must be copied into `data/home/.claude/`.

Both systems use the same markdown format with optional YAML frontmatter and support `$ARGUMENTS`, bash injection (`` !`command` ``), and file references.

**Project commands** — already in `.claude/commands/` in your project? They work automatically when you `opencode` in that project.

**Global commands** — copy from your host into the bind-mounted home:

```bash
# OpenCode native location
cp ~/.claude/commands/*.md data/home/.config/opencode/commands/

# Or keep the Claude Code layout
mkdir -p data/home/.claude/commands
cp ~/.claude/commands/*.md data/home/.claude/commands/
```

**Skills** — same story. Project skills under `<workspace>/.claude/skills/*/SKILL.md` are auto-discovered. For global skills, copy to `data/home/.config/opencode/skills/<name>/SKILL.md` or `data/home/.claude/skills/<name>/SKILL.md`.

**Note:** Claude Code's `allowed-tools` frontmatter field is ignored by OpenCode (which uses `agent` and `model` instead), but the command body works without changes.

## Uninstall

Remove the shell wrapper:

```bash
./scripts/shell-setup.sh uninstall
```

## Example configs

See `examples/` for reference configurations.
