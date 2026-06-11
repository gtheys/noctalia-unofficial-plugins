# Noctalia Unofficial Plugins

An unofficial plugin registry for [Noctalia Shell](https://noctalia.dev) — a Quickshell-based desktop shell.

> **Note:** This is a community-maintained registry. Plugins here are not officially reviewed or endorsed by the Noctalia project.

## Plugins

| Plugin | Description | Version |
|--------|-------------|---------|
| [codexbar](./codexbar) | Codex usage limits in the Noctalia bar via CodexBar CLI | 1.0.0 |
| [easyeffects](./easyeffects) | Quick switch between Easy Effects output and input audio profiles | 1.0.4 |

## Installing a Plugin

Noctalia loads plugins from a registry URL. Add this registry in your Noctalia settings:

```
https://raw.githubusercontent.com/gtheys/noctalia-unofficial-plugins/main/registry.json
```

Or install a plugin manually by copying its folder into your Noctalia plugins directory.

## Contributing

### Adding a Plugin

1. Fork this repository
2. Create a folder matching your plugin `id` (e.g. `my-plugin/`)
3. Add all plugin files including a valid `manifest.json`
4. Run `python3 scripts/generate-registry.py` locally to validate (do **not** commit `registry.json` — CI auto-generates it)
5. Open a PR

### Manifest Requirements

- `id` **must** match the folder name
- `repository` must point to `https://github.com/gtheys/noctalia-unofficial-plugins`
- `metadata.defaultSettings` must include defaults for every setting used
- All user-facing strings must use `pluginApi?.tr()` with translations in `i18n/`

See the [official plugin docs](https://docs.noctalia.dev/development/plugins/overview/) for the full plugin API.

## Tags

Plugins should use tags from the official list:

`Bar` · `Panel` · `Audio` · `AI` · `Development` · `Indicator` · `System` · `Network` · `Media` · `Launcher` · `Clock` · `Weather` · `Hyprland` · `Niri` · `Sway` · `Labwc`

## License

Each plugin carries its own license. See the `LICENSE` file inside each plugin folder.
