# docker-images
Repo to build images and host them on Github

* Each branch refers to a different docker image.

## IDDOC development toolchain

The `iddoc-devtoolchain` branch publishes `ghcr.io/softrams/docker-images:iddoc-devtoolchain`.
It is a non-root Ubuntu 24.04 development environment intended for VS Code or
Cursor Dev Containers, with Node.js 20, Python 3.12, Go, Terraform and common
AWS/IaC utilities.

This is a toolchain image, not an agent runtime: it intentionally does not
install or configure OpenCode or GitHub Copilot CLI. Developers can install or
authenticate their preferred tools separately in their workspace.

For a Dev Container, select the image and its workspace user in the project's
`.devcontainer/devcontainer.json`:

```json
{
  "image": "ghcr.io/softrams/docker-images:iddoc-devtoolchain",
  "remoteUser": "vscode"
}
```
