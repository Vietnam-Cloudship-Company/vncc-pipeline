# GitHub Action Catalog

This directory is the approved allowlist for GitHub Actions in the `vncc-pipeline` repository.
Any workflow change should prefer actions listed here before introducing an unapproved action.

## Approved external actions

| Action | Version | Type | Source | Where used |
| --- | --- | --- | --- | --- |
| `actions/checkout` | `v4` | Official GitHub Action | `https://github.com/actions/checkout` | checkout workflow source and reusable jobs |
| `actions/setup-java` | `v4` | Official GitHub Action | `https://github.com/actions/setup-java` | Maven environment setup in composite action |
| `actions/cache` | `v4` | Official GitHub Action | `https://github.com/actions/cache` | Maven and npm dependency caching |
| `actions/setup-node` | `v4` | Official GitHub Action | `https://github.com/actions/setup-node` | Node.js environment setup for npm workflows |
| `pnpm/action-setup` | `v4` | Third-party GitHub Action | `https://github.com/pnpm/action-setup` | pnpm setup in the reusable pnpm installation action |
| `pietrobolcato/action-read-yaml` | `1.1.0` | Third-party GitHub Action | `https://github.com/pietrobolcato/action-read-yaml` | YAML config reading in reusable build/test workflow |


## VNCC provided actions
| Action | Version | Type | Source | Where used |
| --- | --- | --- | --- | --- |
| `./pipeline/.github/actions/build-test-delivery/dependencies/installation/mvn` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/dependencies/installation/mvn/action.yml` | Maven install and dependency resolution |
| `./pipeline/.github/actions/build-test-delivery/dependencies/installation/npm` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/dependencies/installation/npm/action.yml` | npm install and dependency resolution |
| `./pipeline/.github/actions/build-test-delivery/dependencies/installation/pnpm` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/dependencies/installation/pnpm/action.yml` | pnpm setup, lockfile-based dependency cache, and dependency installation |
| `./pipeline/.github/actions/build-test-delivery/delivery/container/docker` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/delivery/container/docker/action.yml` | Docker image build for delivery |
| `./.github/actions/build-test-delivery/dependencies/installation/mvn` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/dependencies/installation/mvn/action.yml` | Set up Java, restore Maven cache, and resolve dependencies |
| `./.github/actions/build-test-delivery/dependencies/installation/npm` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/dependencies/installation/npm/action.yml` | Set up Node, restore npm cache, and install dependencies |
| `./.github/actions/build-test-delivery/dependencies/installation/pnpm` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/dependencies/installation/pnpm/action.yml` | Set up pnpm/Node, configure cache, and install dependencies |
| `./.github/actions/build-test-delivery/delivery/binary/maven` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/delivery/binary/maven/action.yml` | Run optional Maven tests and package the service |
| `./.github/actions/build-test-delivery/delivery/binary/npm` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/delivery/binary/npm/action.yml` | Run optional npm tests and build the service |
| `./.github/actions/build-test-delivery/delivery/binary/pnpm` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/delivery/binary/pnpm/action.yml` | Run optional pnpm tests and build the service |
| `./.github/actions/build-test-delivery/delivery/container/docker` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/delivery/container/docker/action.yml` | Build, optionally push, and clean up a Docker image |
| `./.github/actions/build-test-delivery/delivery/container/vncc_provided_docker` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/delivery/container/vncc_provided_docker/action.yml` | Inject a Dockerfile template, build, and optionally push/clean up an image |

## Notes
- These entries were identified by scanning the workflow files and composite actions under `vncc-pipeline/.github/`.
- The allowlist is intentionally scoped to the actions actually referenced in this repository and is meant to prevent ad hoc GitHub Action usage.
