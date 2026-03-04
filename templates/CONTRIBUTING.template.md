# Contributing to {{PROJECT_NAME}}

Thank you for your interest in contributing! This document outlines the process and requirements for contributing to {{PROJECT_NAME}}.

## Code Review Process

All PRs must satisfy the SOLID principles checklist and pass automated checks before merge.

### SOLID Principles Checklist

#### Single Responsibility Principle (S)

- [ ] Each class has ONE reason to change
- [ ] Methods accomplish ONE logical task
- [ ] No mixing of unrelated concerns
- [ ] Change in one concern doesn't affect others

**Evidence Required:** List the single responsibility for each class modified.

#### Open/Closed Principle (O)

- [ ] Code is open for extension (new subtypes/implementations)
- [ ] Code is closed for modification (existing code unchanged)
- [ ] Extensibility via inheritance, composition, or polymorphism
- [ ] New features don't require modifying existing classes

**Evidence Required:** Show how a new feature adds WITHOUT modifying existing code.

#### Liskov Substitution Principle (L)

- [ ] All subtypes are substitutable for base type
- [ ] Subclass respects superclass contract
- [ ] No surprising behavior in subclass overrides
- [ ] Type-checking code is unnecessary

**Evidence Required:** Demonstrate subtype compatibility with base type.

#### Interface Segregation Principle (I)

- [ ] Clients depend only on methods they use
- [ ] No "fat interfaces" forcing unused implementations
- [ ] Interfaces are cohesive (related methods grouped)
- [ ] Classes don't implement unnecessary methods

**Evidence Required:** Show minimal, focused interfaces.

#### Dependency Inversion Principle (D)

- [ ] High-level modules don't import low-level modules
- [ ] Both depend on abstractions (interfaces/abstract classes)
- [ ] Dependencies are injected, not constructed internally
- [ ] Easy to swap implementations for testing

**Evidence Required:** Show dependency injection and abstraction layer.

## Testing Requirements

Every PR must include appropriate tests.

### Unit Tests

```{{LANGUAGE}}
{{UNIT_TEST_EXAMPLE}}
```

**Minimum Coverage:** {{COVERAGE_THRESHOLD}}% code coverage for modified files.

### Integration Tests

```{{LANGUAGE}}
{{INTEGRATION_TEST_EXAMPLE}}
```

### Performance Tests

```{{LANGUAGE}}
{{PERFORMANCE_TEST_EXAMPLE}}
```

**Command to Run:**

```bash
{{TEST_COMMAND}}
```

## Complexity Analysis Documentation

For any algorithm contribution:

1. **State the complexity:** Big-O notation (e.g., O(n log n))
2. **Justify it:** Explain the reasoning
3. **Prove correctness:** Match empirical benchmarks
4. **Document trade-offs:** Space, readability, maintenance

See [PERFORMANCE.md](./PERFORMANCE.md) for template.

## Submission Process

1. Fork repo
2. Create feature branch: `git checkout -b feature/{{FEATURE_NAME}}`
3. Implement with tests
4. Run full test suite: `{{TEST_COMMAND}}`
5. Verify SOLID: Complete checklist above
6. Check performance: `{{BENCH_COMMAND}}`
7. Push and open PR
8. All checks must pass before merge

## Performance Regression Testing

CI/CD automatically enforces benchmark validation.

**Local Testing:**

```bash
{{BENCH_COMMAND}}
```

**Threshold:** No regression > {{REGRESSION_THRESHOLD}}%

**What happens if benchmark fails:**

1. Reviewer requests optimization
2. Author improves algorithm or justifies the regression
3. Re-run benchmark to verify fix

## Commit Message Format

Use conventional commits:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting (no code change)
- `refactor`: Code restructuring (no behavior change)
- `perf`: Performance improvement
- `test`: Adding/updating tests
- `chore`: Maintenance tasks

## Questions?

- See [ARCHITECTURE.md](./ARCHITECTURE.md) for system design
- See [PERFORMANCE.md](./PERFORMANCE.md) for complexity analysis
- Open an issue for clarification

---

*Standardized with [chronoboiler](https://github.com/the-chronomancer/chronoboiler) v{{CHRONOBOILER_VERSION}}*
