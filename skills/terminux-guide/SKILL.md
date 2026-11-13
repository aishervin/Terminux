---
name: Terminux Environment
description: How the TΞRMINUX/OpenCode environment on Termux works, and how to restart, update, or debug it
metadata:
  opencode/autoinvoke: true
---

# Terminux Environment

You are running inside **TΞRMINUX™**, a Termux-based distribution of OpenCode.
The actual Linux userland lives inside a `proot-distro` Ubuntu container.

## Layout

| What | Where |
| --- | --- |
| Ubuntu container | `proot-distro` distro named `ubuntu` |
| OpenCode binary | `~/.opencode/bin/opencode` inside Ubuntu |
| Config | `~/.config/opencode/` inside Ubuntu |
| Sessions / database | `~/.local/share/opencode/` inside Ubuntu |
| This repo | `~/Terminux` inside Ubuntu |
| Skills | `~/Terminux/skills` (registered in `opencode.json`) |
| Launcher | `Terminux` in Termux (`$PREFIX/bin/termunix` → `bin/termunix`) |
| Keeper log / pid | `~/.termunix/opencode.log` and `~/.termunix/keeper.pid` (Termux home) |

## How the service stays awake

`proot-distro` starts the container with `--kill-on-exit`, so every process
inside Ubuntu (including the OpenCode background service) dies when the last
proot session ends. The launcher therefore starts one **detached keeper**
session:

- it holds the container open, independent of the terminal window;
- every 15 seconds it runs `opencode service status` and, if the service is
  down, runs `opencode service start` again;
- it starts the local API proxies once (when `~/.config/terminux-proxies.sh`
  exists).

Only `Terminux stop` stops the keeper. `Termux:Boot` runs
`Terminux start --no-open` after a reboot when that add-on is installed.

## Common tasks

```bash
Terminux              # start the keeper + service and open the web UI
Terminux start        # same, without opening a second window if already up
Terminux status       # version, service health, keeper and proxy state
Terminux restart      # stop the keeper/service, then start again
Terminux logs [n]     # tail ~/.termunix/opencode.log
Terminux update       # pull this repo, reload skin/skills (sessions kept)
Terminux upgrade      # upgrade OpenCode itself (sessions kept)
Terminux stop         # stop keeper, service and proxies
```

## Debugging

- Service health: `opencode service status` inside Ubuntu.
- API info: `opencode api get /api/info` inside Ubuntu.
- Server log: `~/.local/share/opencode/log/opencode.log` inside Ubuntu
  (`role=server` for the server, `role=cli` for clients).
- Keeper log: `~/.termunix/opencode.log` in Termux.
- Do not delete `~/.local/share/opencode/opencode.db`, `service.json`, or
  `~/.config/opencode/opencode.json` while debugging: they hold sessions,
  the service password and the user's providers.

## Notes

- The web UI is served on `127.0.0.1:49374` inside the container and is
  reachable from the Android browser because proot shares the network stack.
- Authentication is a pairing link (`/auth/connect/<code>`), not a password.
- Skills added to `skills/` in this repository become available to every
  user after `Terminux update`.
- The skin (`skin/`) is built against `@opencode/plugin` and must match the
  installed OpenCode minor version. Rebuild with:
  `cd ~/Terminux/skin && bun install && bun run brand`.
