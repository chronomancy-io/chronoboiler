# Contributing to chronoboiler

Thank you for your interest in contributing to chronoboiler! This document outlines the process and requirements for contributing.

## Code Review Process

All PRs must pass automated CI checks before review.

### SOLID Principles Checklist

Since chronoboiler is primarily shell scripts and templates, SOLID principles apply differently:

#### Single Responsibility Principle (S)

- [ ] Each script does ONE thing (validate OR sync OR batch-validate)
- [ ] Each template serves ONE purpose
- [ ] Config files are language-specific, not mixed

#### Open/Closed Principle (O)

- [ ] New languages added via new config files, not script modification
- [ ] Templates extensible via additional placeholders
- [ ] Validation checks can be added without modifying core logic

#### Liskov Substitution Principle (L)

- [ ] All language configs are interchangeable in sync-templates.sh
- [ ] All repos pass the same validation criteria

#### Interface Segregation Principle (I)

- [ ] Scripts accept minimal required arguments
- [ ] Optional features controlled by separate flags/options

#### Dependency Inversion Principle (D)

- [ ] Scripts depend on abstract config structure, not specific languages
- [ ] No hardcoded language-specific logic in core scripts

## Testing Requirements

Every PR must include appropriate tests.

### Script Testing

```bash
# Validate the validation script works
./scripts/validate-repo.sh .

# Test sync on a temp directory
mkdir /tmp/test-repo
./scripts/sync-templates.sh /tmp/test-repo python
./scripts/validate-repo.sh /tmp/test-repo
rm -rf /tmp/test-repo
```

### Template Testing

Ensure templates:

1. Use consistent `{{PLACEHOLDER}}` format
2. Have all required sections
3. Meet minimum line counts

### CI Verification

All changes must pass:

- shellcheck for shell scripts
- yamllint for YAML files
- Template structure validation
- Self-validation

## Adding a New Language

1. Create `configs/newlanguage.yaml`:

```yaml
language:
  name: NewLanguage
  version: "1.0"
  file_extensions: [".nl"]

github_actions:
  setup_action: actions/setup-newlanguage@v1
  setup_version_key: newlanguage-version
  cache_path: ~/.newlanguage/cache
  lock_file: newlanguage.lock

commands:
  install: newlang install
  lint: newlang lint
  format_check: newlang fmt --check
  test: newlang test
  coverage: newlang coverage
  bench: newlang bench
  build: newlang build

coverage:
  file: coverage.xml
  threshold: 80

benchmark:
  tool: customSmallerIsBetter
  output_file: benchmark.json

artifacts:
  path: dist/

example:
  project_name: my-newlang-project
  description: "A NewLanguage project"
  cde_role: simulation
  complexity_profile: hpc
  complexity_proven: true
  benchmarks_enforced: true
```

1. Test with sync-templates.sh
2. Update README.md language table
3. Submit PR

## Adding a New Template

1. Create template in `templates/` with `.template.md` or `.template.yaml` suffix
2. Use `{{PLACEHOLDER}}` syntax for all variable content
3. Include standardization footer:

```markdown
---

*Standardized with [chronoboiler](https://github.com/the-chronomancer/chronoboiler) v{{CHRONOBOILER_VERSION}}*
```

1. Update sync-templates.sh to copy the new template
2. Update documentation
3. Submit PR

## Modifying Validation Rules

1. Edit `scripts/validate-repo.sh`
2. Add new check with appropriate pass/fail/warn calls:

```bash
section "NEW CHECK: Description"

if [[ -f "$TARGET_DIR/new-file" ]]; then
    pass "Found: new-file"
else
    fail "Missing: new-file"  # or warn() for non-critical
fi
```

1. Test against multiple repos (`./scripts/validate-all.sh`)
2. Submit PR

## Submission Process

1. Fork repo
2. Create feature branch: `git checkout -b feature/my-feature`
3. Make changes
4. Run validation: `./scripts/validate-repo.sh .`
5. Ensure CI passes locally if possible
6. Push and open PR
7. All checks must pass before merge

## Commit Message Format

Use conventional commits:

```text
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**

- `feat`: New feature (template, config, script)
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting (no code change)
- `refactor`: Code restructuring (no behavior change)
- `test`: Adding/updating tests
- `chore`: Maintenance tasks

**Examples:**

```text
feat(configs): add Ruby language configuration

docs(readme): clarify versioning strategy

fix(validate): handle missing yq gracefully
```

## Version Bumping

When your changes warrant a version bump, note the change in the PR description
and bump the `version` referenced in `repo-config.yaml` /
`templates/repo-config.template.yaml`. (There is no `CHANGELOG.md` in this repo
at present.)

## Questions?

- See [ARCHITECTURE.md](./ARCHITECTURE.md) for system design
- See [README.md](./README.md) for usage
- Open an issue for clarification

---

*Standardized with [chronoboiler](https://github.com/the-chronomancer/chronoboiler) v1.0.0*
