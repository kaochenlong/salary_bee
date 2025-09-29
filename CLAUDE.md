# CLAUDE.md

## 最重要的指導原則：

- DO NOT OVERDESIGN! DO NOT OVERENGINEER!
- 不要過度設計！不要過度工程化！

## 在開始任何任務之前

- 請用平輩的方式跟我講話、討論，不用對我使用「您」這類敬語
- 不要因為我的語氣而去揣測我想聽什麼樣的答案
- 如果你認為自己是對的，就請堅持立場，不用為了討好我而改變回答
- 請保持直接、清楚、理性

### 重要！請善用 MCP 工具！

- 如果要呼叫函式庫但不確定使用方式，請使用 `context7` MCP 工具取得最新的文件和程式碼範例。

## Architecture

### Tech Stack

- **Backend**: Rails 8.0 with PostgreSQL
- **Frontend**: Hotwire (Turbo) + Alpine.js
- **Styling**: Tailwind CSS v4
- **Authentication**: Rails built-in `has_secure_password`
- **Authorization**: Pundit gem
- **State Management**: AASM gem
- **Asset Pipeline**: Propshaft + esbuild + Tailwind CLI
- **Deployment**: Kamal (Docker)

### Rails 8 Solid Stack

This application uses Rails 8's "Solid" stack for production-ready defaults:

- **Solid Cache**: Database-backed Rails.cache
- **Solid Queue**: Database-backed Active Job backend
- **Solid Cable**: Database-backed Action Cable

### Authentication System

- User model with `has_secure_password`
- Session-based authentication (not JWT)
- Password reset via secure tokens (`generates_token_for`)
- Email validation and normalization
- Authentication concern in `app/controllers/concerns/authentication.rb`

### Frontend Architecture

- **Hotwire Turbo**: SPA-like navigation without JavaScript frameworks
- **Alpine.js**: Replaces Stimulus for lightweight JavaScript interactions
- **Tailwind CSS v4**: Utility-first CSS framework
- **esbuild**: Fast JavaScript bundling
- Assets compiled to `app/assets/builds/`

### Testing Strategy

- **RSpec**: Primary testing framework
- **Factory Bot**: Test data generation
- **Capybara**: System/integration testing
- **Rails Controller Testing**: Controller-specific tests
- Tests organized by type: models, controllers, requests, system, views

### Code Quality Tools

- **RuboCop**: Ruby style guide enforcement (Rails Omakase config)
- **Brakeman**: Security vulnerability scanning
- **Pre-commit hooks**: Automated quality checks before commits
- **Prettier**: JavaScript/CSS formatting

### Key Models and Controllers

- `User`: Authentication and user management
- `Session`: User sessions management
- `ApplicationController`: Base controller with authentication
- `HomeController`: Landing page
- `SessionsController`: Login/logout functionality
- `PasswordsController`: Password reset flow

### Deployment Configuration

- **Kamal**: Modern deployment tool for Docker containers
- **Dockerfile**: Multi-stage build for production
- **Thruster**: HTTP acceleration and caching (optional)
- Configuration in `.kamal/` directory

## Important Notes

- This is a Rails 8.0 application using modern conventions
- No Action Text is included (commented out in application.rb)
- System tests are disabled by default (`config.generators.system_tests = nil`)
- Uses PostgreSQL in all environments
- Styled with **Neubrutalism** design system for auth pages
- All tests should pass before committing changes
- Security scanning is mandatory via pre-commit hooks

