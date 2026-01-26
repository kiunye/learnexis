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

```bash
# Create and migrate databases
bin/rails db:create
bin/rails db:migrate

# (Optional) Load seed data for development
bin/rails db:seed
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

```bash
# Create a new migration
bin/rails generate migration MigrationName

# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Reset database (WARNING: deletes all data)
bin/rails db:reset
```

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

## Environment Configuration

### Development

Uses SQLite3 for database. No additional configuration needed.

### Production

Set the following environment variables:

- `DATABASE_URL`: PostgreSQL connection string
- `RAILS_MASTER_KEY`: Rails encrypted credentials key
- `SECRET_KEY_BASE`: Rails secret key base

See `.env.example` for a template of production environment variables.

## Contributing

1. Create a feature branch
2. Make your changes
3. Run tests: `bundle exec rspec`
4. Run code quality checks: `bin/rubocop && bin/brakeman`
5. Submit a pull request

## License

[Add your license here]
