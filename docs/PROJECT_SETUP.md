# Project Setup

> Local development, testing, and deployment for Genixo Restoration.
>
> For standard Rails patterns (auth, Inertia, Solid Stack), see `~/.claude/rails-playbook/`.
> This doc covers only what's specific to this project.

---

## Prerequisites

- Ruby 3.3+
- PostgreSQL 16+
- Node.js 20+
- Heroku CLI (`brew tap heroku/brew && brew install heroku`)

---

## Local Development

### 1. Clone & Install

```bash
git clone <repo-url>
cd genixo-restoration

bundle install
npm install
```

### 2. Environment Variables

```bash
cp .env.example .env
```

Edit `.env` with your local values:

```bash
# App
APP_NAME="Genixo Restoration"
APP_HOST="localhost:3000"
APP_URL="http://localhost:3000"

# Rails
RAILS_ENV=development

# Email — letter_opener_web in dev, no external provider needed
# Emails open in browser at /letter_opener

# Notification provider (SMS/voice) — not needed for local dev
# NOTIFICATION_PROVIDER=twilio
# TWILIO_ACCOUNT_SID=xxx
# TWILIO_AUTH_TOKEN=xxx
# TWILIO_FROM_NUMBER=+1xxx

# File storage — local disk in dev, no config needed
# S3 config only needed in production (see Deployment section)
```

### 3. Database Setup

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### 4. Start Dev Server

```bash
bin/dev
```

This starts Puma (Rails) + Vite (frontend) via `Procfile.dev`. App runs at `http://localhost:3000`.

---

## Seed Data

`db/seeds.rb` creates a working development environment:

### Organizations

| Org | Type | Purpose |
|-----|------|---------|
| Genixo Construction | Mitigation | The service provider |
| Greystar Properties | Property Management | Client #1 |
| Sandalwood Management | Property Management | Client #2 (for testing PM isolation) |

### Users

All passwords: `password`

**Genixo Construction (Mitigation) — 14 users:**

| Email | Name | Role |
|-------|------|------|
| fhall@genixoconstruction.com | Fred Hall | manager (VP of Operations) |
| dhutson@genixoconstruction.com | Daniel Hutson | manager (Mitigation Director) |
| cmiller@genixoconstruction.com | Caleb Miller | manager (Construction PM) |
| jowen@genixoconstruction.com | Jeremy Owen | manager (VP of Operations) |
| jtucker@genixoconstruction.com | John Tucker | manager (Construction PM) |
| awagner@genixoconstruction.com | Anthony Wagner | manager (Construction Director) |
| gward@genixoconstruction.com | Gordon Ward | manager (Mitigation PM) |
| htello@genixoconstruction.com | Henry Tello | technician (Construction Supervisor) |
| zmeyer@genixoconstruction.com | Zachary Meyer | technician (Construction Supervisor) |
| cbutler@genixoconstruction.com | Chrystie Butler | office_sales (Office Staff) |
| enorthern@genixoconstruction.com | Emily Northern | office_sales (Office Manager) |
| mwoods@genixoconstruction.com | Melanie Woods | office_sales (Office Staff) |
| tkasbohm@genixoconstruction.com | Taylor Kasbohm | office_sales (Director of Estimating) |
| jsedita@genixoconstruction.com | Jessica Sedita | office_sales (Business Development) |

**Greystar Properties (PM) — 3 users:**

| Email | Name | Role |
|-------|------|------|
| jane@greystar.com | Jane Smith | property_manager (River Oaks) |
| tom@greystar.com | Tom Rodriguez | area_manager (River Oaks + Heights) |
| amy@greystar.com | Amy Chen | pm_manager (org-level) |

**Sandalwood Management (PM isolation test) — 1 user:**

| Email | Name | Role |
|-------|------|------|
| bob@sandalwood.com | Bob Johnson | property_manager (Sandalwood Apts) |

### Properties

| Property | PM Org | Mitigation Org |
|----------|--------|----------------|
| Park at River Oaks | Greystar | Genixo |
| Greystar Heights | Greystar | Genixo |
| Sandalwood Apartments | Sandalwood | Genixo |

### Property Assignments

- Jane Smith (jane@greystar.com) → Park at River Oaks
- Tom Rodriguez (tom@greystar.com) → Park at River Oaks, Greystar Heights
- Amy Chen (amy@greystar.com) → Park at River Oaks, Greystar Heights
- Bob Johnson (bob@sandalwood.com) → Sandalwood Apartments

### Sample Incidents

Seeds create 2-3 incidents at different statuses with messages, labor entries, equipment placements, and activity events — enough to exercise the dashboard groups and daily log views.

### Equipment Types (Genixo org)

- Dehumidifier
- Air Mover
- Air Blower
- Water Extraction Unit

### On-Call Configuration (Genixo org)

- Primary on-call: Fred Hall (fhall@genixoconstruction.com)
- Escalation timeout: 10 minutes
- Escalation contacts: Daniel Hutson (position 1), Anthony Wagner (position 2)

---

## Testing

> For testing principles and guidelines, see [TESTING.md](TESTING.md).

### Three-Layer Strategy

