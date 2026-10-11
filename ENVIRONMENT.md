# Frontend environment configuration

Copy `.env.example` to `.env` and set `API_BASE_URL` to the public API base URL ending in `/api/v1`. `.env` is ignored by Git. The URL is injected at build time with `scripts/build_web.ps1`. Do not put credentials, API keys, or private tokens in frontend environment values because web assets are public.

The in-app Network Settings screen has been removed. Change the URL in `.env` and rebuild the client to switch backend environments.
