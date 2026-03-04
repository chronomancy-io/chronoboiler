# Chronoboiler

Standardization templates for repository portfolios.

[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg)](https://github.com/RichardLitt/standard-readme)
![License](https://img.shields.io/badge/License-Apache_2.0-blue)
![WASP v1.0.0](https://img.shields.io/badge/WASP-v1.0.0-blue)
![CDE v1.0.0](https://img.shields.io/badge/CDE-v1.0.0-green)
![MSS v1.0.0](https://img.shields.io/badge/MSS-v1.0.0-orange)

Encodes CDE dimensions (template type, option set, file graph, parameter map) to generate repeatable, MSS-compliant scaffolding across multiple languages.

## Background

Chronoboiler provides templates, validation scripts, and CI/CD workflows for maintaining consistent structure across repositories that use different languages and tools.

### CDE Implementation

#### Dimensions

- **Template type**: language/stack selection.
- **Option set**: toggles for CI, docs, licensing, and code style.
- **File graph**: mapping from template files to destination paths.
- **Parameter map**: placeholders → concrete values.

#### Query Workload

ChronoBoiler is optimized for:

- "Given a template and options, instantiate a new repository skeleton."
- "Given a repo, map back to the template and parameterization that produced it."
- "Generate repeatable, MSS-compliant scaffolding across multiple languages."

#### Minimal Sufficient Statistic

Template type, option set, file graph, and parameter map are:

- The smallest set that can fully reconstruct any instantiated repo, and
- Sufficient to reason about its structure and standards.

This CDE is an MSS for template-driven repository generation.

## Install

```bash
git clone https://github.com/chronomancy-io/chronoboiler.git
```

## Usage

### Apply to a New Repository

```bash
./chronoboiler/scripts/sync-templates.sh /path/to/your-repo rust
```

### Validate a Repository

```bash
./scripts/validate-repo.sh /path/to/repo
```

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

| Config | Language | Example Use |
|--------|----------|-------------|
| `configs/rust.yaml` | Rust | Game engines, performance-critical |
| `configs/typescript.yaml` | TypeScript | Web applications, simulations |
| `configs/swift.yaml` | Swift | macOS/iOS applications |
| `configs/assembly-6502.yaml` | 6502 Assembly | Embedded, retro computing |
| `configs/forth.yaml` | Forth | Embedded, stack-based languages |
| `configs/python.yaml` | Python | General purpose, scripting |
| `configs/unrealscript.yaml` | UnrealScript | Game modding |

## Scripts

| Script | Purpose |
|--------|---------|
| `scripts/validate-repo.sh` | Check repository compliance |
| `scripts/validate-all.sh` | Check multiple repositories |
| `scripts/sync-templates.sh` | Deploy templates to a target repo |

## Standardized Repositories

| Repository | Language | Role |
|------------|----------|------|
| chronoengine | Rust | Rendering engine |
| chronoboids | TypeScript | Boid simulation |
| chronoforth | 6502 Assembly | Forth for C64 |
| chronosat | Forth | SAT verification |
| chronoquit | Swift | macOS utility |
| chronoscribe | Python | OCR text restoration |

## Versioning

Repositories reference chronoboiler in their `repo-config.yaml`:

```yaml
standardization:
  source: chronomancy-io/chronoboiler
  version: v1.0.0
```

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
