# Bundled Plugins

Add tinycode plugins here to pre-bake them into the container image.

## Adding a plugin

```bash
cd plugins/
npm install tinycode-plugin-example
```

This adds the package to `package.json` and downloads it to `node_modules/`. Both are committed to the repo so the container build doesn't need npm registry access.

## How it works

The ContainerFile COPYs `plugins/node_modules/` to `/opt/tinycode-plugins/` in the image. The entrypoint scans that directory for packages starting with `tinycode-plugin-` and adds each to the plugin array in `config.json`.

## Removing a plugin

```bash
cd plugins/
npm uninstall tinycode-plugin-example
```

Then commit the updated `package.json` and `node_modules/`.
