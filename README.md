# Drone GitHub Release Plugin

This project hosts a Container Image definition that fits on top of the official
[GitHub Release Drone Plugin](https://github.com/drone-plugins/drone-github-release).

## Motivation

A drone plugin is just a container image with some software that receives environment variables, then produces
an output. You can *(potentially)*[**(1)**](#potentially) use a plugin in two different ways:

[As a plugin](http://plugins.drone.io/drone-plugins/drone-github-release/):

```yaml
---
kind: pipeline
name: Release

steps:
- name: release
    image: plugins/github-release
    settings:
      GITHUB_TOKEN:
        from_secret: GITHUB_TOKEN
    when:
      event:
        - tag
```

As a regular step:

```yaml
---
kind: pipeline
name: Release

steps:
- name: release
    image: plugins/github-release
    environment:
      GITHUB_TOKEN:
        from_secret: GITHUB_TOKEN
    commands:
      - drone-github-release
    when:
      event:
        - tag
```

### Potentially?

> Note the environment section cannot expand environment variables or evaluate shell expressions.
> If you need to construct variables it should be done in the commands section.
*Source: [https://docs.drone.io/pipeline/environment/syntax/](https://docs.drone.io/pipeline/environment/syntax/)*

In some scenarios is required to compute some environment variables / settings that depends on other environment
variables.

In order to do something like:

```yaml
kind: pipeline
name: Release

steps:
  - name: release
    image: plugins/github-release
    environment:
      GITHUB_TOKEN:
        from_secret: GITHUB_TOKEN
    commands:
      - export GITHUB_RELEASE_TITLE="Welcome $${DRONE_TAG} release"
      - export GITHUB_RELEASE_NOTE="docs/releases/$${DRONE_TAG}.md"
      - drone-github-release
    when:
      event:
        - tag
```

It is required to run the plugin as a regular step to configure these environment variables
that are based in the value of `${DRONE_TAG}`.

The main problem is that a regular step requires the container image to have `/bin/sh` and/or `/bin/bash` installed.
This plugins lacks this requirement:

```bash
$ docker run -it --entrypoint /bin/sh --rm plugins/github-release
docker: Error response from daemon: OCI runtime create failed: container_linux.go:367: starting container process caused: exec: "/bin/sh": stat /bin/sh: no such file or directory: unknown.
```

So in order to solve the issue, we have created this repository that creates a container image starting from
the upstream container image but based on `debian:buster`. This adds a proper shell enabling the usage of the plugin
also as a regular drone pipeline step.

```yaml
kind: pipeline
name: Release

steps:
  - name: release
    image: registry.sighup.io/fury/drone-github-release:latest # This is the new image
    environment:
      GITHUB_TOKEN:
        from_secret: GITHUB_TOKEN
    commands:
      - export GITHUB_RELEASE_TITLE="Welcome $${DRONE_TAG} release"
      - export GITHUB_RELEASE_NOTE="docs/releases/$${DRONE_TAG}.md"
      - drone-github-release
    when:
      event:
        - tag
```

### Dockerfile

You can check the resulting [Dockerfile here](Dockerfile).

```Dockerfile
FROM plugins/github-release:latest as binary

FROM debian:buster
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=binary /bin/drone-github-release /bin/drone-github-release
ENTRYPOINT [ "/bin/drone-github-release" ]
```

## Build

Build the Docker image with the following command:

```console
docker build --tag registry.sighup.io/fury/drone-github-release .
```

## Usage

### Local

```console
docker run --rm \
  -e DRONE_BUILD_EVENT=tag \
  -e DRONE_REPO_OWNER=octocat \
  -e DRONE_REPO_NAME=foo \
  -e DRONE_COMMIT_REF=refs/heads/master \
  -e PLUGIN_API_KEY=${HOME}/.ssh/id_rsa \
  -e PLUGIN_FILES=master \
  -v $(pwd):$(pwd) \
  -w $(pwd) \
  registry.sighup.io/fury/drone-github-release
```

### Pipeline

You can follow upstream documentation from [here](http://plugins.drone.io/drone-plugins/drone-github-release/) just
changing the `image`:

From: `plugins/github-release`, to: **`registry.sighup.io/fury/drone-github-release`**

Examples:

As a plugin:

```yaml
---
kind: pipeline
name: Release

steps:
- name: release
    image: registry.sighup.io/fury/drone-github-release:latest
    settings:
      GITHUB_TOKEN:
        from_secret: GITHUB_TOKEN
    when:
      event:
        - tag
```

Or as a regular step:

```yaml
kind: pipeline
name: Release

steps:
  - name: release
    image: registry.sighup.io/fury/drone-github-release:latest
    environment:
      GITHUB_TOKEN:
        from_secret: GITHUB_TOKEN
    commands:
      - drone-github-release
    when:
      event:
        - tag
```

## License

Read the [License file](LICENSE)
