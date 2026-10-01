# StealthxUI Phase 1 setup

StealthxUI Phase 1 keeps the WindUI API/behavior intact while changing the library namespace and build/package identity.

## First-time repository setup

The icon dependency is retained as the original Git submodule:

```bash
git submodule add https://github.com/Footagesus/Icons.git src/Icons
git submodule update --init --recursive
```

After the repository is configured, the CI workflows use recursive submodule checkout automatically.

## Build

```bash
npm install
aftman install
npm run build
```

Production builds use `build/darklua.config.json`; development builds use `build/darklua.dev.config.json`.
