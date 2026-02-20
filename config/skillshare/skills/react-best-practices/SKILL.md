---
name: react-best-practices
description: React performance optimization guidelines for client-side SPAs using Vite. This skill should be used when writing, reviewing, or refactoring React code to ensure optimal performance patterns. Triggers on tasks involving React components, data fetching, bundle optimization, or performance improvements.
---

# React Best Practices

## Overview

Comprehensive performance optimization guide for client-side React applications, containing 30+ rules across 7 categories. Rules are prioritized by impact to guide automated refactoring and code generation.

## When to Apply

Reference these guidelines when:
- Writing new React components
- Implementing client-side data fetching
- Reviewing code for performance issues
- Refactoring existing React code
- Optimizing bundle size or load times

## Priority-Ordered Guidelines

Rules are prioritized by impact:

| Priority | Category | Impact |
|----------|----------|--------|
| 1 | Eliminating Waterfalls | CRITICAL |
| 2 | Bundle Size Optimization | CRITICAL |
| 3 | Client-Side Data Fetching | MEDIUM-HIGH |
| 4 | Re-render Optimization | MEDIUM |
| 5 | Rendering Performance | MEDIUM |
| 6 | JavaScript Performance | LOW-MEDIUM |
| 7 | Advanced Patterns | LOW |

## Quick Reference

### Critical Patterns (Apply First)

**Eliminate Waterfalls:**
- Defer await until needed (move into branches)
- Use `Promise.all()` for independent async operations
- Start promises early, await late
- Use `better-all` for partial dependencies

**Reduce Bundle Size:**
- Avoid barrel file imports (import directly from source)
- Use `React.lazy()` for heavy components
- Preload based on user intent

### Medium-High Impact Client Patterns

- Use SWR/TanStack Query for automatic request deduplication
- Defer state reads to usage point
- Use lazy state initialization for expensive values
- Use derived state subscriptions
- Apply `startTransition` for non-urgent updates

### Rendering Patterns

- Animate SVG wrappers, not SVG elements directly
- Use `content-visibility: auto` for long lists
- Use explicit conditional rendering (`? :` not `&&`)

### JavaScript Patterns

- Batch DOM CSS changes via classes
- Build index maps for repeated lookups
- Cache repeated function calls
- Use `toSorted()` instead of `sort()` for immutability
- Early length check for array comparisons

## References

Full documentation with code examples is available in:

- `references/react-performance-guidelines.md` - Complete guide with all patterns
- `references/rules/` - Individual rule files organized by category

To look up a specific pattern, grep the rules directory:
```
grep -l "barrel" references/rules/
grep -l "swr" references/rules/
```

## Rule Categories in `references/rules/`

- `async-*` - Waterfall elimination patterns
- `bundle-*` - Bundle size optimization
- `client-*` - Client-side data fetching
- `rerender-*` - Re-render optimization
- `rendering-*` - DOM rendering performance
- `js-*` - JavaScript micro-optimizations
- `advanced-*` - Advanced patterns
