# Loopin - Habit Tracking Ruby on Rails Application

Loopin is a Ruby on Rails 7.1.5.2 habit tracking application that helps users form and maintain habits through visualization, achievements, and social features. The application uses PostgreSQL as the database, Hotwire/Turbo for the frontend, and Docker for containerization.

**ALWAYS reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Working Effectively

### Environment Setup
- **Ruby Version**: The application requires Ruby 3.3.1, but can work with Ruby 3.2.3 with minor Gemfile modifications
- **Node.js Version**: Node.js 22.17.1 (see `.node-version` file)
- **PostgreSQL**: Uses PostgreSQL 15 via Docker container
- **Package Managers**: Bundler for Ruby gems, Yarn for JavaScript packages

### Bootstrap and Development Setup

**CRITICAL**: All build and test commands can take significant time. NEVER CANCEL long-running operations.

1. **Install Dependencies (NEVER CANCEL - Takes 3-5 minutes):**
   ```bash
   # Install system dependencies
   sudo apt-get update && sudo apt-get install -y libpq-dev postgresql-client

   # Install Ruby gems (NEVER CANCEL - Takes 30-60 seconds, timeout: 5+ minutes)
   gem install bundler --user-install
   export PATH="/home/runner/.local/share/gem/ruby/3.2.0/bin:$PATH"
   bundle config set --local path 'vendor/bundle'
   bundle install

   # Install JavaScript dependencies (Takes 30 seconds)
   npm install -g yarn
   yarn install
   ```

2. **Start Database Container:**
   ```bash
   docker compose up -d db
   # Database runs on port 15432 (not default 5432)
   ```

3. **Setup Database (Takes 1-2 seconds each):**
   ```bash
   export DB_HOST=localhost
   export DB_PORT=15432
   export POSTGRES_PASSWORD=password
   PGPORT=15432 PGHOST=localhost bundle exec rails db:create
   PGPORT=15432 PGHOST=localhost bundle exec rails db:migrate
   ```

4. **Build JavaScript Assets (Takes 1 second):**
   ```bash
   yarn build
   ```

### Running the Application

**Development Server with Live Reload:**
```bash
# Install foreman if needed
gem install foreman --user-install

# Start both Rails server and JavaScript watcher (NEVER CANCEL)
export PATH="/home/runner/.local/share/gem/ruby/3.2.0/bin:$PATH"
export DB_HOST=localhost
export POSTGRES_PASSWORD=password
export PGPORT=15432 PGHOST=localhost
./bin/dev
```

**Rails Server Only:**
```bash
export PATH="/home/runner/.local/share/gem/ruby/3.2.0/bin:$PATH"
export DB_HOST=localhost
export POSTGRES_PASSWORD=password
export PGPORT=15432 PGHOST=localhost
bundle exec rails server -p 3000
```

The application will be available at http://localhost:3000

### Testing and Quality Assurance

**Run Tests (NEVER CANCEL - Takes 3-5 seconds, includes asset compilation):**
```bash
export PATH="/home/runner/.local/share/gem/ruby/3.2.0/bin:$PATH"
export DB_HOST=localhost
export POSTGRES_PASSWORD=password
export PGPORT=15432 PGHOST=localhost
bundle exec rails test
# Test suite currently has 0 tests but runs successfully
```

**Run Linter (Takes 1-2 seconds):**
```bash
export PATH="/home/runner/.local/share/gem/ruby/3.2.0/bin:$PATH"
bundle exec rubocop
# Expect 158 style offenses, 148 are auto-correctable
```

**Auto-fix Linting Issues:**
```bash
bundle exec rubocop -a
```

## Validation Scenarios

**CRITICAL**: Always validate functionality after making changes by running through these scenarios:

1. **Application Startup Validation:**
   - Run `./bin/dev` and ensure both web and js processes start without errors
   - Access http://localhost:3000 and verify the Rails welcome page loads
   - Check that the response returns HTTP 200 status

2. **Database Connectivity Validation:**
   - Run `bundle exec rails db:migrate` to ensure database connection works
   - Verify PostgreSQL container is running on port 15432

3. **Asset Pipeline Validation:**
   - Run `yarn build` and verify JavaScript assets compile successfully
   - Check that `app/assets/builds/application.js` is generated

## Common Development Tasks

### Working with Ruby Gems
- **Add a new gem**: Edit `Gemfile`, then run `bundle install`
- **Update gems**: Run `bundle update`
- **Check gem dependencies**: Run `bundle check`

