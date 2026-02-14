# Testing Guidelines

> Principles for writing excellent tests. Referenced during development — read this before writing your first test, revisit when something feels wrong.

---

## Testing Layers

| Layer | Tool | Purpose | Volume |
|-------|------|---------|--------|
| **Services + Models** | Minitest | Business logic, validations, scopes | Heavy |
| **Controllers** | Minitest + Inertia helpers | Authorization scoping, correct component/props per role | Heavy |
| **E2E (System)** | Capybara + Playwright | Critical happy paths in a real browser | Light |

**Test at the lowest possible layer.** If you can verify it in a service test, don't write a controller test. If you can verify it in a controller test, don't write a browser test. Higher layers are slower, flakier, and harder to debug.

---

## Principles

### Test the contract, not the implementation

Assert what happens (output, side effects, state changes), not how it happens internally. Tests that verify method calls or internal ordering break on every refactor and provide zero confidence.

### Name tests like sentences

`test "deactivated user cannot log in"` not `test_auth_edge_case_4`. Someone should be able to read test names alone and understand every behavior the system supports.

### Every bug gets a regression test

Before you fix a bug, write a test that reproduces it. Watch it fail. Fix the code. Watch it pass. This is the single highest-ROI testing practice — it guarantees the same bug never ships twice.

### Don't test the framework

Rails already tests that `validates :name, presence: true` works. Test your business rules — the things that are unique to your domain and would break if someone changed them.

### Cover the sad paths

Happy paths are obvious and rarely where bugs live. The real value is in: invalid inputs, unauthorized access, state transitions that shouldn't be allowed, empty collections, nil values, and race conditions.

### Tests are documentation

A new developer should be able to read your test file and understand what the feature does, what the edge cases are, and what's not allowed — without reading the implementation.

### Arrange-Act-Assert, always

Setup the world, do the thing, check the result. One concept per test. If a test fails, you should know exactly what broke from the test name alone.

### Flaky tests are worse than no tests

A test that passes 95% of the time erodes trust in the entire suite. People stop running tests. Fix flaky tests immediately or delete them. Never skip them.

---

## Multi-Tenant Testing

### Always test isolation

Every query that touches scoped data should have a test proving org A cannot see org B's data. This is a security test, not a feature test — treat it accordingly.

### Fixtures should represent the tenant model

Create fixtures that exercise the full hierarchy: multiple orgs, users of each type in each org, properties across different PM orgs, incidents at various statuses. The fixture set should make cross-tenant bugs impossible to miss.

---

## State Machine Testing

### Test the matrix

Test every valid transition works. Test every invalid transition raises. This is one place where exhaustive testing pays for itself — status bugs are expensive and hard to catch in production.

### Test side effects of transitions

A status change doesn't just update a column. It creates activity events, sends notifications, resolves escalations. Test that the full chain fires correctly for each transition.

---

## Authorization Testing

### Test at the controller boundary

Use Inertia test helpers (`assert_inertia_component`, `assert_inertia_props`) to verify each role receives exactly the right component with exactly the right data. Authorization failures should return 404 (not 403) — test for that.

### Test every role

With six user types across two org types, the permission matrix is complex. Each controller action should have tests for: roles that can access it, roles that can't, and roles that can access it but with scoped-down data.

---

## Mocking & Stubbing

### Mock your interfaces, not third-party code

Stub `NotificationDispatchService`, not `Twilio::Client`. If you mock what you don't own, your tests pass while production breaks.

### Prefer real objects when possible

Only stub external services (notification providers, email delivery) and slow dependencies. Let models, services, and database interactions run for real — that's the whole point of the test.

---

## E2E / System Tests

### Playwright over Selenium

We use `capybara-playwright-driver` — same Capybara DSL, but Playwright under the hood. Dramatically more reliable with Inertia/React SPAs.

### Keep E2E tests focused

Each system test should cover one complete user flow (login, do the thing, verify the result). Don't chain multiple features into mega-tests — when they fail, you can't tell what broke.

### E2E is for JavaScript-dependent flows

If a behavior can be verified without rendering React components, test it at the controller layer instead. Reserve browser tests for multi-step interactions that require real JS execution.
