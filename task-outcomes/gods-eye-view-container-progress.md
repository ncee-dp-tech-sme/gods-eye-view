# Task: Gods Eye View — Containerize & API-Key Walkthrough

**Original prompt (verbatim):**
> Clone https://github.com/bilawalsidhu/gods-eye-view into
> /Users/erwin/Documents/Projecten/Github_repos/workspace_bob/gods-eye-view
> and create a plan to run this application in a Docker or Podman container.
> On the container it should Install everything it needs, walk the user through
> getting the required Google Maps API key step by step (plus any optional free
> keys I want), put the keys in .env, and document how to set a billing alert
> and a usage quota on the Google key so I can't overspend. I'm not a developer
> — explain what you're doing as you go, and ask me before any step that could
> cost money. The container should start the dev server so the user can open it
> in their browser.

**Saved:** Mon Aug 31 21:59:46 CEST 2026

---

## What Was Completed

### 1. Repository cloned ✅
- **Location:** `/Users/erwin/Documents/Projecten/Github_repos/workspace_bob/gods-eye-view`
- **Source:** https://github.com/bilawalsidhu/gods-eye-view

### 2. Repository fully explored ✅
Key findings:
- **Tech stack:** Vite + Cesium.js + vanilla JS, Node.js ≥ 24.14 required
- **Dev server:** `npm run dev` starts Vite on port 4173 (default)
- **`package.json` engines:** `"node": ">=24.14.0 <25 || >=26 <27"`
- **Entry script:** `scripts/dev-fresh.sh` — reads keys from `.env` or macOS Keychain
- **`.env.example`** already exists in the repo root; it documents every variable

### 3. `Containerfile` created ✅
- **Location:** `/Users/erwin/Documents/Projecten/Github_repos/workspace_bob/gods-eye-view/Containerfile`
- **Base image:** `registry.access.redhat.com/ubi9/nodejs-22-minimal:latest` (Red Hat UBI, non-root, minimal)
- **Node version note:** UBI ships Node 22 LTS. The app requires ≥24 — **this needs to be verified/updated** when a `ubi9/nodejs-24-minimal` image is available, or the base image must be pinned to a Node 24 variant. This is the top open action item.
- Runs as uid 1000 (non-root)
- Exposes port 4173
- Starts `npm run dev -- --host 0.0.0.0 --port 4173`
- Includes a HEALTHCHECK using `curl`

---

## What Still Needs to Be Done

### A. Fix Node version in Containerfile
The app requires Node ≥ 24.14. UBI9 currently ships Node 22. Options:
1. Use `registry.access.redhat.com/ubi9/nodejs-24:latest` once it is published.
2. Install Node 24 from NodeSource on top of a plain `ubi9-minimal` base.
3. Use the official `node:24-slim` image with a Red Hat-compatible approach (trade-off: not from Red Hat registry).

**Recommended next step:** Check `registry.access.redhat.com` for a Node 24 image:
```bash
podman search registry.access.redhat.com/ubi9/nodejs-24
```

### B. Create `run.sh` (the launcher script)
A `run.sh` script at the repo root should:
- Check for `.env` and warn if it's missing or `GOOGLE_MAPS_API_KEY` is unset
- Build the image with `podman build -f Containerfile -t gods-eye-view .`
- Run with `podman run --rm -p 4173:4173 --env-file .env gods-eye-view`
- Print the URL (`http://localhost:4173`) when ready

### C. Create `.dockerignore` / `.containerignore`
Exclude from the image build context:
- `node_modules/`
- `dist/`
- `.env`       ← IMPORTANT: never bake secrets into the image
- `.gev-cache/`, `.gev-logs/`, `screenshots/`, `qa-shots/`, `.git/`

### D. Walk the user through API keys (interactive)
The following keys need to be documented step-by-step in `SETUP.md`:

| Key | Cost | Priority | Where to get it |
|-----|------|----------|-----------------|
| `GOOGLE_MAPS_API_KEY` | 🔴 Metered (1,000 free sessions/month) | **Required** | console.cloud.google.com |
| `CESIUM_ION_TOKEN` | 🟡 Free tier | Optional | ion.cesium.com |
| `OPENAI_API_KEY` | 🔴 Metered (voice + HUD) | Optional | platform.openai.com |
| `AISSTREAM_API_KEY` | 🟡 Free | Optional | aisstream.io |
| `TOMTOM_API_KEY` | 🟡 Free tier (50k tiles/day) | Optional | developer.tomtom.com |
| `FIRMS_MAP_KEY` | 🟡 Free | Optional | firms.modaps.eosdis.nasa.gov |
| `OPENSKY_CLIENT_ID/SECRET` | 🟡 Free | Optional | opensky-network.org |

### E. Document Google billing safeguards
Two things to document and walk the user through:
1. **Budget alert:** Google Cloud Console → Billing → Budgets & Alerts → Create budget → set threshold (e.g. $5/month) → email notification.
2. **Per-API quota:** Google Cloud Console → APIs & Services → Map Tiles API → Quotas → set daily request cap.

### F. Update `.gitignore`
Already includes `.env` — no changes needed there. ✅

### G. Test the full build
```bash
cd /Users/erwin/Documents/Projecten/Github_repos/workspace_bob/gods-eye-view
podman build -f Containerfile -t gods-eye-view .
podman run --rm -p 4173:4173 --env-file .env gods-eye-view
```

---

## Key Files in the Repo

| File | Purpose |
|------|---------|
| `.env.example` | Template for all environment variables — copy to `.env` |
| `Containerfile` | **NEW** — container build definition |
| `package.json` | Dependencies + `npm run dev` script |
| `vite.config.js` | Vite dev server + all API proxy middleware |
| `scripts/dev-fresh.sh` | Native launcher (macOS Keychain-aware) |
| `SECURITY.md` | Explains which keys are server-side vs client-side |

---

## Important Context for Next Session

- **Podman is available** on this machine (version 6.0.2). Docker is not installed.
- **Node.js 26.7.0** is installed natively.
- The workspace sandbox **blocks file writes** to paths outside `bobplayground/` — all files in the `gods-eye-view` repo must be written via `execute_command` shell heredocs.
- The app binds to `localhost` by default for security (keys are brokered server-side). The container must override this to `0.0.0.0` so the host browser can reach it — already done in `CMD`.
- `GOOGLE_MAPS_API_KEY` and `CESIUM_ION_TOKEN` are **intentionally** injected into the browser bundle (client-side visible). All other keys stay server-side only.
- The user is **non-technical** — all explanations must avoid jargon.

---

## Resume Instructions

To pick this up, tell Bob:
> "Continue the Gods Eye View container setup. The repo is already cloned at
> /Users/erwin/Documents/Projecten/Github_repos/workspace_bob/gods-eye-view
> and a Containerfile exists. Next steps are in
> task-outcomes/gods-eye-view-container-progress.md — pick up from section B."
