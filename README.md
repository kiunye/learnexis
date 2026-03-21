# LearnExis - School Management System

A comprehensive Ruby on Rails 8.0+ School Management System leveraging Hotwire (Turbo + Stimulus) for real-time interactivity, Tailwind CSS v4 with DaisyUI components for modern styling, and Rails' built-in authentication for secure access control.

## Prerequisites

- **Ruby**: 3.3.0 or higher (managed via mise)
- **Bun**: Latest version for JavaScript bundling
- **Node.js**: Required for Tailwind CSS and DaisyUI
- **SQLite3**: For development and test databases
- **PostgreSQL**: For production (optional, can use SQLite in dev/test)

## Local Setup

### 1. Clone the repository

```bash
git clone <repository-url>
cd learnexis
```

### 2. Install Ruby dependencies

```bash
bundle install
```

### 3. Install JavaScript dependencies

```bash
bun install
```

### 4. Set up the database

**Development/Test (SQLite):**
```bash
# Create and migrate databases
bin/rails db:create
bin/rails db:migrate

# (Optional) Load seed data for development
bin/rails db:seed
```

**Production (PostgreSQL):**

The application uses PostgreSQL in production. Configure your database connection using environment variables:

**Option 1: Use DATABASE_URL (recommended)**
```bash
export DATABASE_URL=postgresql://username:password@hostname:port/database_name
```

**Option 2: Use individual connection parameters**
```bash
export DB_HOST=localhost
export DB_PORT=5432
export DB_USER=postgres
export DB_PASSWORD=your_password
export DB_NAME=learnexis_production
```

See the "Environment Configuration" section below for a complete list of environment variables.

**Note:** Make sure the `pg` gem is installed for PostgreSQL support:
```bash
bundle install
```

### 5. Start the development server

```bash
# This starts Rails server, CSS watcher, and other services
bin/dev
```

The application will be available at `http://localhost:3000`

## Development Workflow

### Running Tests

```bash
# Run all RSpec tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/user_spec.rb

# Run tests with coverage
COVERAGE=true bundle exec rspec
```

### Code Quality Tools

```bash
# Run Rubocop (code style checker)
bin/rubocop

# Run Brakeman (security scanner)
bin/brakeman

# Run bundler-audit (dependency vulnerability scanner)
bin/bundler-audit
```

### Database Management

**Development/Test:**
```bash
# Create a new migration
bin/rails generate migration MigrationName

# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Reset database (WARNING: deletes all data)
bin/rails db:reset

# Prepare test database
bin/rails db:test:prepare
```

**Production:**
```bash
# Run migrations in production
RAILS_ENV=production bin/rails db:migrate

# Or if using environment variables
bin/rails db:migrate RAILS_ENV=production
```

**Database Strategy:**
- **Development/Test**: Uses SQLite3 (lightweight, no setup required)
- **Production**: Uses PostgreSQL (configured via environment variables)

## Technology Stack

- **Backend**: Ruby on Rails 8.1.2
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS v4, DaisyUI
- **Authentication**: Rails Authentication Generator (built-in)
- **Authorization**: Pundit
- **Pagination**: Pagy
- **Testing**: RSpec, FactoryBot, Faker
- **Database**: SQLite3 (dev/test), PostgreSQL (production)
- **Background Jobs**: Solid Queue (Rails 8 default)
- **Caching**: Solid Cache (Rails 8 default)
- **Real-time**: Action Cable with Turbo Streams
- **File Storage**: Active Storage

## Project Structure

```
app/
├── controllers/         # RESTful controllers
├── models/             # ActiveRecord models
├── views/              # ERB templates with Turbo Frames/Streams
├── services/           # Business logic service objects
├── policies/           # Pundit authorization policies
├── jobs/              # Background jobs (Solid Queue)
├── javascript/
│   └── controllers/   # Stimulus controllers
└── assets/
    └── tailwind/      # Tailwind CSS v4 + DaisyUI configuration
```

## Key Gems

- **pundit**: Authorization
- **pagy**: Pagination
- **rspec-rails**: Testing framework
- **factory_bot_rails**: Test data factories
- **faker**: Fake data generation
- **rubocop-rails-omakase**: Code style enforcement
- **brakeman**: Security scanning
- **bundler-audit**: Dependency vulnerability scanning
- **flipper** / **flipper-active_record**: Feature flags for SMS and M-Pesa in production

## Environment Configuration

### Development

Uses SQLite3 for database. No additional configuration needed.

