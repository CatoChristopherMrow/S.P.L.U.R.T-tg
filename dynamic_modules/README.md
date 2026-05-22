# Dynamic Modules

This folder is managed by Dynamic SS13 Modules.

- `framework/` pins the Dynamic SS13 Modules framework.
- `installed/` is for module repositories installed as submodules.
- `local/` is for SPLURT-local module manifests or server override modules.

Run this before compiling:

```bash
python3 tools/dynamic_modules/prepare.py
```

Generated files live in `.dynamic_modules_build/` and are intentionally not
committed.
