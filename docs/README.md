# God's Eye View — Setup Guide for Non-Developers

> **You don't need to understand code to follow this guide.**
> Every step is written for someone who has never set up a developer project before.
> If a step says "⚠️ This could cost money", read it carefully and confirm before continuing.

---

## What you'll end up with

A container — think of it as a self-contained copy of the app running on your computer — that you can open in your browser like any normal website.  It shows a photorealistic, interactive 3D globe with live aircraft, ships, satellites, earthquakes, traffic, public cameras, and more.

> This repository is forked from [bilawalsidhu/gods-eye-view](https://github.com/bilawalsidhu/gods-eye-view) All kudos to them.
> This is a containerized version of the original work, no additional features. The original README for this project can be read at [README_gods-eye-view](https://github.com/ncee-dp-tech-sme/gods-eye-view/blob/feature/bob-containerization/ORIGINAL_gods-eye-view_README.md)

---

## Step 0 — Download the code

You don't need Git or any developer tools to get the files.  Just use your browser.

1. Click this link to download everything as a ZIP file:
   **[⬇️ Download gods-eye-view.zip](https://github.com/ncee-dp-tech-sme/gods-eye-view/archive/refs/heads/feature/bob-containerization.zip)**

2. Once downloaded, find the ZIP file (usually in your **Downloads** folder) and **unzip / extract** it.
   - **macOS:** double-click the ZIP file — it extracts automatically.
   - **Windows:** right-click the ZIP file → **"Extract All…"** → click **Extract**.
   - **Linux:** `unzip gods-eye-view-main.zip`

3. You'll now have a folder called **`gods-eye-view-main`**.  Open it — all the files are inside.

4. When this guide tells you to open a terminal "in the `gods-eye-view` folder", it means this extracted folder.

---

## Before you start — what you need installed

You need **Podman** (the program that runs the container).  It's free.

- **macOS:** `brew install podman && podman machine init && podman machine start`
  - Don't have Homebrew?  Install it first at https://brew.sh
- **Windows:** Download the installer from https://podman.io/getting-started/installation
- **Linux:** `sudo apt install podman` (Ubuntu/Debian) or `sudo dnf install podman` (Fedora/RHEL)

---

## Step 1 — Get your Google Maps API key (Required) 🔴

> ⚠️ **This step involves a service that charges money** — but Google gives you **1,000 free sessions per month**, which is very hard for a single person to use up during normal exploring.  A "session" lasts up to 3 hours of globe rendering.
>
> **You will set up a spending cap in Steps 1d and 1e below before any charges could ever reach you.**  Do not skip those sub-steps.

The Google Maps key is the only required key.  Without it the 3D photorealistic globe will not load.  Everything else in this guide is optional and free.

### 1a. Create a Google Cloud account (if you don't have one)

1. Go to https://console.cloud.google.com
2. Sign in with your Google account (the same Gmail you use for everything else is fine).
3. If this is your first visit, Google will ask you to agree to their terms and set up a billing account.  **You will not be charged yet** — Google Cloud requires a payment method on file but gives every new account $300 of free credits that cover months of typical usage.

### 1b. Create a project

1. At the top of the page, click the project dropdown (it may say "My First Project" or show a project name).
2. Click **"New Project"**.
3. Give it a name like `gods-eye-view` and click **Create**.
4. Wait a few seconds for it to be created, then select it from the same dropdown.

### 1c. Enable the Map Tiles API

The Map Tiles API is the specific Google service that provides the 3D photorealistic imagery.

1. In the search bar at the top of the Google Cloud Console, type **`Map Tiles API`** and click the result.
2. Click the blue **"Enable"** button.
3. Wait a moment for it to activate.

### 1d. Set a budget alert ⚠️ (Do this BEFORE creating the key)

This is your safety net.  It sends you an email warning before you get anywhere near a real charge.

1. In the left-hand menu, find and click **"Billing"**.
   - If you don't see it, click the ☰ (hamburger) menu at the top-left first.
2. Click **"Budgets & alerts"**.
3. Click **"Create budget"**.
4. Fill in the form:
   - **Name:** `gods-eye-view-budget`
   - **Scope:** leave as-is (it will apply to your whole project)
   - **Amount:** set to `5` (this means $5 USD — you'll be notified before spending this much)
   - **Alert thresholds:** leave the defaults (50%, 90%, 100%)
   - **Email notifications:** make sure your email is listed
5. Click **"Finish"**.

✅ You'll now get an email warning if you ever approach $5 in charges.  Normal single-person use of this app should cost $0 most months.

### 1e. Set a daily quota cap ⚠️ (Do this BEFORE creating the key)

A budget alert *tells* you about spending.  A quota cap *stops* it.

1. In the left menu, go to **"APIs & Services"** → **"Enabled APIs & services"**.
2. Click on **"Map Tiles API"** in the list.
3. Click the **"Quotas & System Limits"** tab at the top.
4. Find **"Map session tokens per day"** in the list.
5. Click the pencil ✏️ icon to edit it.
6. Set the limit to `50` (that's 50 sessions per day — more than enough for personal use, and it prevents any runaway spending).
7. Click **"Save"**.

✅ You now have a hard daily ceiling.  Even if something went wrong, you could never spend more than a few cents per day.

### 1f. Create the API key

1. In the left menu, go to **"APIs & Services"** → **"Credentials"**.
2. Click **"+ Create Credentials"** at the top, then choose **"API key"**.
3. A pop-up shows your new key — it looks like `AIzaSy...` (a long string of letters and numbers).
4. Click **"Copy"** to copy it.  **Do not close this pop-up yet.**

### 1g. Restrict the key (important security step)

An unrestricted API key could be used by anyone who finds it.  Restricting it means it only works for this specific app.

1. In the same pop-up, click **"Edit API key"** (or find the key in the Credentials list and click its name).
2. Under **"Application restrictions"**, choose **"HTTP referrers (websites)"**.
3. Click **"Add an item"** and type: `http://localhost:4173/*`
4. Click **"Add another item"** and type: `http://127.0.0.1:4173/*`
5. Under **"API restrictions"**, choose **"Restrict key"**, then select **"Map Tiles API"** from the dropdown.
6. Click **"Save"**.

✅ The key is now locked to only work when used from your local machine on port 4173.

### 1h. Put the key in your .env file

1. In the `gods-eye-view` folder, find the file called `.env.example`.
2. Make a copy of it and name the copy `.env` (no `.example` at the end).
   - On macOS/Linux in Terminal: `cp .env.example .env`
   - On Windows: right-click the file, Copy, Paste, rename to `.env`
3. Open `.env` in any text editor (Notepad, TextEdit, VS Code — anything works).
4. Find the line that says: `GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here`
5. Replace `your_google_maps_api_key_here` with the key you copied in step 1f.
6. Save the file.

---

## Step 2 — Optional free keys (add as many or as few as you like)

All of these are completely free.  Each one unlocks an additional layer in the app.  You can skip any or all of them and come back later.

### 🟡 Cesium Ion token — unlocks Bing satellite map styles

Cesium Ion provides alternative satellite imagery (Bing Maps).  The app works without it — you just won't have those map style options.

1. Go to https://ion.cesium.com and create a free account.
2. After signing in, click your profile icon → **"Access tokens"**.
3. Click **"Create token"**.
4. Give it a name like `gods-eye-view`.
5. Under **"Scope"**, select only **"assets:read"**.
6. Click **"Create"** and copy the token.
7. In your `.env` file, find the line: `CESIUM_ION_TOKEN=`
8. Paste the token after the `=` sign.

### 🟡 AISStream key — unlocks the live ships layer

AISStream provides real-time ship positions from AIS transponders worldwide.  Free forever for open-source use.

1. Go to https://aisstream.io and create a free account.
2. After signing in, go to **"API Keys"** and click **"Create New API Key"**.
3. Copy the key.
4. In your `.env` file, find: `AISSTREAM_API_KEY=`
5. Paste the key after the `=` sign.

### 🟡 TomTom key — unlocks live traffic flow

Without this key the app shows a simulated traffic layer (clearly labelled as such).  TomTom's free tier gives you 50,000 tile requests per day — more than enough for personal use.

1. Go to https://developer.tomtom.com and create a free account.
2. After signing in, go to **"My Apps"** → **"Create a new app"**.
3. Give it a name and click **"Next"**.  Select **"Traffic"** as the product.
4. Copy the API key shown on your new app's page.
5. In your `.env` file, find: `TOMTOM_API_KEY=`
   - The line is commented out (starts with `#`) — remove the `#` first, then add your key.

### 🟡 NASA FIRMS key — unlocks the active fires layer

NASA's FIRMS (Fire Information for Resource Management System) provides near real-time fire detections from satellites.  Completely free.

1. Go to https://firms.modaps.eosdis.nasa.gov/api/map_key/
2. Fill in the short form (name + email) and click **"Request MAP_KEY"**.
3. You'll receive an email with your key within a few minutes.
4. In your `.env` file, find the line that says: `# FIRMS_MAP_KEY=`
5. Remove the `#` at the start of the line and paste your key after the `=`.

### 🟡 OpenSky credentials — improves aircraft data quality

Without credentials, aircraft data still works (anonymous access) but with a stricter rate limit.  If you'd like more frequent updates, create a free account.

1. Go to https://opensky-network.org and click **"Register"**.
2. After verifying your email, go to **"My OpenSky"** → **"Account"**.
3. Under **"OAuth Client Credentials"**, click **"Generate credentials"**.
4. Copy the `client_id` and `client_secret` values.
5. In your `.env` file, find and fill in:
   ```
   OPENSKY_AUTH_MODE=oauth
   OPENSKY_CLIENT_ID=<your client_id here>
   OPENSKY_CLIENT_SECRET=<your client_secret here>
   ```

### 🔴 OpenAI key — unlocks voice control and AI HUD summary (costs money)

> ⚠️ **OpenAI charges per minute of voice conversation.**  The app has a built-in
> $5 per-session cap.  Visit https://platform.openai.com → **Settings → Limits**
> to set a monthly usage limit before enabling this.
>
> **Ask before continuing if you are unsure about the cost.**

1. Go to https://platform.openai.com and sign in or create an account.
2. **Set a monthly spending limit first:** go to **Settings → Limits → Monthly budget** and set it to something low like `$5`.
3. Go to **API keys** → **"Create new secret key"**.
4. Copy the key.
5. In your `.env` file, find: `OPENAI_API_KEY=`
6. Paste the key after the `=` sign.

---

## Step 3 — Start the container

Open a terminal in the `gods-eye-view` folder and run:

```bash
./run.sh
```

**What happens next:**
- The first run downloads the base image and installs all dependencies (3–8 minutes depending on your internet speed).
- Subsequent starts take under a minute because everything is cached.
- The script will print a green URL when the server is ready.
- Open **http://localhost:4173** in your browser.
- Press **Ctrl+C** in the terminal to stop.

### Useful commands

| What you want to do | Command |
|---------------------|---------|
| Start the app | `./run.sh` |
| Stop the app | Press `Ctrl+C` in the terminal, or run `./run.sh --stop` in another terminal |
| Rebuild after a code update | `./run.sh --rebuild` |
| Check if the container is running | `podman ps` |
| See the app's log output | `podman logs gods-eye-view-dev` |

---

## Troubleshooting

**"No .env file found"**
Run `cp .env.example .env` in the `gods-eye-view` folder, then edit `.env` to add your Google Maps key.

**The globe loads but is grey / no 3D buildings**
Your Google Maps key is likely missing or incorrect.  Double-check step 1h.  Make sure there are no spaces around the `=` sign in `.env`.

**"GOOGLE_MAPS_API_KEY is not set"**
Open `.env` and make sure the line reads exactly:
`GOOGLE_MAPS_API_KEY=AIzaSy...` (your real key, no quotes, no spaces).

**The page won't load at all**
The container may still be starting.  Wait 30–60 seconds and try refreshing.  If it still doesn't load, run `podman logs gods-eye-view-dev` to see any error messages.

**Port 4173 is already in use**
Another program is using that port.  Set a different port in your `.env` file:
`PORT=4174`
Then restart with `./run.sh`.  Open http://localhost:4174 instead.

---

## Quick cost summary

| Layer | Cost | Notes |
|-------|------|-------|
| 3D photorealistic globe | 🔴 Metered | ~1,000 free sessions/month — hard to exhaust solo |
| Voice control + AI HUD | 🔴 Metered | Charged per minute of voice; built-in $5 session cap |
| Live aircraft (OpenSky) | 🟡 Free | Anonymous or authenticated — both free |
| Live ships (AISStream) | 🟡 Free | Free API |
| Satellites, earthquakes, fires | 🟡 Free | Public data sources |
| Public cameras (CCTV) | 🟡 Free | City open-data feeds |
| Traffic (TomTom) | 🟡 Free tier | 50k tile requests/day free |
| Alternative map styles (Cesium) | 🟡 Free tier | Public assets token |
| Rocket launches, radio stations | 🟡 Free | Public APIs |

For typical solo exploring on your own machine: **expect $0 per month** unless you use voice control heavily.

---

*See also: [SECURITY.md](https://github.com/ncee-dp-tech-sme/gods-eye-view/blob/feature/bob-containerization//SECURITY.md) for how your API keys are protected, and [DATA_SOURCES.md](https://github.com/ncee-dp-tech-sme/gods-eye-view/blob/feature/bob-containerization/DATA_SOURCES.md) for details on every live data feed.*

## Disclaimer
- Created by Erwin Friethoff, Security Architect at IBM. 
- This is 100% free and open source and not in any way endorsed or supported by IBM. All done on personal title. 
- If you have any questions, please reach out to me on LinkedIn. I’m happy to help.
- 100% free and open source. No warranty. 
- GitHub Issues: Report bugs or request features
