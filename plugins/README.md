# Bundled Plugins

Go plugin binaries are downloaded from the tinycode release during the container build. They are placed in `/opt/tinycode-plugins/` and added to `PATH`.

The entrypoint scans this directory for executables named `tinycode-plugin-<name>` and adds each to the plugin array in `config.json`.

## What's included

The container build downloads the `tinycode-plugins-linux-<arch>.tar.gz` bundle from the GitHub release. This includes all curated plugins (safety-net, ocp-context-injection, etc.).

## Adding a plugin manually

Copy a plugin binary into `/opt/tinycode-plugins/` before the entrypoint runs, or use `tinycode plugin install <name>` at runtime.

## Plugin list

See [plugin-catalog.md](https://github.com/bobbyjohnstx/tinycode/blob/main/docs/plugin-catalog.md) for the full registry.
