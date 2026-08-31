# Prompt
> I ran ./run.sh and when I stopped the container these errors were shown on the command line, can you tell me where these come from and can you suppress these in future runs?
> npm error path /app
> npm error command failed
> npm error signal SIGINT
> npm error command sh -c vite --host 0.0.0.0 --port 4173
> npm error Log files were not written due to an error writing to the directory: /opt/app-root/src/.npm/_logs

Timestamp: Tue Sep  1 01:34:45 CEST 2026

## Root Cause

Two separate (harmless) errors fired on Ctrl+C:

1. **`npm error signal SIGINT / command failed`**
   npm was used as the process launcher (`npm run dev`). When Ctrl+C is pressed,
   SIGINT is sent to the container. npm forwards it to the vite child, then treats
   the non-zero exit as an error and prints the noise. This is npm wrapping behavior,
   not a real failure.

2. **`Log files were not written due to an error writing to /opt/app-root/src/.npm/_logs`**
   npm tried to write a crash log to the home directory of the `node` user
   (`/opt/app-root/src/`). That directory is owned by root, so uid 1000 (the
   non-root user the container runs as) cannot write there.

## Fix applied — Containerfile

Two changes:

1. **`CMD` changed** from `["npm", "run", "dev", ...]` to
   `["node_modules/.bin/vite", "--host", "0.0.0.0", "--port", "4173"]`
   — vite is invoked directly, bypassing npm's process wrapper entirely.
   Vite handles SIGINT gracefully and exits with 0, producing no error output.

2. **`ENV NPM_CONFIG_LOGS_DIR=/tmp/npm-logs`** added after `npm ci`
   — any npm invocation inside the container (e.g. future package commands)
   will write logs to /tmp, which is always writable by uid 1000.

A `--rebuild` run is needed once for the changes to take effect:
   ./run.sh --rebuild
