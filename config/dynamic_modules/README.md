# Dynamic Module Config

Server-local module config overrides live here as `<module-id>.toml`.

Each module owns its default config and optional schema. Overrides here are
merged on top during `dynamic-modules prepare`.