| Layer | Tool | Tests | Volume |
|-------|------|-------|--------|
| **Services + Models** | Minitest | Business logic, validations, scopes | Heavy |
| **Controllers** | Minitest + Inertia helpers | Authorization scoping, correct component/props per role | Heavy |
| **E2E (System)** | Capybara + Playwright | Critical happy paths in a real browser | Light |

### Commands

```bash
bin/rails test                    # All tests
bin/rails test test/models/       # Model tests only
bin/rails test test/services/     # Service tests only
bin/rails test test/controllers/  # Controller tests only
bin/rails test test/system/       # E2E browser tests only
```

### Principles

- **Test behavior, not implementation.** Assert what the user/system experiences, not internal method calls.
- **Every service gets tested.** Services hold all business logic — test valid paths, invalid paths, and edge cases.
- **Authorization at the controller layer.** Test that each role sees exactly what it should and nothing more. Use Inertia test helpers (`assert_inertia_component`, `assert_inertia_props`) to verify the right data reaches the right users.
- **E2E for real browser flows only.** Use system tests for things that require JavaScript rendering and multi-step user interaction. Don't duplicate what controller tests already cover.
- **Fixtures over factories.** Rails fixtures are fast and predictable. Create fixtures that exercise the multi-tenant model (multiple orgs, users of each type, cross-org isolation).
- **Stub external services.** Notification providers, email delivery, and any external APIs get stubbed in tests. Use a test notification provider or mock the dispatch layer.
- **All tests pass before every commit.** No exceptions.

### E2E Setup (Capybara + Playwright)

Uses `capybara-playwright-driver` — same Capybara DSL as standard Rails system tests, but Playwright instead of Selenium. Much more reliable with Inertia/React SPAs (no flaky Selenium timeouts).

```ruby
# Gemfile
gem "capybara-playwright-driver", group: :test

# test/application_system_test_case.rb
class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :playwright, using: :chromium, screen_size: [1400, 900]
end
```

---

## Background Jobs

Solid Queue runs in the same database (single-database setup per playbook).

### Queues

| Queue | Jobs | Priority |
|-------|------|----------|
| `urgent` | EscalationJob, EscalationTimeoutJob | Highest — emergency response |
| `default` | StatusChangeNotificationJob, MessageNotificationJob | Normal |
| `low` | DailyDigestJob | Background — runs once daily |

### Development

Jobs process inline in development by default. To test async processing:

```bash
# In a separate terminal
bin/rails solid_queue:start
```

### Recurring Jobs

```yaml
# config/solid_queue.yml
recurring:
  daily_digest:
    class: DailyDigestJob
    schedule: "every day at 6am"
    queue: low
```

---

## Deployment (Heroku)

### First-Time Setup

```bash
heroku create genixo-restoration
heroku addons:create heroku-postgresql:essential-0
heroku stack:set heroku-24
```

### Environment Variables

```bash
# App
heroku config:set APP_NAME="Genixo Restoration"
heroku config:set APP_HOST="genixo-restoration.herokuapp.com"
heroku config:set APP_URL="https://genixo-restoration.herokuapp.com"

# Rails
heroku config:set RAILS_ENV=production
heroku config:set RAILS_MASTER_KEY=$(cat config/master.key)
heroku config:set RAILS_SERVE_STATIC_FILES=true

# Email (Resend — swap provider by changing mailer config)
heroku config:set RESEND_API_KEY=re_XXX

# SMS/Voice notifications (provider TBD)
# heroku config:set NOTIFICATION_PROVIDER=twilio
# heroku config:set TWILIO_ACCOUNT_SID=xxx
# heroku config:set TWILIO_AUTH_TOKEN=xxx
# heroku config:set TWILIO_FROM_NUMBER=+1xxx

# File storage (S3)
heroku config:set AWS_ACCESS_KEY_ID=xxx
heroku config:set AWS_SECRET_ACCESS_KEY=xxx
heroku config:set AWS_REGION=us-east-1
heroku config:set AWS_S3_BUCKET=genixo-restoration-prod
```

### Procfile

```procfile
web: bundle exec puma -C config/puma.rb
worker: bundle exec bin/jobs --mode=async
release: bundle exec rails db:migrate
```

Solid Queue's `async` mode (v1.3.0+) runs the supervisor with reduced memory (~260MB vs ~512MB on Heroku).

### Deploy

```bash
git push heroku main
```

### Post-Deploy

```bash
# Seed initial data (first deploy only)
heroku run rails db:seed

# Scale worker for background jobs
heroku ps:scale worker=1

# Verify
heroku logs --tail
heroku run rails console
```

---

## Key Differences from Playbook

Things that are **not** in this project (skip these playbook sections):

- **No Stripe/payments** — not a SaaS product
- **No OAuth** — email/password only
- **No ActionCable** — deferred post-MVP (Solid Cable tables still created for later)
- **No analytics/SEO** — internal tool, not public-facing

Things that are **added** beyond the playbook:

- **Notification providers** — SMS/voice for escalation (Twilio or similar)
- **On-call configuration** — seeded per mitigation org
- **Multi-tenant scoping** — org-based data isolation (not standard SaaS tenancy)
- **Active Storage for attachments** — polymorphic across incidents and messages
