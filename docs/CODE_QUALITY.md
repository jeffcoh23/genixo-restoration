# Code Quality Guidelines

> Rules for writing clean, maintainable Rails code. General principles — not project-specific.

---

## Controllers

- **Three jobs only:** authorize, call a service, render. If you're writing business logic in a controller, it belongs somewhere else.
- **Never trust URL params for data access.** Always scope queries through authorization helpers. If a user shouldn't see a record, the query shouldn't return it — don't check after the fact.
- **Return 404 for unauthorized access, not 403.** Don't reveal that a record exists to someone who can't see it.
- **Strong params, always.** Whitelist every attribute explicitly. Never `.permit!`.

---

## Services

- **All business logic lives in services.** Controllers are thin. Models are thin. Services are where the real work happens.
- **One service, one purpose, one public method.** If it does two unrelated things, split it.
- **Wrap multi-write operations in transactions.** If step 3 fails, steps 1 and 2 roll back.
- **Raise on failure, don't return booleans.** Meaningful exceptions give the caller context. `true/false` is ambiguous.
- **Services can call other services.** Models should never call services. Keep the dependency arrow one-directional: Controller → Service → Model.

---

## Models

- **Validations enforce data shape** — presence, format, uniqueness, inclusion. Business rules (who can do what, when) belong in services.
- **Scopes for reusable queries.** If a `where` clause appears in more than one place, make it a scope. Named scopes make code readable.
- **Minimize callbacks.** Normalizing data in `before_validation` is fine. Triggering jobs, sending emails, or modifying other records in `after_create` is not — that belongs in a service where it's explicit and testable.
- **Associations tell the domain story.** Read the model file and you should understand the relationships. Use descriptive foreign key names over generic ones.

---

## Database

- **Index every foreign key.** No exceptions. Also index columns you query or sort by frequently.
- **Database constraints are the last line of defense.** `NOT NULL`, unique indexes, CHECK constraints, and foreign keys catch bugs that validations miss. Code can have bugs. Constraints can't be bypassed. Use both.
- **Migrations are append-only.** Never edit a migration that's been run. Need to change something? Write a new migration.
- **Back every association with a real foreign key.** This prevents orphaned records and makes the schema self-documenting.

---

## Authorization

- **Think in scopes, not permissions.** Don't ask "can this user do this action?" — narrow the query to only return records the user can see, then operate on the result. If the record isn't in the scope, it doesn't exist to that user.
- **In multi-tenant systems, test isolation relentlessly.** The scariest bug is tenant A seeing tenant B's data. Every endpoint that returns data should have a test proving this can't happen.
- **Never check `user_type` directly in controllers or services for permission gating.** Use `current_user.can?(Permissions::X)` via the `Authorization` concern. For new features: add a constant to `Permissions`, add it to the correct roles in `ROLE_PERMISSIONS`, add a `can_x?` helper to the `Authorization` concern.
- **Type-check helpers live on the User model.** Use `current_user.technician?`, `current_user.manager?`, etc. — never define private `technician?` or similar methods in controllers.
- **Use constants for domain strings.** User types (`User::MANAGER`), statuses, project types — anything referenced in more than one place should be a constant on the model, not a string literal.

---

## Frontend

> **The frontend is a dumb display layer.** All logic — authorization, data formatting, label resolution, filtering, sorting, pluralization — lives on the Rails server. React components receive display-ready props and render them. If a component needs to think, the server should have thought for it.

- **Pages are thin.** A page component receives props and renders. Over 100 lines? Extract sub-components. Complex state? Extract a hook.
- **Let the server do the work.** With Inertia, you're not building a traditional SPA. The frontend just presents what the server sends. No data transformation, no label lookups, no string formatting, no pluralization, no truncation. If you find yourself writing `===` checks or `.length > 0` conditionals to transform data, that logic belongs on the server.
- **Server sends display-ready data.** Every prop the frontend receives should be ready to render directly. Send `role_label: "Office/Sales"` not `user_type: "office_sales"`. Send `address: "123 Main St, Denver, CO"` not raw fields. Send `summary: "Flood — Kitchen damage..."` not raw description + damage_type for the client to assemble.
- **Constants live on the server.** Role labels, status labels, damage type labels — all defined as model constants (e.g., `User::ROLE_LABELS`, `Incident::STATUS_LABELS`) and shared via `inertia_share` with `InertiaRails.once`. The frontend never duplicates these mappings.
- **Nav items come from the server.** The server determines which navigation items to show based on the user's role and sends them via `inertia_share`. The sidebar just renders what it receives.
- **Never hardcode routes.** Use shared route props. If a route changes, it changes in one place.
- **Use reusable components.** `DataTable`, `PageHeader`, `DetailList`, `FormField`, `AddressFields`, `StatusBadge` exist for common patterns. Use them instead of writing raw HTML tables, headers, or form fields. Domain-specific UI that these don't cover should become new shared components.
- **Use the component library.** shadcn/ui for `Button`, `Input`, `Label`, `Card`, `Alert`, `Badge`. Custom components should only exist for domain-specific UI that the library doesn't cover.
- **Design tokens, not hardcoded values.** Use semantic color/spacing tokens, never raw color codes or pixel values. Tokens make theming possible and keep UI consistent.

---

## Error Handling

- **Raise meaningful exceptions.** Domain-specific exception classes tell you exactly what went wrong without reading a stack trace.
- **Don't rescue broadly.** `rescue => e` catches everything including typos and nil errors. Rescue specific exceptions you expect and can handle. Let unexpected errors bubble up.
- **Trust the framework.** If a record isn't found, Rails renders 404 automatically. Don't catch exceptions just to manually replicate what the framework already does.

---

## Performance

- **Prevent N+1 queries.** Use `includes` or `preload` when you know the view will access associations. Catch these in development before they hit production.
- **Denormalize sparingly but intentionally.** If a computed value is expensive to derive and queried often, denormalize it. Document why it exists and ensure it stays in sync through a single code path.
- **Paginate all list endpoints.** No endpoint should return unbounded results. Even if there are only 20 records today, there won't be 20 forever.

---

## General Principles

- **Naming matters more than comments.** Spend time on names. A well-named method eliminates the need for documentation. If you need a comment to explain what code does, rename the code.
- **Methods should do one thing.** If you're describing a method with "and" — it does too much.
- **Prefer explicit over clever.** Metaprogramming, dynamic method definitions, and dense one-liners are clever. They're also hard to debug, hard to search for, and hard for the next person to understand. Write boring code.
- **Delete dead code.** Don't comment it out. Don't leave it "in case we need it later." Git has history. Dead code confuses readers and decays as surrounding code evolves.
- **Small methods, small classes, small commits.** If a method is over 15 lines, it probably does too much. If a class is over 200 lines, it has too many responsibilities.
- **Consistency over personal preference.** Follow the patterns already established in the codebase. Match the existing style, even if you'd prefer something different.
