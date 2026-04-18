# oh-my-opencode

Docker Compose setup for [OpenCode](https://opencode.ai) with [oh-my-openagent](https://github.com/code-yeongyu/oh-my-openagent).

Config, auth, and plugin data lives in `data/` so you can inspect and edit it from the host.

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

Or edit `data/config/opencode.json` directly:

```json
{
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama",
      "options": { "baseURL": "http://192.168.1.69:11434/v1" },
      "models": {
        "gemma4:31b": { "name": "Gemma 4 31B" }
      }
    }
  }
}
```

### Networking

The container uses `network_mode: host` so it has direct access to the host network and LAN.

**Note:** On Docker Desktop for Mac/Windows, `host` networking requires enabling **"Host networking"** in Docker Desktop settings. Without it, the container runs in a VM and cannot reach LAN devices or receive OAuth callbacks. See [Docker docs](https://docs.docker.com/engine/network/drivers/host/#docker-desktop) for details.

## Data

All state is bind-mounted to `data/` in the project directory:

| Path | Container path | Purpose |
|------|---------------|---------|
| `data/config/` | `/root/.config/opencode/` | Config, plugins, agent definitions |
| `data/share/` | `/root/.local/share/opencode/` | Auth, sessions DB, logs |
| `data/state/` | `/root/.local/state/opencode/` | Lock files |
| `data/cache/` | `/root/.cache/opencode/` | Plugin package cache |

To start fresh, delete the `data/` directory.

## Portability

### Transfer setup to another machine

Copy `data/` and `.env` to the new machine — everything is self-contained:

```bash
# Machine A: after setup, auth, and plugin install
tar czf opencode-portable.tar.gz data/ .env

# Machine B: clone the repo, extract, run
git clone <this-repo> && cd oh-my-opencode
tar xzf opencode-portable.tar.gz
opencode   # ready to go
```

No re-authentication (until OAuth tokens expire), no reconfiguring providers, no reinstalling plugins or MCPs.

**Caveats:**
- OAuth tokens have a lifetime — they'll work immediately but will eventually need re-auth via `opencode providers`
- LAN IP endpoints in `data/config/opencode.json` (e.g., Ollama at `192.168.1.69:11434`) must be reachable from the new machine
- `data/state/` is just lock files — safe to skip, they regenerate

### Migrate from Claude Code

OpenCode reads Claude Code's command and skill files directly — no conversion needed. It loads from these locations (in priority order):

| Priority | Location | Scope |
|----------|----------|-------|
| 1 | `.opencode/commands/*.md` | Project (OpenCode native) |
| 2 | `data/config/commands/*.md` | Global (OpenCode native) |
| 3 | `.claude/commands/*.md` | Project (Claude Code compat) |
| 4 | `~/.claude/commands/*.md` | Global (Claude Code compat) |

Both systems use the same markdown format with optional YAML frontmatter and support `$ARGUMENTS`, bash injection (`` !`command` ``), and file references.

**Project commands** — already in `.claude/commands/`? They work automatically when you `opencode` in that project.

**Global commands** — copy to OpenCode's config directory:

```bash
cp ~/.claude/commands/*.md data/config/commands/
```

**Skills** — same story. OpenCode discovers `.claude/skills/*/SKILL.md` automatically. For global skills, copy to `data/config/skills/<name>/SKILL.md`.

**Note:** Claude Code's `allowed-tools` frontmatter field is ignored by OpenCode (which uses `agent` and `model` instead), but the command body works without changes.

## Uninstall

Remove the shell wrapper:

```bash
./scripts/shell-setup.sh uninstall
```

## Example configs

See `examples/` for reference configurations.
