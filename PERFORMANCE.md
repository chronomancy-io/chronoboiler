# Performance Analysis: chronoboiler

## 1. Complexity Classification

**Claim (Guarantee):** `validate-repo.sh` runs in **O(n)** time where n is the
total size (in lines) of the files it reads. This is derivable from the source.

**Derivation by component:**

| Component | Operation | Complexity | Justification |
|-----------|-----------|------------|---------------|
| `validate-repo.sh` | File existence checks | O(k) | k = fixed number of required files |
| `validate-repo.sh` | YAML field reads | O(m) | m = lines in `repo-config.yaml` (awk pass per field, or one `yq` call per field) |
| `validate-repo.sh` | Documentation line count | O(l) | l = total lines across the 4 doc files (one `awk 'END{print NR}'` per file) |
| `sync-templates.sh` | Placeholder replacement | O(t) per file | one `sed` pass over template of size t |

Combining: O(k) + O(m) + O(l) = **O(n)** in the content read. There is no
nested scan of the same content, so the linear bound holds.

> **Note (Assumption, not Guarantee):** the awk-based field reads in the no-`yq`
> path scan `repo-config.yaml` once per requested field. With a fixed, small
> field list this is still O(m); it is not O(m²) because the field list is a
> constant.

## 2. Measured Benchmarks

All numbers below were **measured on the audit machine**, not estimated.

### Test configuration

- **Hardware:** AMD Ryzen 7 5800X (16 logical cores)
- **OS:** Debian 13 (Linux 6.12)
- **Shell:** GNU bash 5.2.37
- **`yq`:** mikefarah/yq v4.53.2 (when present)
- **Iterations:** 10 runs per measurement
- **Repo under test:** chronoboiler itself (this repo, `mss-honesty` branch)

### Harness (reproducible)

```bash
# Run from the chronoboiler repo root.
# Drop yq from PATH for the no-yq path; include it for the with-yq path.
ITERATIONS=10
TOTAL=0
for i in $(seq 1 $ITERATIONS); do
  START=$(date +%s%N)
  ./scripts/validate-repo.sh . > /dev/null 2>&1
  END=$(date +%s%N)
  TOTAL=$(( TOTAL + (END - START) / 1000000 ))
done
echo "Average: $(( TOTAL / ITERATIONS ))ms"
```

### Observed results (measured 2026-06-04)

| Operation | Path | Per-run samples (ms) | Average |
|-----------|------|----------------------|---------|
| `validate-repo.sh .` | no `yq` (awk fallback) | 47 53 46 45 49 53 46 52 46 56 | **49 ms** |
| `validate-repo.sh .` | with `yq` v4.53.2 | 57 57 53 59 60 59 47 47 66 54 | **55 ms** |

`time ./scripts/validate-repo.sh .` on a single run:

```text
no yq:    real 0m0.049s   user 0m0.037s   sys 0m0.006s
with yq:  real 0m0.060s   user 0m0.028s   sys 0m0.026s
```

`validate-all.sh` (default mode: scans the parent directory and validates every
sibling that has a `repo-config.yaml`; 10 sibling repos found on the audit
machine, with `yq` present):

```text
time ./scripts/validate-all.sh
real 0m0.970s   user 0m0.318s   sys 0m0.265s
```

> **Unmeasured (removed):** earlier versions of this file listed `~50ms`,
> `~100ms`, `~200ms`, `~300ms`, a "< 500ms" target, and a `0m0.150s` sample
> output. None of those were produced by a harness in this repo; they have been
> replaced with the measured values above. `sync-templates.sh` is interactive
> (it prompts and waits for confirmation), so a clean wall-clock timing of it is
> not provided here rather than fabricated.

## 3. Self-Validation Status (measured)

`./scripts/validate-repo.sh .` exits `0` on this repo in **both** paths:

```text
no yq:   exit 0
with yq: exit 0
```

> **Note on the no-`yq` path.** The no-`yq` SEMANTICS check is a top-level-key
> structure check (`validate_yaml_structure`) that requires both a `repository`
> and a `semantics` key in `repo-config.yaml`. This repo's `repo-config.yaml`
> now carries a `semantics:` block so the check passes. Independently, the awk
> field parser (`yaml_get`) does not currently extract values past the leading
> `---` document marker, so the per-field "defined" lines in the no-`yq` path
> report nothing; those required-field misses do not increment the failure
> counter (a quirk of the validator, not a guarantee). With `yq` installed the
> field reads succeed and all four SEMANTICS fields pass cleanly. These are
> observations of current behavior, recorded honestly; the script itself was not
> modified in this docs-only change.

## 4. Memory Profile

No memory profiler was run, so per-allocation figures are **not** reported here.
The tools are short-lived bash processes plus, in the with-`yq` path, one `yq`
subprocess per field read; peak resident set is dominated by those processes and
does not grow with repository size (the scripts stream files line by line and
hold only counters and small strings in memory). Treat this as a structural
**Assumption** until a profiler run is added.

## 5. Linting (measured)

Reproduces the CI `lint-scripts` and `validate-yaml` jobs locally:

```text
shellcheck scripts/validate-repo.sh    -> clean
shellcheck scripts/validate-all.sh     -> clean
shellcheck scripts/sync-templates.sh   -> clean
yamllint -s repo-config.yaml configs/*.yaml -> exit 0 (clean)
```

> **Known issue (Unknown impact on CI).** `scripts/lint-all-repos.sh` is a
> `#!/bin/zsh` script. shellcheck cannot parse zsh and emits `SC1071` (error,
> exit 1) on it. The CI `lint-scripts` job runs
> `find scripts -name "*.sh" -exec shellcheck {} \;`, whose overall exit status
> is that of the *last* invocation; because the last `.sh` in iteration order is
> a clean bash script, the job currently exits 0 despite the zsh error. This is
> incidental, not guaranteed. (Not fixed here — this change is docs-only.)

## 6. CI/CD Performance

The repo's GitHub Actions workflow (`.github/workflows/ci.yml`) defines six jobs
(`lint-scripts`, `validate-yaml`, `validate-templates`, `validate-configs`,
`self-validate`, `test-template-rendering`) plus a `summary` gate.

> **Unmeasured (removed):** the previous per-job durations (`15s`, `10s`, `20s`,
> `45s` total, etc.) were illustrative and not measured from a real run. No CI
> run was available to time during this audit, so concrete per-job durations are
> intentionally omitted rather than invented. The job list above is verified
> against the workflow file.

## References

1. Shell scripting best practices: https://google.github.io/styleguide/shellguide.html
2. GitHub Actions caching: https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows

---

*Standardized with [chronoboiler](https://github.com/the-chronomancer/chronoboiler) v1.0.0*
