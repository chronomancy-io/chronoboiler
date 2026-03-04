# Performance Analysis: {{PROJECT_NAME}}

## 1. Complexity Classification

**Claim:** {{PROJECT_NAME}} achieves **O({{COMPLEXITY}})** time complexity for {{PRIMARY_OPERATION}}.

**Proof by Component:**

| Component | Operation | Complexity | Justification |
|-----------|-----------|------------|---------------|
| {{COMPONENT_1}} | {{OPERATION_1}} | O({{COMPLEXITY_1}}) | {{JUSTIFICATION_1}} |
| {{COMPONENT_2}} | {{OPERATION_2}} | O({{COMPLEXITY_2}}) | {{JUSTIFICATION_2}} |
| {{COMPONENT_3}} | {{OPERATION_3}} | O({{COMPLEXITY_3}}) | {{JUSTIFICATION_3}} |
| **Total** | **{{PRIMARY_OPERATION}}** | **O({{COMPLEXITY}})** | {{COMPLEXITY_SUMMARY}} |

### Derivation

For each step of the algorithm:

1. **Step 1:** O({{STEP_1_COMPLEXITY}}) because {{STEP_1_EXPLANATION}}
2. **Step 2:** O({{STEP_2_COMPLEXITY}}) because {{STEP_2_EXPLANATION}}
3. **Step 3:** O({{STEP_3_COMPLEXITY}}) because {{STEP_3_EXPLANATION}}

Combining: O({{STEP_1_COMPLEXITY}}) + O({{STEP_2_COMPLEXITY}}) + O({{STEP_3_COMPLEXITY}}) = **O({{COMPLEXITY}})**

## 2. Benchmarking Methodology

### Test Configuration

- **Hardware:** {{BENCHMARK_HARDWARE}}
- **OS:** {{BENCHMARK_OS}}
- **Runtime:** {{BENCHMARK_RUNTIME}}
- **Iterations:** {{BENCHMARK_ITERATIONS}}

### Benchmark Harness

```{{LANGUAGE}}
{{BENCHMARK_CODE}}
```

### Observed Results

| Scale | Observed (ms) | Predicted O({{COMPLEXITY}}) | Ratio | Pass? |
|-------|---------------|----------------------------|-------|-------|
| {{SCALE_1}} | {{OBSERVED_1}} | {{PREDICTED_1}} | {{RATIO_1}}x | {{PASS_1}} |
| {{SCALE_2}} | {{OBSERVED_2}} | {{PREDICTED_2}} | {{RATIO_2}}x | {{PASS_2}} |
| {{SCALE_3}} | {{OBSERVED_3}} | {{PREDICTED_3}} | {{RATIO_3}}x | {{PASS_3}} |
| {{SCALE_4}} | {{OBSERVED_4}} | {{PREDICTED_4}} | {{RATIO_4}}x | {{PASS_4}} |

**Conclusion:** Observed results match predicted O({{COMPLEXITY}}) within ±{{MARGIN}}% margin.

## 3. Optimization Techniques

### Technique 1: {{OPTIMIZATION_1_NAME}}

**Impact:** {{OPTIMIZATION_1_SPEEDUP}} speedup
**Before:**

```{{LANGUAGE}}
{{OPTIMIZATION_1_BEFORE}}
```

**After:**

```{{LANGUAGE}}
{{OPTIMIZATION_1_AFTER}}
```

**Trade-Off:** {{OPTIMIZATION_1_TRADEOFF}}

<!-- Add more optimization techniques as needed -->

### Technique 2: {{OPTIMIZATION_2_NAME}}

**Impact:** {{OPTIMIZATION_2_SPEEDUP}} speedup
**Before:**

```{{LANGUAGE}}
{{OPTIMIZATION_2_BEFORE}}
```

**After:**

```{{LANGUAGE}}
{{OPTIMIZATION_2_AFTER}}
```

**Trade-Off:** {{OPTIMIZATION_2_TRADEOFF}}

## 4. Memory Profile

| Allocation | Per-Unit Size | Total @ {{SCALE_SMALL}} | Total @ {{SCALE_LARGE}} |
|------------|---------------|------------------------|------------------------|
| {{ALLOCATION_1}} | {{SIZE_1}} | {{TOTAL_1_SMALL}} | {{TOTAL_1_LARGE}} |
| {{ALLOCATION_2}} | {{SIZE_2}} | {{TOTAL_2_SMALL}} | {{TOTAL_2_LARGE}} |
| {{ALLOCATION_3}} | {{SIZE_3}} | {{TOTAL_3_SMALL}} | {{TOTAL_3_LARGE}} |
| **Total** | | {{TOTAL_SMALL}} | {{TOTAL_LARGE}} |

## 5. Regression Testing

**Policy:** Every commit runs automated benchmarks.

**Threshold:** PR is blocked if performance regresses > {{REGRESSION_THRESHOLD}}%.

### CI Command

```bash
{{BENCH_CI_COMMAND}}
```

### Local Testing

```bash
{{BENCH_LOCAL_COMMAND}}
```

Expected output:

```
{{BENCH_EXPECTED_OUTPUT}}
```

## References

<!-- OPTIONAL: Add academic or technical references -->

1. {{REFERENCE_1}}
2. {{REFERENCE_2}}

---

*Standardized with [chronoboiler](https://github.com/the-chronomancer/chronoboiler) v{{CHRONOBOILER_VERSION}}*
