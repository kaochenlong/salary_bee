FactoryBot.define do
  factory :insurance do
    insurance_type { "labor" }
    grade_level { 1 }
    salary_min { 28_590 }
    salary_max { 29_999 }
    premium_base { 28_590 }
    rate { 0.125 }
    employee_ratio { 0.2 }
    employer_ratio { 0.7 }
    government_ratio { 0.1 }
    effective_date { Date.new(2025, 1, 1) }
    expiry_date { nil }

    trait :health_insurance do
      insurance_type { "health" }
      rate { 0.0517 }
      employee_ratio { 0.3 }
      employer_ratio { 0.6 }
      government_ratio { 0.1 }
    end

    trait :labor_pension do
      insurance_type { "labor_pension" }
      rate { 0.06 }
      employee_ratio { 0.0 }
      employer_ratio { 1.0 }
      government_ratio { 0.0 }
    end

    trait :occupational_injury do
      insurance_type { "occupational_injury" }
      rate { 0.002 }
      employee_ratio { 0.0 }
      employer_ratio { 1.0 }
      government_ratio { 0.0 }
    end

    trait :highest_grade do
      grade_level { 45 }
      salary_min { 45_800 }
      salary_max { nil }
      premium_base { 45_800 }
    end

    trait :expired do
      effective_date { Date.new(2024, 1, 1) }
      expiry_date { Date.new(2024, 12, 31) }
    end

    # 邊界測試用 traits
    trait :lowest_labor_grade do
      insurance_type { "labor" }
      grade_level { 1 }
      salary_min { 28_590 }
      salary_max { 29_999 }
      premium_base { 28_590 }
    end

    trait :highest_labor_grade do
      insurance_type { "labor" }
      grade_level { 15 }
      salary_min { 45_800 }
      salary_max { nil }
      premium_base { 45_800 }
    end

    trait :highest_health_grade do
      insurance_type { "health" }
      grade_level { 67 }
      salary_min { 313_000 }
      salary_max { nil }
      premium_base { 313_000 }
      rate { 0.0517 }
      employee_ratio { 0.3 }
      employer_ratio { 0.6 }
      government_ratio { 0.1 }
    end

    trait :highest_pension_grade do
      insurance_type { "labor_pension" }
      grade_level { 27 }
      salary_min { 150_000 }
      salary_max { nil }
      premium_base { 150_000 }
      rate { 0.06 }
      employee_ratio { 0.0 }
      employer_ratio { 1.0 }
      government_ratio { 0.0 }
    end

    trait :highest_injury_grade do
      insurance_type { "occupational_injury" }
      grade_level { 38 }
      salary_min { 72_800 }
      salary_max { nil }
      premium_base { 72_800 }
      rate { 0.002 }
      employee_ratio { 0.0 }
      employer_ratio { 1.0 }
      government_ratio { 0.0 }
    end

    # 中間級距測試用
    trait :middle_grade do
      grade_level { 8 }
      salary_min { 37_200 }
      salary_max { 38_399 }
      premium_base { 37_200 }
    end

    # 特殊日期測試用
    trait :effective_today do
      effective_date { Date.current }
      expiry_date { nil }
    end

    trait :expires_today do
      effective_date { Date.current - 1.year }
      expiry_date { Date.current }
    end

    trait :effective_tomorrow do
      effective_date { Date.current + 1.day }
      expiry_date { nil }
    end

    trait :expired_yesterday do
      effective_date { Date.current - 1.year }
      expiry_date { Date.current - 1.day }
    end

    # 2025年實際級距資料用於測試
    trait :labor_2025_grade_5 do
      insurance_type { "labor" }
      grade_level { 5 }
      salary_min { 33_600 }
      salary_max { 34_799 }
      premium_base { 33_600 }
      rate { 0.125 }
      employee_ratio { 0.2 }
      employer_ratio { 0.7 }
      government_ratio { 0.1 }
      effective_date { Date.new(2025, 1, 1) }
    end

    trait :health_2025_grade_10 do
      insurance_type { "health" }
      grade_level { 10 }
      salary_min { 43_000 }
      salary_max { 45_999 }
      premium_base { 45_800 }
      rate { 0.0517 }
      employee_ratio { 0.3 }
      employer_ratio { 0.6 }
      government_ratio { 0.1 }
      effective_date { Date.new(2025, 1, 1) }
    end

    # 重疊期間測試用
    trait :overlapping_period_old do
      effective_date { Date.new(2024, 1, 1) }
      expiry_date { Date.new(2024, 12, 31) }
      rate { 0.115 } # 舊費率
    end

    trait :overlapping_period_new do
      effective_date { Date.new(2025, 1, 1) }
      expiry_date { nil }
      rate { 0.125 } # 新費率
    end
  end
end