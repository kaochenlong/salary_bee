class Insurance < ApplicationRecord
  INSURANCE_TYPES = %w[labor health labor_pension occupational_injury].freeze

  validates :insurance_type, presence: true, inclusion: { in: INSURANCE_TYPES }
  validates :grade_level, presence: true, numericality: { greater_than: 0 }
  validates :salary_min, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :salary_max, numericality: { greater_than_or_equal_to: :salary_min }, allow_nil: true, if: :salary_min
  validates :premium_base, presence: true, numericality: { greater_than: 0 }
  validates :rate, presence: true, numericality: { greater_than: 0, less_than_or_equal_to: 1 }
  validates :employee_ratio, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :employer_ratio, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :government_ratio, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :effective_date, presence: true

  validate :ratios_sum_to_one
  validate :expiry_date_after_effective_date

  scope :active, -> { where("effective_date <= ? AND (expiry_date IS NULL OR expiry_date > ?)", Date.current, Date.current) }
  scope :by_type, ->(type) { where(insurance_type: type) }
  scope :by_salary, ->(salary) { where("salary_min <= ? AND (salary_max IS NULL OR salary_max >= ?)", salary, salary) }

  def self.find_grade_by_salary(insurance_type, salary)
    active.by_type(insurance_type).by_salary(salary).first
  end

  def self.calculate_premium(insurance_type, salary)
    grade = find_grade_by_salary(insurance_type, salary)
    return nil unless grade

    total_premium = grade.premium_base * grade.rate
    {
      total: total_premium,
      employee: total_premium * grade.employee_ratio,
      employer: total_premium * grade.employer_ratio,
      government: total_premium * grade.government_ratio,
      grade: grade
    }
  end

  def active?
    effective_date <= Date.current && (expiry_date.nil? || expiry_date > Date.current)
  end

  def total_premium
    premium_base * rate
  end

  def employee_premium
    total_premium * employee_ratio
  end

  def employer_premium
    total_premium * employer_ratio
  end

  def government_premium
    total_premium * government_ratio
  end

  def salary_range_text
    if salary_max.nil?
      "#{salary_min.to_i}元以上"
    else
      "#{salary_min.to_i}~#{salary_max.to_i}元"
    end
  end

  private

  def ratios_sum_to_one
    total_ratio = employee_ratio + employer_ratio + government_ratio
    unless (total_ratio - 1.0).abs < 0.001
      errors.add(:base, "負擔比例總和必須等於1")
    end
  end

  def expiry_date_after_effective_date
    return unless expiry_date && effective_date

    if expiry_date <= effective_date
      errors.add(:expiry_date, "失效日期必須晚於生效日期")
    end
  end
end