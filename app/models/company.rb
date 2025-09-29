class Company < ApplicationRecord
  has_many :user_companies, dependent: :destroy
  has_many :users, through: :user_companies

  validates :name, presence: true, uniqueness: true
  validates :tax_id, presence: true, uniqueness: true, format: { with: /\A\d{8}\z/, message: "必須是 8 位數字" }
  validate :valid_taiwan_tax_id

  private

  def valid_taiwan_tax_id
    return unless tax_id.present? && tax_id.match?(/\A\d{8}\z/)

    # 台灣統編驗證算法
    validators = [ 1, 2, 1, 2, 1, 2, 4, 1 ]

    check_sum = tax_id.chars
                      .map(&:to_i)
                      .zip(validators)
                      .map { |a, b| number_reducer(a * b) }

    valid = if tax_id[6] == "7"
              check_sum[6] = 0
              [ 0, 1 ].include?(check_sum.sum % 5)
    else
              check_sum.sum % 5 == 0
    end

    unless valid
      errors.add(:tax_id, "統一編號格式不正確")
    end
  end

  def number_reducer(num)
    return num if num < 10
    number_reducer(num.digits.sum)
  end
end
