# SOLID Principles Code Review Checklist

This checklist ensures all PRs comply with SOLID principles before merge.

## PR Details

- PR Number: #
- Branch:
- Files Modified:

---

## Single Responsibility Principle (S)

### Class/Module Level

- [ ] Each class/module has ONE reason to change
- [ ] No class exceeds 200 lines of code (unless unavoidable)
- [ ] Methods accomplish single, clear purpose
- [ ] Data structures don't mix unrelated concerns

**Classes Modified:**

1. `ClassName`: Single responsibility statement
2. `ClassName`: Single responsibility statement

**Issues Found:**

- [ ] None
- [ ] Issue description

---

## Open/Closed Principle (O)

### Extensibility

- [ ] New features can be added WITHOUT modifying existing code
- [ ] Uses inheritance, composition, or polymorphism
- [ ] Doesn't require conditional logic for new variants

**Evidence of Extension Points:**

- Strategy pattern used at:
- Factory pattern used at:
- Interface-based design at:

**Modifications to Existing Code:**

- [ ] None (closed for modification)
- [ ] Unavoidable for: reason

---

## Liskov Substitution Principle (L)

### Subtype Compatibility

- [ ] All subtypes substitutable for base type
- [ ] Subclass respects superclass contract
- [ ] No surprising behavior in overrides
- [ ] Type-checking unnecessary

**Subclasses Modified:**

1. `Subclass` extends `Superclass`
   - [ ] Maintains contract
   - [ ] No precondition strengthening
   - [ ] No postcondition weakening

---

## Interface Segregation Principle (I)

### Interface Design

- [ ] Clients depend only on methods they use
- [ ] No "fat interfaces"
- [ ] Related methods grouped
- [ ] No forced empty implementations

**Interfaces Modified:**

1. `InterfaceName`
   - Methods:
   - Implementers:
   - All methods used by all implementers? [ ] Yes [ ] No

---

## Dependency Inversion Principle (D)

### Dependency Management

- [ ] High-level modules don't import low-level modules
- [ ] Both depend on abstractions
- [ ] Dependencies injected (not constructed)
- [ ] Easy to swap for testing

**Dependency Injections:**

1. `Class` depends on `Interface`
2. `Class` depends on `Interface`

**Direct Instantiations (anti-pattern):**

- [ ] None found
- [ ] Found at: location

---

## Summary

- [ ] All SOLID principles satisfied
- [ ] Code review approved
- [ ] Ready to merge

**Reviewer Comments:**

**PR Author Response:**

---

*Standardized with [chronoboiler](https://github.com/the-chronomancer/chronoboiler) v{{CHRONOBOILER_VERSION}}*