### Production

Create a `.env` file (or set environment variables) with the following:

**Required Variables:**
```bash
# Database Configuration
# Option 1: Use DATABASE_URL (recommended)
DATABASE_URL=postgresql://username:password@hostname:port/database_name

# Option 2: Use individual parameters
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=learnexis_production

# Rails Configuration
RAILS_ENV=production
RAILS_MASTER_KEY=your_master_key_here
SECRET_KEY_BASE=your_secret_key_base_here
RAILS_MAX_THREADS=5
```

**Optional Variables (for Solid Cache, Queue, Cable):**
```bash
# Separate databases for Solid Stack components (optional)
DB_CACHE_NAME=learnexis_production_cache
DB_QUEUE_NAME=learnexis_production_queue
DB_CABLE_NAME=learnexis_production_cable

# Or use separate URLs
DATABASE_CACHE_URL=postgresql://username:password@hostname:port/cache_db
DATABASE_QUEUE_URL=postgresql://username:password@hostname:port/queue_db
DATABASE_CABLE_URL=postgresql://username:password@hostname:port/cable_db
```

**Future Integration Variables (when implemented):**
- SMS (Africastalking): `AFRICASTALKING_API_KEY`, `AFRICASTALKING_USERNAME`
- M-Pesa: `MPESA_CONSUMER_KEY`, `MPESA_CONSUMER_SECRET`, `MPESA_SHORTCODE`, `MPESA_PASSKEY`
- Active Storage (S3): `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`, `AWS_S3_BUCKET`
- Email (SMTP): `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`

### Integrations, feature flags, and kill switches

SMS (`SmsService`, `AttendanceNotificationJob`) and M-Pesa (`MpesaPaymentService`, `TransactionsController` webhook) are gated by `Integrations` (`app/services/integrations.rb`):

| Environment | Default |
|-------------|---------|
| **development** / **test** | Integrations are **on** unless `FORCE_DISABLE_SMS` or `FORCE_DISABLE_MPESA` is truthy (`1`, `true`, `yes`, `on`). |
| **production** (and other non-local envs) | Requires `ENABLE_SMS=true` **and** `Flipper.enable(:sms)` for SMS; `ENABLE_MPESA=true` **and** `Flipper.enable(:mpesa)` for M-Pesa. |

**Flipper** uses the Active Record adapter in development/production (tables `flipper_features` / `flipper_gates` after `bin/rails db:migrate`). In tests, an in-memory adapter is used.

```bash
bin/rails runner 'Flipper.enable(:sms); Flipper.enable(:mpesa)'
# or disable
bin/rails runner 'Flipper.disable(:sms)'
```

**M-Pesa webhook hardening**

- `POST /transactions/mpesa_callback` is **unauthenticated** (provider callback). CSRF is skipped for this action only.
- If `MPESA_WEBHOOK_SECRET` is set, the request must include header `X-Learnexis-Mpesa-Signature` with `OpenSSL::HMAC.hexdigest("SHA256", secret, raw_post_body)` (hex).
- Successful payments are deduplicated for 72 hours using `Rails.cache` and a key derived from receipt / checkout / transaction id (`MpesaPaymentService.callback_idempotency_key`).

**Staff-only status check:** `GET /transactions/verify_mpesa` requires a signed-in admin or teacher and `Integrations.mpesa_enabled?`.

See `.env.example` for variable names.

### Deployment checklist (Kamal / production)

1. Set `RAILS_MASTER_KEY`, database URLs, `SECRET_KEY_BASE`, and host/SSL as for any Rails 8 app.
2. Run migrations (includes Flipper tables).
3. Enable integrations: `ENABLE_SMS` / `ENABLE_MPESA` and run `Flipper.enable` for `:sms` / `:mpesa` as needed.
4. Set `MPESA_WEBHOOK_SECRET` and configure your M-Pesa provider to send the matching `X-Learnexis-Mpesa-Signature` (or leave unset only behind a trusted network — not recommended on the public internet).
5. Use PostgreSQL in production; update `config/deploy.yml` server IPs, registry, and uncomment **job** / **accessories** if you split Solid Queue or run a managed database.
6. Run security checks before release: `bin/brakeman` and `bin/bundler-audit`.

**Important:** Never commit `.env` files to version control. Use your deployment platform's environment variable configuration instead.

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests: `bundle exec rspec`
4. Run code quality checks: `bin/rubocop && bin/brakeman`
5. Submit a pull request

## License

[Add your license here]
