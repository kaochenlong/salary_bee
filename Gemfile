source "https://rubygems.org"

# ===== 核心框架 =====
gem "rails", "~> 8.1.0"          # Rails 8.0 主框架

# ===== 網頁伺服器 =====
gem "puma", "~> 7.0", ">= 7.0.4" # 高效能 Ruby 網頁伺服器

# ===== 資料庫 =====
gem "pg", "~> 1.1"               # PostgreSQL 資料庫適配器

# ===== 前端資產管理 =====
gem "propshaft"                  # Rails 8 現代資產管道
gem "jsbundling-rails"           # JavaScript 打包和編譯
gem "cssbundling-rails"          # CSS 打包和處理

# ===== Hotwire 全端框架 =====
gem "turbo-rails"                # SPA 級別的頁面加速器

# ===== 快取與背景作業 =====
gem "solid_cache"                # 資料庫支援的 Rails.cache
gem "solid_queue"                # 資料庫支援的 Active Job
gem "solid_cable"                # 資料庫支援的 Action Cable

# ===== 部署與效能 =====
gem "kamal", require: false      # Docker 容器部署工具
gem "thruster", require: false   # HTTP 快取壓縮和加速

# ===== 跨平台支援 =====
gem "tzinfo-data", platforms: %i[ windows jruby ]  # Windows 時區資料

# ===== 未來可能需要的功能 =====
gem "bcrypt", "~> 3.1.7"       # 密碼加密 (has_secure_password)
# gem "image_processing", "~> 1.2" # Active Storage 圖片處理

# ===== 授權與狀態管理 =====
gem "pundit"                    # 授權管理框架
gem "aasm"                      # 狀態機管理

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rspec-rails", "~> 8.0"     # RSpec 測試框架
  gem "factory_bot", "~> 6.5"     # 測試資料產生器
  gem "rails-controller-testing"  # Controller 測試支援
  gem "capybara"                   # System 測試支援
  gem "brakeman", require: false  # 安全漏洞靜態分析
  gem "rubocop", "~> 1.81"        # Ruby 程式碼風格檢查
  gem "rubocop-rails-omakase", require: false  # Rails 程式碼風格檢查
end

group :development do
  gem "web-console"                # 例外頁面的互動式控制台
  gem "letter_opener"              # 開發環境郵件預覽
end

