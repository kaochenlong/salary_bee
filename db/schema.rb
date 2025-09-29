# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_29_054352) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tax_id", limit: 8, null: false
    t.index [ "tax_id" ], name: "index_companies_on_tax_id", unique: true
  end

  create_table "insurances", force: :cascade do |t|
    t.string "insurance_type", null: false
    t.integer "grade_level", null: false
    t.decimal "salary_min", precision: 10, scale: 2, null: false
    t.decimal "salary_max", precision: 10, scale: 2
    t.decimal "premium_base", precision: 10, scale: 2, null: false
    t.decimal "rate", precision: 5, scale: 4, null: false
    t.decimal "employee_ratio", precision: 4, scale: 3, null: false
    t.decimal "employer_ratio", precision: 4, scale: 3, null: false
    t.decimal "government_ratio", precision: 4, scale: 3, default: "0.0"
    t.date "effective_date", null: false
    t.date "expiry_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "grade_level" ], name: "index_insurances_on_grade_level"
    t.index [ "insurance_type", "effective_date", "expiry_date" ], name: "index_insurances_on_type_and_dates"
    t.index [ "insurance_type" ], name: "index_insurances_on_insurance_type"
    t.index [ "salary_min", "salary_max" ], name: "index_insurances_on_salary_range"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "user_id" ], name: "index_sessions_on_user_id"
  end

  create_table "user_companies", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "company_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "company_id" ], name: "index_user_companies_on_company_id"
    t.index [ "user_id", "company_id" ], name: "index_user_companies_on_user_id_and_company_id", unique: true
    t.index [ "user_id" ], name: "index_user_companies_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "email_address" ], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "sessions", "users"
  add_foreign_key "user_companies", "companies"
  add_foreign_key "user_companies", "users"
end
