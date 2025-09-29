require 'rails_helper'

RSpec.describe Insurance, type: :model do
  describe "validations" do
    it "需要 insurance_type" do
      insurance = build(:insurance, insurance_type: nil)
      expect(insurance).to_not be_valid
      expect(insurance.errors[:insurance_type]).to include("can't be blank")
    end

    it "insurance_type 必須是有效值" do
      insurance = build(:insurance, insurance_type: "invalid")
      expect(insurance).to_not be_valid
      expect(insurance.errors[:insurance_type]).to include("is not included in the list")
    end

    it "需要 grade_level" do
      insurance = build(:insurance, grade_level: nil)
      expect(insurance).to_not be_valid
      expect(insurance.errors[:grade_level]).to include("can't be blank")
    end

    it "grade_level 必須大於 0" do
      insurance = build(:insurance, grade_level: 0)
      expect(insurance).to_not be_valid
      expect(insurance.errors[:grade_level]).to include("must be greater than 0")
    end

    it "需要 salary_min" do
      insurance = build(:insurance, salary_min: nil)
      expect(insurance).to_not be_valid
      expect(insurance.errors[:salary_min]).to include("can't be blank")
    end

    it "salary_max 必須大於等於 salary_min" do
      insurance = build(:insurance, salary_min: 30_000, salary_max: 25_000)
      expect(insurance).to_not be_valid
      expect(insurance.errors[:salary_max]).to include("must be greater than or equal to 30000.0")
    end

    it "salary_max 可以為 nil（最高級距）" do
      insurance = build(:insurance, :highest_grade)
      expect(insurance).to be_valid
    end

    it "需要 premium_base" do
      insurance = build(:insurance, premium_base: nil)
      expect(insurance).to_not be_valid
      expect(insurance.errors[:premium_base]).to include("can't be blank")
    end

    it "rate 必須在 0 到 1 之間" do
      insurance = build(:insurance, rate: 1.5)
      expect(insurance).to_not be_valid
      expect(insurance.errors[:rate]).to include("must be less than or equal to 1")
    end

    it "負擔比例總和必須等於 1" do
      insurance = build(:insurance, employee_ratio: 0.3, employer_ratio: 0.5, government_ratio: 0.1)
      expect(insurance).to_not be_valid
      expect(insurance.errors[:base]).to include("負擔比例總和必須等於1")
    end

    it "expiry_date 必須晚於 effective_date" do
      insurance = build(:insurance, effective_date: Date.new(2025, 1, 1), expiry_date: Date.new(2024, 12, 31))
      expect(insurance).to_not be_valid
      expect(insurance.errors[:expiry_date]).to include("失效日期必須晚於生效日期")
    end
  end

  describe "scopes" do
    before do
      @active_insurance = create(:insurance)
      @expired_insurance = create(:insurance, :expired)
      @future_insurance = create(:insurance, effective_date: Date.current + 1.year)
    end

    it ".active 回傳目前有效的保險" do
      expect(Insurance.active).to include(@active_insurance)
      expect(Insurance.active).to_not include(@expired_insurance)
      expect(Insurance.active).to_not include(@future_insurance)
    end

    it ".by_type 依保險類型篩選" do
      health_insurance = create(:insurance, :health_insurance)
      expect(Insurance.by_type('health')).to include(health_insurance)
      expect(Insurance.by_type('health')).to_not include(@active_insurance)
    end

    it ".by_salary 依薪資範圍篩選" do
      insurance_low = create(:insurance, salary_min: 20_000, salary_max: 30_000)
      insurance_high = create(:insurance, salary_min: 40_000, salary_max: 50_000)

      expect(Insurance.by_salary(25_000)).to include(insurance_low)
      expect(Insurance.by_salary(25_000)).to_not include(insurance_high)
    end
  end

  describe "class methods" do
    before do
      @labor_grade_1 = create(:insurance, insurance_type: 'labor', salary_min: 28_590, salary_max: 29_999, premium_base: 28_590)
      @labor_grade_2 = create(:insurance, insurance_type: 'labor', salary_min: 30_000, salary_max: 31_999, premium_base: 30_000, grade_level: 2)
    end

    describe ".find_grade_by_salary" do
      it "根據薪資找到對應級距" do
        grade = Insurance.find_grade_by_salary('labor', 29_000)
        expect(grade).to eq(@labor_grade_1)
      end

      it "找不到級距時回傳 nil" do
        grade = Insurance.find_grade_by_salary('labor', 50_000)
        expect(grade).to be_nil
      end
    end

    describe ".calculate_premium" do
      it "計算保險費用分攤" do
        result = Insurance.calculate_premium('labor', 29_000)

        expect(result).to include(:total, :employee, :employer, :government, :grade)
        expect(result[:grade]).to eq(@labor_grade_1)
        expect(result[:total]).to eq(@labor_grade_1.premium_base * @labor_grade_1.rate)
        expect(result[:employee]).to eq(result[:total] * @labor_grade_1.employee_ratio)
      end

      it "找不到級距時回傳 nil" do
        result = Insurance.calculate_premium('labor', 50_000)
        expect(result).to be_nil
      end
    end
  end

  describe "instance methods" do
    let(:insurance) { create(:insurance) }

    describe "#active?" do
      it "目前有效的保險回傳 true" do
        expect(insurance.active?).to be true
      end

      it "已過期的保險回傳 false" do
        expired = create(:insurance, :expired)
        expect(expired.active?).to be false
      end
    end

    describe "#total_premium" do
      it "計算總保險費" do
        expect(insurance.total_premium).to eq(insurance.premium_base * insurance.rate)
      end
    end

    describe "#employee_premium" do
      it "計算勞工負擔保險費" do
        expected = insurance.total_premium * insurance.employee_ratio
        expect(insurance.employee_premium).to eq(expected)
      end
    end

    describe "#employer_premium" do
      it "計算雇主負擔保險費" do
        expected = insurance.total_premium * insurance.employer_ratio
        expect(insurance.employer_premium).to eq(expected)
      end
    end

    describe "#government_premium" do
      it "計算政府負擔保險費" do
        expected = insurance.total_premium * insurance.government_ratio
        expect(insurance.government_premium).to eq(expected)
      end
    end

    describe "#salary_range_text" do
      it "有上限的級距顯示範圍" do
        insurance = create(:insurance, salary_min: 28_590, salary_max: 29_999)
        expect(insurance.salary_range_text).to eq("28590~29999元")
      end

      it "最高級距顯示「以上」" do
        insurance = create(:insurance, :highest_grade)
        expect(insurance.salary_range_text).to eq("45800元以上")
      end
    end
  end

  describe "different insurance types" do
    it "勞保" do
      labor = create(:insurance, insurance_type: 'labor')
      expect(labor).to be_valid
    end

    it "健保" do
      health = create(:insurance, :health_insurance)
      expect(health).to be_valid
    end

    it "勞退" do
      pension = create(:insurance, :labor_pension)
      expect(pension).to be_valid
    end

    it "職災險" do
      injury = create(:insurance, :occupational_injury)
      expect(injury).to be_valid
    end
  end
end