### Working with JavaScript
- **Add new JavaScript dependencies**: `yarn add package-name`
- **Build assets manually**: `yarn build`
- **Watch for changes**: Use `./bin/dev` (preferred) or `yarn build --watch`

### Database Operations
- **Create database**: `PGPORT=15432 PGHOST=localhost bundle exec rails db:create`
- **Run migrations**: `PGPORT=15432 PGHOST=localhost bundle exec rails db:migrate`
- **Rollback migration**: `PGPORT=15432 PGHOST=localhost bundle exec rails db:rollback`
- **Reset database**: `PGPORT=15432 PGHOST=localhost bundle exec rails db:reset`

### Code Quality
- **Always run linting before committing**: `bundle exec rubocop`
- **Auto-fix style issues**: `bundle exec rubocop -a`
- **Run tests**: `bundle exec rails test`

## Important File Locations

### Configuration Files
- `Gemfile` - Ruby gem dependencies
- `package.json` - JavaScript dependencies  
- `config/database.yml` - Database configuration
- `config/application.rb` - Rails application configuration
- `Procfile.dev` - Development process definitions for foreman

### Application Structure
- `app/` - Main application code
  - `app/controllers/` - Rails controllers
  - `app/models/` - Rails models
  - `app/views/` - View templates
  - `app/javascript/` - JavaScript source files
  - `app/assets/` - CSS and other assets
- `config/` - Configuration files
- `db/` - Database migrations and schema
- `test/` - Test files (using Minitest, not RSpec despite README mention)

### Key Scripts
- `bin/dev` - Start development environment with foreman
- `bin/setup` - Project setup script
- `bin/rails` - Rails command runner

## Technology Stack Details

- **Framework**: Ruby on Rails 7.1.5.2
- **Ruby Version**: 3.3.1 (can work with 3.2.3)
- **Database**: PostgreSQL 15
- **Frontend**: Hotwire (Turbo + Stimulus)
- **CSS Framework**: Tailwind CSS (likely, inferred from setup)
- **Build Tool**: esbuild for JavaScript bundling
- **Testing**: Minitest (Rails default)
- **Linting**: Rubocop
- **Process Manager**: Foreman
- **Containerization**: Docker with docker-compose

## Troubleshooting Common Issues

### Ruby Version Mismatch
If you encounter "Your Ruby version is X.X.X, but your Gemfile specified Y.Y.Y":
- Temporarily modify `Gemfile` to match your Ruby version
- Or install the correct Ruby version using rbenv/rvm

### Database Connection Issues
- Ensure PostgreSQL container is running: `docker compose ps`
- Verify port 15432 is used, not 5432
- Set environment variables: `export DB_HOST=localhost && export POSTGRES_PASSWORD=password && export PGPORT=15432 PGHOST=localhost`
- The application defaults to connecting to hostname "db" (Docker container name) if DB_HOST is not set

### Asset Compilation Issues
- Run `yarn install` to ensure JavaScript dependencies are installed
- Try `yarn build` manually to check for JavaScript errors
- Ensure Node.js version matches `.node-version` file

### Permission Issues with Gems
- Use `--user-install` flag: `gem install bundler --user-install`
- Ensure PATH includes user gem directory: `export PATH="/home/runner/.local/share/gem/ruby/3.2.0/bin:$PATH"`

### Foreman Not Found
- Install foreman: `gem install foreman --user-install`
- Ensure PATH includes user gem directory

## Development Workflow Best Practices

1. **Always set environment variables** for PostgreSQL connection before running Rails commands
2. **Use `./bin/dev` for development** - it starts both Rails server and asset watcher
3. **Run tests and linting** before committing changes
4. **Check Docker container status** if database connectivity fails
5. **Use proper timeouts** for long-running commands (builds, tests)
6. **Never cancel** build or test operations - they may take several minutes

## Build and Test Timing Expectations

- **Bundle install**: 30-60 seconds (NEVER CANCEL - set timeout to 5+ minutes)
- **Database creation**: 2-3 seconds
- **Database migration**: 1-2 seconds  
- **JavaScript asset build**: 1 second
- **Test suite**: 3-5 seconds (includes asset compilation)
- **Rubocop linting**: 1-2 seconds
- **Application startup**: 5-10 seconds

**CRITICAL**: Never cancel these operations even if they appear to hang. Build processes can take up to 5+ minutes in some environments.