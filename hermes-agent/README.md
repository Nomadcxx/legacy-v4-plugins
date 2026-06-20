# Hermes Agent

Native Noctalia plugin for [Hermes Agent](https://github.com/noctalia-dev/legacy-v4-plugins).

Shows live Hermes status in the bar, provides a full chat panel with streaming responses, tool-event activity, approval prompts, interrupt, one-shot prompts, and a launcher provider using `>hermes`.

## Features

- **Bar widget**: traffic-light status indicator (online / busy / needs you / degraded / offline) with click-to-expand summary popup.
- **Panel**: persistent chat with Hermes — send prompts, watch streaming responses, approve tool calls, interrupt, start / resume sessions.
- **Launcher provider**: type `>hermes` in the Noctalia launcher to open the panel, start a session, resume the latest session, or send a one-shot prompt.
- **Settings UI**: configure bridge host / port, state file, Hermes home, poll interval, default provider / model, auto-start bridge, hide-when-idle, pin panel, show tool activity.

## Requirements

- [Hermes Agent](https://github.com/noctalia-dev/legacy-v4-plugins) installed and on `PATH` (or set `hermesCommand` in settings).
- Noctalia 4.4.1 or newer.

## How it works

The plugin ships a small Python bridge (`scripts/hermes_bridge.py`) that exposes local HTTP endpoints for health, state, session, prompt, interrupt, approvals, and one-shot commands. The QML surfaces talk to the bridge and render state from a watched state file.

## Settings

| Setting | Default | Description |
|---|---|---|
| `bridgeHost` | `127.0.0.1` | Bridge host |
| `bridgePort` | `19777` | Bridge port |
| `stateFile` | `~/.cache/noctalia-hermes/state.json` | Shared state file |
| `hermesHome` | `~/.hermes` | Hermes home directory |
| `hermesCommand` | `hermes` | Hermes executable |
| `autoStartBridge` | `true` | Start the bridge when Noctalia loads |
| `statusPollIntervalSec` | `30` | Status poll interval |
| `hideWhenIdle` | `false` | Hide the bar pill when idle |
| `launcherPrefix` | `>hermes` | Launcher command prefix |
| `panelPinned` | `false` | Pin the panel as a persistent side window |
| `showToolActivity` | `false` | Show compact tool-activity line |
| `defaultProvider` | _(empty)_ | Default provider |
| `defaultModel` | _(empty)_ | Default model |

## License

MIT