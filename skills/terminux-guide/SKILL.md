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
| This repo | `~/Terminux` inside Ubuntu |
| Skills | `~/Terminux/skills` (registered in `opencode.json`) |
| Launcher | `Terminux` (a wrapper around `proot-distro login ubuntu`) |

## Common tasks

```bash
Terminux          # start the server and open the web UI
Terminux status   # version + server state
Terminux update   # pull this repo and reload the skin
Terminux stop     # stop the background server
```

## Notes

- The web UI is served on `127.0.0.1:49374` inside the container and is
  reachable from the Android browser because proot shares the network stack.
- Authentication is a pairing link (`/auth/connect/<code>`), not a password.
- Skills added to `skills/` in this repository become available to every
  user after `Terminux update`.
