# GitHub Action Catalog

This directory is the approved allowlist for GitHub Actions in the `vncc-pipeline` repository.
Any workflow change should prefer actions listed here before introducing an unapproved action.

## Approved actions

| Action | Version | Type | Source | Where used |
| --- | --- | --- | --- | --- |
| `actions/checkout` | `v4` | Official GitHub Action | `https://github.com/actions/checkout` | checkout workflow source and reusable jobs |
| `actions/setup-java` | `v4` | Official GitHub Action | `https://github.com/actions/setup-java` | Maven environment setup in composite action |
| `actions/cache` | `v4` | Official GitHub Action | `https://github.com/actions/cache` | Maven and npm dependency caching |
| `actions/setup-node` | `v4` | Official GitHub Action | `https://github.com/actions/setup-node` | Node.js environment setup for npm workflows |
| `pnpm/action-setup` | `v4` | Third-party GitHub Action | `https://github.com/pnpm/action-setup` | pnpm setup in the reusable pnpm installation action |
| `pietrobolcato/action-read-yaml` | `1.1.0` | Third-party GitHub Action | `https://github.com/pietrobolcato/action-read-yaml` | YAML config reading in reusable build/test workflow |
| `./pipeline/.github/actions/build-test-delivery/dependencies/installation/mvn` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/dependencies/installation/mvn/action.yml` | Maven install and dependency resolution |
| `./pipeline/.github/actions/build-test-delivery/dependencies/installation/npm` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/dependencies/installation/npm/action.yml` | npm install and dependency resolution |
| `./pipeline/.github/actions/build-test-delivery/dependencies/installation/pnpm` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/dependencies/installation/pnpm/action.yml` | pnpm setup, lockfile-based dependency cache, and dependency installation |
| `./pipeline/.github/actions/build-test-delivery/delivery/container/docker` | repo-local composite action | Local composite action | `vncc-pipeline/.github/actions/build-test-delivery/delivery/container/docker/action.yml` | Docker image build for delivery |

## Notes
- These entries were identified by scanning the workflow files and composite actions under `vncc-pipeline/.github/`.
- The allowlist is intentionally scoped to the actions actually referenced in this repository and is meant to prevent ad hoc GitHub Action usage.
