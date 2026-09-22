# React + Vite

This template provides a minimal setup to get React working in Vite with HMR and some Oxlint rules.

Currently, two official plugins are available:


## React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the Oxlint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and Oxlint's TypeScript related rules in your project.

# TravelWise frontend-web

## Setup commands

```powershell
cd TravelWise
npm create vite@latest frontend-web -- --template react
cd frontend-web
npm install
npm install axios react-router-dom react-hook-form zod @hookform/resolvers lucide-react tailwindcss @tailwindcss/vite
npm run dev
```

Tailwind is configured through `@tailwindcss/vite`; styles are imported from `src/index.css`.
Set `VITE_API_URL` in `.env` to the backend base URL, for example `https://localhost:7127/api`.
