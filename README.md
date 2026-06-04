# Chronoboiler

Standardization templates for repository portfolios.

[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg)](https://github.com/RichardLitt/standard-readme)
![License](https://img.shields.io/badge/License-Apache_2.0-blue)
![WASP v1.0.0](https://img.shields.io/badge/WASP-v1.0.0-blue)
![CDE v1.0.0](https://img.shields.io/badge/CDE-v1.0.0-green)
![MSS v1.0.0](https://img.shields.io/badge/MSS-v1.0.0-orange)

Zero-dependency bash scaffolding plus per-language YAML configs and shared
templates, used to give the chrono-* repositories a consistent structure.

## Background

Chronoboiler provides templates, validation scripts, and CI/CD workflows for maintaining consistent structure across repositories that use different languages and tools.

### CDE Framing (Definition)

Chronoboiler is described in terms of four conceptual dimensions. These are a
**descriptive framing** over the bash scripts and YAML configs, not a built or
queryable index. No index is constructed; `sync-templates.sh` performs `sed`
placeholder substitution and `validate-repo.sh` performs file-existence,
YAML-field, and line-count checks.

- **Template type**: language/stack selection (chooses a `configs/*.yaml`).
- **Option set**: toggles for CI, docs, licensing, and code style.
- **File graph**: mapping from template files to destination paths (the
  manifest in `sync-templates.sh`).
- **Parameter map**: `{{PLACEHOLDER}}` tokens → concrete values.

#### What the tooling actually does (Definition)

- "Given a config and a target directory, copy the templates and substitute
  `{{PLACEHOLDER}}` values" — implemented by `scripts/sync-templates.sh`.
- "Given a repo, check it for the required files, a valid `repo-config.yaml`,
  a CI workflow, and minimum doc length" — implemented by
  `scripts/validate-repo.sh`.

> **Assumption, not Guarantee.** The four dimensions are an informal framing.
> Chronoboiler does not store or query a reverse index, so "map a repo back to
> the template and parameters that produced it" is not implemented and is not a
> guarantee. The claim that these four fields are a *minimal sufficient
> statistic* that can reconstruct an instantiated repo is unproven in this repo
> and is treated here as framing, not a proven property.

## Install

```bash
git clone https://github.com/chronomancy-io/chronoboiler.git
```

## Usage

### Apply to a New Repository

```bash
# Run from the chronoboiler repo root
./scripts/sync-templates.sh /path/to/your-repo rust
```

### Validate a Repository

```bash
./scripts/validate-repo.sh /path/to/repo
```

Chronoboiler passes its own validator. Measured on the audit machine
(AMD Ryzen 7 5800X, bash 5.2.37), `./scripts/validate-repo.sh .` exits `0`
both with and without `yq` installed. See [PERFORMANCE.md](PERFORMANCE.md) for
the measured timings and an important note about the no-`yq` path.

## Templates

| Template | Purpose |
|----------|---------|
| `templates/README.template.md` | Project overview and quick start |
| `templates/ARCHITECTURE.template.md` | System design and component breakdown |
| `templates/PERFORMANCE.template.md` | Complexity analysis and benchmarks |
| `templates/CONTRIBUTING.template.md` | Code review and testing requirements |
| `templates/repo-config.template.yaml` | Repository configuration |
| `templates/github/workflows/ci.template.yml` | CI/CD pipeline |

## Language Configurations

Eight configs ship in `configs/`. The `language.name` column below is read
directly from each file; the example role is the config's own `example.cde_role`.

| Config | Language (`language.name`) | `example.cde_role` |
|--------|----------------------------|--------------------|
| `configs/rust.yaml` | Rust | engine |
| `configs/typescript.yaml` | TypeScript | simulation |
| `configs/swift.yaml` | Swift | utility |
| `configs/assembly-6502.yaml` | 6502 Assembly | embedded |
| `configs/forth.yaml` | Forth | embedded |
| `configs/python.yaml` | Python | pipeline |
| `configs/java.yaml` | Java | simulation |
| `configs/unrealscript.yaml` | UnrealScript | game-mod |

## Scripts

| Script | Shell | Purpose |
|--------|-------|---------|
| `scripts/validate-repo.sh` | bash | Check a single repository's compliance |
| `scripts/validate-all.sh` | bash | Validate every sibling repo that has a `repo-config.yaml` |
| `scripts/sync-templates.sh` | bash | Deploy templates to a target repo |
| `scripts/lint-all-repos.sh` | zsh | Run language linters across the chrono-* repos (optional; needs zsh + linters) |

## Standardized Repositories

The chrono-* portfolio is the intended consumer of these templates. Languages
below are read from each sibling repo's own `repo-config.yaml` where one was
present at audit time; entries without a sibling repo are marked.

| Repository | Language (from its `repo-config.yaml`) |
|------------|----------------------------------------|
| chronoengine | Rust |
| chronoforth | Forth |
| chronosat | Forth |
| chronoquit | Swift |
| chronoscribe | Python |

> **Unknown / aspirational.** As of this audit, none of these repos declares
> `standardization.source: chronoboiler` in its `repo-config.yaml`, so the link
> is by convention only, not recorded in the configs. A `chronoboids`
> (TypeScript boid simulation) repo is referenced elsewhere in the framing but
> was not present alongside this repo at audit time.

## Versioning

The template configuration includes a `standardization` block intended to let a
consuming repo record where its scaffolding came from:

```yaml
standardization:
  source: the-chronomancer/chronoboiler
  version: v1.0.0
```

> **Assumption.** This is the convention encoded in
> `templates/repo-config.template.yaml`. At audit time the chrono-* sibling
> repos did not actually carry this block, so it documents intended usage rather
> than current state.

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for component diagrams.

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make changes to templates or scripts
4. Ensure all CI checks pass
5. Submit a pull request

## License

Apache-2.0 © 2026 Jacob Coleman — See [LICENSE](LICENSE) for details.
