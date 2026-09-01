# God's Eye View — Containerfile
# Changed: Mon Aug 31 21:56:20 CEST 2026 — initial containerized dev server image
# Changed: Tue Sep  1 00:00:00 CEST 2026 — upgraded base image to nodejs-24-minimal (satisfies >=24.14 engine constraint)
# Changed: Tue Sep  1 00:00:00 CEST 2026 — removed explicit curl install; nodejs-24-minimal already ships curl-minimal
# Changed: Tue Sep  1 00:00:00 CEST 2026 — chown node_modules to uid 1000 after npm ci so Vite cache writes succeed at runtime
# Changed: Tue Sep  1 01:34:45 CEST 2026 — invoke vite directly instead of via npm run to suppress SIGINT error noise on Ctrl+C; redirect npm logs to /tmp
# Changed: Tue Sep  1 02:27:34 CEST 2026 — bump sharp ^0.34.5 -> ^0.35.4 (CVE-2026-59876, CVE-2026-59877, CVE-2026-65898); add overrides.dompurify ^3.4.13 (GHSA-55q2-fjhq-7xh7, GHSA-c2j3-45gr-mqc4)
#
# ─────────────────────────────────────────────────────────────────────────────
# Plain-English explanation of what this file does:
#
#   A Containerfile is a recipe for building a container image — think of it
#   as a "snapshot" of a fully configured computer that is identical every time
#   you start it.  Here is what each section does:
#
#   1. FROM   — we start from a ready-made, trustworthy base provided by
#               Red Hat that already has Node.js 24 installed.  Node.js is the
#               engine that runs the God's Eye View application.
#
#   2. USER root / mkdir — we briefly become the "administrator" just long
#               enough to create the app folder and hand it to the node user.
#
#   3. COPY package*.json + RUN npm ci — we copy the list of software the
#               app depends on, then install all of it.  Doing this BEFORE
#               copying the rest of the code means Podman can skip this step
#               on rebuilds if the dependency list has not changed (faster).
#
#   4. COPY . . — copy the rest of the application source code in.
#
#   5. USER 1000 — switch to a non-administrator account for safety.
#               The app never needs root; running as root inside a container is
#               an unnecessary risk.
#
#   6. EXPOSE 4173 — declare which network port the app uses so Podman knows
#               to forward your browser traffic to it.
#
#   7. HEALTHCHECK — Podman will periodically ask "are you alive?" and report
#               whether the app is ready.
#
#   8. CMD — the command that runs when you start the container.
#               "--host 0.0.0.0" means "accept connections from outside the
#               container" so your browser on the host machine can reach it.
#
# ─────────────────────────────────────────────────────────────────────────────

# Node 24 LTS — satisfies package.json engines: ">=24.14.0 <25 || >=26 <27"
# nodejs-24-minimal already ships curl-minimal (used by the health check).
FROM registry.access.redhat.com/ubi9/nodejs-24-minimal:latest

# Become root briefly to create and own the app directory,
# then drop back to uid 1000 (the built-in node user) for everything else.
USER root
RUN mkdir -p /app && chown 1000:0 /app

WORKDIR /app

# ── Install dependencies ──────────────────────────────────────────────────────
# Copy only the dependency manifests first.  If nothing in these two files has
# changed since the last build, Podman reuses the cached layer and skips the
# (slow) npm install step entirely.
COPY --chown=1000:0 package.json package-lock.json ./

# npm ci = "clean install" — reads the exact versions from package-lock.json
# so every build is reproducible and identical.
# chown -R afterwards: npm ci runs as root and creates node_modules/ owned by
# root.  Vite writes a .vite/ cache into node_modules/ at runtime (as uid 1000),
# so ownership of the whole tree must be handed over before we drop privileges.
# Redirect npm's log directory to /tmp so uid 1000 can always write to it.
# Without this, npm prints a spurious "Log files were not written" error on shutdown.
RUN npm ci && chown -R 1000:0 /app/node_modules
ENV NPM_CONFIG_LOGS_DIR=/tmp/npm-logs

# ── Copy application source ───────────────────────────────────────────────────
# Everything not listed in .containerignore is copied here.
# .env is excluded by .containerignore — secrets must NEVER be baked into an image.
COPY --chown=1000:0 . .

# ── Drop to non-root ──────────────────────────────────────────────────────────
USER 1000

# ── Network ───────────────────────────────────────────────────────────────────
EXPOSE 4173

# ── Health check ─────────────────────────────────────────────────────────────
# Podman checks every 15 s whether the dev server responds.
# The container shows as "healthy" in `podman ps` once it passes.
# curl-minimal is already present in the base image — no separate install needed.
HEALTHCHECK --interval=15s --timeout=5s --start-period=45s --retries=3 \
  CMD curl -sf http://localhost:4173/ > /dev/null || exit 1

# ── Start ─────────────────────────────────────────────────────────────────────
# API keys are injected at run time via --env-file .env (see run.sh).
# They are NEVER stored in the image itself.
# Invoke vite directly (not via `npm run`) so that Ctrl+C (SIGINT) terminates
# cleanly without npm printing a spurious "command failed / signal SIGINT" error.
CMD ["node_modules/.bin/vite", "--host", "0.0.0.0", "--port", "4173"]
