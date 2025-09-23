source "https://rubygems.org"

# ========================================
# Core Framework
# ========================================
gem "rails", "~> 8.0.3"

# ========================================
# Web Server
# ========================================
gem "puma", ">= 5.0"                    # High-performance web server
gem "thruster", require: false          # HTTP asset caching/compression and X-Sendfile acceleration

# ========================================
# Assets & Frontend
# ========================================
gem "propshaft"                         # Modern asset pipeline for Rails
gem "jsbundling-rails"                  # Bundle and transpile JavaScript
gem "cssbundling-rails"                 # Bundle and process CSS
gem "turbo-rails"                       # Hotwire's SPA-like page accelerator

# ========================================
# Database
# ========================================
gem "sqlite3", ">= 2.1"                 # SQLite database adapter

# ========================================
# Caching & Background Jobs
# ========================================
# Solid suite: Database-backed adapters
gem "solid_cache"                       # Database-backed Rails.cache store
gem "solid_queue"                       # Database-backed Active Job queue
gem "solid_cable"                       # Database-backed Action Cable adapter

# ========================================
# Deployment
# ========================================
gem "kamal", require: false             # Docker container deployment tool

# ========================================
# Platform Compatibility
# ========================================
gem "tzinfo-data", platforms: %i[ windows jruby ]  # Timezone data for Windows/JRuby

# ========================================
# Optional Features
# ========================================
# gem "bcrypt", "~> 3.1.7"              # Active Model has_secure_password support

# ========================================
# Development & Test
# ========================================
group :development, :test do
  # Debugging
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Code Quality
  gem "brakeman", require: false        # Static analysis for security vulnerabilities
  gem "rubocop-rails-omakase", require: false  # Rails code style checker
end

# ========================================
# Development Only
# ========================================
group :development do
  gem "web-console"                     # Debug console on exception pages
end


gem "devise", "~> 4.9"
