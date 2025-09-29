require 'rails_helper'

RSpec.describe Insurance, type: :model do
  describe "邊界條件測試" do
    describe "級距查詢邊界測試" do
      before do
        @labor_grade_1 = create(:insurance, :lowest_labor_grade)
        @labor_grade_15 = create(:insurance, :highest_labor_grade)
        @health_grade_67 = create(:insurance, :highest_health_grade)
      end

      it "薪資剛好等於級距下限時能正確匹配" do
        result = Insurance.find_grade_by_salary('labor', 28_590)
        expect(result).to eq(@labor_grade_1)
        expect(result.salary_min).to eq(28_590)
      end

      it "薪資剛好等於級距上限時能正確匹配" do
        result = Insurance.find_grade_by_salary('labor', 29_999)
        expect(result).to eq(@labor_grade_1)
        expect(result.salary_max).to eq(29_999)
      end

      it "薪資超出勞保最高級距時匹配最高級距" do
        result = Insurance.find_grade_by_salary('labor', 50_000)
        expect(result).to eq(@labor_grade_15)
        expect(result.salary_max).to be_nil
      end

      it "薪資低於最低級距時找不到匹配" do
        result = Insurance.find_grade_by_salary('labor', 20_000)
        expect(result).to be_nil
      end

      it "健保最高級距313000元能正確匹配" do
        result = Insurance.find_grade_by_salary('health', 350_000)
        expect(result).to eq(@health_grade_67)
        expect(result.premium_base).to eq(313_000)
      end

      it "不同保險類型有不同的級距上限" do
        # 建立健保高級距用於測試
        high_health = create(:insurance, :health_insurance,
          salary_min: 190_000, salary_max: 220_000, premium_base: 200_000)

        high_salary = 200_000
        labor_result = Insurance.find_grade_by_salary('labor', high_salary)
        health_result = Insurance.find_grade_by_salary('health', high_salary)

        expect(labor_result).to eq(@labor_grade_15)
        expect(labor_result.premium_base).to eq(45_800)
        expect(health_result).to eq(high_health)
        expect(health_result.premium_base).to be > 45_800
      end
    end

    describe "薪資邊界值測試" do
      before do
        @middle_grade = create(:insurance, :middle_grade)
      end

      it "薪資為0時找不到匹配" do
        result = Insurance.find_grade_by_salary('labor', 0)
        expect(result).to be_nil
      end

      it "薪資為負數時找不到匹配" do
        result = Insurance.find_grade_by_salary('labor', -1000)
        expect(result).to be_nil
      end

      it "薪資剛好在級距邊界上能正確匹配（下限）" do
        result = Insurance.find_grade_by_salary('labor', 37_200)
        expect(result).to eq(@middle_grade)
      end

      it "薪資剛好在級距邊界上能正確匹配（上限）" do
        result = Insurance.find_grade_by_salary('labor', 38_399)
        expect(result).to eq(@middle_grade)
      end

      it "薪資超出級距邊界一元時不匹配該級距" do
        result = Insurance.find_grade_by_salary('labor', 38_400)
        expect(result).to_not eq(@middle_grade)
      end
    end

    describe "日期邊界測試" do
      it "保險在生效日當天能被查詢到" do
        insurance = create(:insurance, :effective_today)
        expect(insurance.active?).to be true
        expect(Insurance.active).to include(insurance)
      end

      it "保險在失效日當天不能被查詢到" do
        insurance = create(:insurance, :expires_today)
        expect(insurance.active?).to be false
        expect(Insurance.active).to_not include(insurance)
      end

      it "未來生效的保險目前不能被查詢到" do
        insurance = create(:insurance, :effective_tomorrow)
        expect(insurance.active?).to be false
        expect(Insurance.active).to_not include(insurance)
      end

      it "昨天過期的保險不能被查詢到" do
        insurance = create(:insurance, :expired_yesterday)
        expect(insurance.active?).to be false
        expect(Insurance.active).to_not include(insurance)
      end
    end
  end

  describe "精確性測試" do
    describe "保險費計算精度" do
      before do
        @labor_insurance = create(:insurance, :labor_2025_grade_5)
      end

      it "保險費計算結果精確到小數點後2位" do
        result = @labor_insurance.total_premium
        expected = 33_600 * 0.125 # 4200.0
        expect(result).to eq(expected)
        expect(result.round(2)).to eq(result)
      end

      it "勞工負擔金額計算正確" do
        result = @labor_insurance.employee_premium
        expected = 33_600 * 0.125 * 0.2 # 840.0
        expect(result).to eq(expected)
      end

      it "雇主負擔金額計算正確" do
        result = @labor_insurance.employer_premium
        expected = 33_600 * 0.125 * 0.7 # 2940.0
        expect(result).to eq(expected)
      end

      it "政府負擔金額計算正確" do
        result = @labor_insurance.government_premium
        expected = 33_600 * 0.125 * 0.1 # 420.0
        expect(result).to eq(expected)
      end

      it "各方負擔總和等於總保險費" do
        total = @labor_insurance.total_premium
        sum = @labor_insurance.employee_premium +
              @labor_insurance.employer_premium +
              @labor_insurance.government_premium
        expect(sum).to eq(total)
      end
    end

    describe "四種保險費率驗證" do
      it "勞保費率12.5%計算正確" do
        labor = create(:insurance, insurance_type: 'labor', premium_base: 30_000, rate: 0.125)
        expect(labor.total_premium).to eq(3_750)
      end

      it "健保費率5.17%計算正確" do
        health = create(:insurance, :health_insurance, premium_base: 30_000)
        expected = 30_000 * 0.0517 # 1551.0
        expect(health.total_premium).to eq(expected)
      end

      it "勞退提繳率6%計算正確" do
        pension = create(:insurance, :labor_pension, premium_base: 30_000)
        expected = 30_000 * 0.06 # 1800.0
        expect(pension.total_premium).to eq(expected)
      end

      it "職災險費率0.2%計算正確" do
        injury = create(:insurance, :occupational_injury, premium_base: 30_000)
        expected = 30_000 * 0.002 # 60.0
        expect(injury.total_premium).to eq(expected)
      end
    end

    describe "負擔比例精確性驗證" do
      it "勞保負擔比例：勞工20%、雇主70%、政府10%" do
        labor = create(:insurance, insurance_type: 'labor')
        expect(labor.employee_ratio).to eq(0.2)
        expect(labor.employer_ratio).to eq(0.7)
        expect(labor.government_ratio).to eq(0.1)
        expect(labor.employee_ratio + labor.employer_ratio + labor.government_ratio).to eq(1.0)
      end

      it "健保負擔比例：勞工30%、雇主60%、政府10%" do
        health = create(:insurance, :health_insurance)
        expect(health.employee_ratio).to eq(0.3)
        expect(health.employer_ratio).to eq(0.6)
        expect(health.government_ratio).to eq(0.1)
      end

      it "勞退負擔比例：雇主100%" do
        pension = create(:insurance, :labor_pension)
        expect(pension.employee_ratio).to eq(0.0)
        expect(pension.employer_ratio).to eq(1.0)
        expect(pension.government_ratio).to eq(0.0)
      end

      it "職災險負擔比例：雇主100%" do
        injury = create(:insurance, :occupational_injury)
        expect(injury.employee_ratio).to eq(0.0)
        expect(injury.employer_ratio).to eq(1.0)
        expect(injury.government_ratio).to eq(0.0)
      end
    end
  end

  describe "2025年台灣實際級距測試" do
    before do
      # 建立實際的級距資料進行測試
      @labor_basic = create(:insurance,
        insurance_type: 'labor',
        salary_min: 28_590,
        salary_max: 29_999,
        premium_base: 28_590,
        rate: 0.125
      )

      @health_grade_10 = create(:insurance, :health_2025_grade_10)
    end

    it "2025年基本工資28590元能正確匹配勞保第1級" do
      result = Insurance.find_grade_by_salary('labor', 28_590)
      expect(result).to eq(@labor_basic)
      expect(result.premium_base).to eq(28_590)
    end

    it "基本工資員工的勞保費計算" do
      result = Insurance.calculate_premium('labor', 28_590)
      expect(result).to_not be_nil
      expect(result[:grade]).to eq(@labor_basic)

      total = 28_590 * 0.125 # 3573.75
      expect(result[:total]).to eq(total)
      expect(result[:employee]).to eq(total * 0.2) # 714.75
      expect(result[:employer]).to eq(total * 0.7) # 2501.625
      expect(result[:government]).to eq(total * 0.1) # 357.375
    end

    it "健保第10級距測試（43000-45999元）" do
      # 測試級距中間值
      result = Insurance.find_grade_by_salary('health', 44_000)
      expect(result).to eq(@health_grade_10)
      expect(result.premium_base).to eq(45_800)
    end

    it "不同保險類型對同一薪資的級距差異" do
      salary = 50_000

      # 建立勞保最高級距
      labor_highest = create(:insurance, :highest_labor_grade)
      # 建立健保對應級距
      health_grade = create(:insurance, :health_insurance,
        salary_min: 48_000, salary_max: 52_000, premium_base: 51_000)

      labor_result = Insurance.calculate_premium('labor', salary)
      health_result = Insurance.calculate_premium('health', salary)

      expect(labor_result).to_not be_nil
      expect(health_result).to_not be_nil

      # 勞保超過最高級距，使用45800
      expect(labor_result[:grade].premium_base).to eq(45_800)

      # 健保還在級距範圍內，使用對應級距
      expect(health_result[:grade].premium_base).to be > 45_800
    end
  end

  describe "整合測試" do
    describe "多保險同時計算" do
      before do
        # 建立四種保險的測試級距
        @labor = create(:insurance, insurance_type: 'labor', salary_min: 40_000, salary_max: 41_999, premium_base: 40_800)
        @health = create(:insurance, :health_insurance, salary_min: 40_000, salary_max: 42_999, premium_base: 42_000)
        @pension = create(:insurance, :labor_pension, salary_min: 40_000, salary_max: 41_999, premium_base: 40_800)
        @injury = create(:insurance, :occupational_injury, salary_min: 40_000, salary_max: 41_999, premium_base: 40_800)
      end

      it "薪資40500元的完整保險費計算" do
        salary = 40_500

        labor_result = Insurance.calculate_premium('labor', salary)
        health_result = Insurance.calculate_premium('health', salary)
        pension_result = Insurance.calculate_premium('labor_pension', salary)
        injury_result = Insurance.calculate_premium('occupational_injury', salary)

        expect(labor_result).to_not be_nil
        expect(health_result).to_not be_nil
        expect(pension_result).to_not be_nil
        expect(injury_result).to_not be_nil

        # 驗證各保險的投保金額
        expect(labor_result[:grade].premium_base).to eq(40_800)
        expect(health_result[:grade].premium_base).to eq(42_000)
        expect(pension_result[:grade].premium_base).to eq(40_800)
        expect(injury_result[:grade].premium_base).to eq(40_800)

        # 驗證勞工總負擔（只有勞保和健保）
        employee_total = labor_result[:employee] + health_result[:employee]
        expect(employee_total).to be > 0

        # 驗證雇主總負擔（四種保險都有）
        employer_total = labor_result[:employer] + health_result[:employer] +
                        pension_result[:employer] + injury_result[:employer]
        expect(employer_total).to be > employee_total
      end

      it "高薪員工（80000元）的保險計算邏輯" do
        high_salary = 80_000

        # 建立高薪測試級距
        high_labor = create(:insurance, :highest_labor_grade)
        high_health = create(:insurance, :health_insurance, salary_min: 75_000, salary_max: 84_999, premium_base: 80_200)
        high_pension = create(:insurance, :labor_pension, salary_min: 75_000, salary_max: 84_999, premium_base: 80_000)
        high_injury = create(:insurance, :highest_injury_grade)

        labor_result = Insurance.calculate_premium('labor', high_salary)
        health_result = Insurance.calculate_premium('health', high_salary)

        # 勞保達到上限
        expect(labor_result[:grade]).to eq(high_labor)
        expect(labor_result[:grade].premium_base).to eq(45_800)

        # 健保仍在級距內
        expect(health_result[:grade]).to eq(high_health)
        expect(health_result[:grade].premium_base).to eq(80_200)
      end
    end

    describe "時效性整合測試" do
      it "保險級距更新時的過渡處理" do
        # 建立2024年舊級距（已過期）
        old_insurance = create(:insurance, :overlapping_period_old,
          salary_min: 28_000, salary_max: 31_000, premium_base: 30_000)
        # 建立2025年新級距（目前有效）
        new_insurance = create(:insurance, :overlapping_period_new,
          salary_min: 28_000, salary_max: 31_000, premium_base: 30_000)

        # 查詢應該只回傳有效的保險
        active_insurances = Insurance.active.where(insurance_type: 'labor')
        expect(active_insurances).to include(new_insurance)
        expect(active_insurances).to_not include(old_insurance)

        # 費率應該是新的
        result = Insurance.calculate_premium('labor', 30_000)
        expect(result).to_not be_nil
        expect(result[:grade].rate).to eq(0.125) # 新費率
      end
    end
  end

  describe "錯誤處理測試" do
    describe "無效輸入處理" do
      it "不存在的保險類型回傳nil" do
        result = Insurance.calculate_premium('invalid_type', 30_000)
        expect(result).to be_nil
      end

      it "nil薪資回傳nil" do
        result = Insurance.calculate_premium('labor', nil)
        expect(result).to be_nil
      end

      it "字串薪資嘗試轉換" do
        create(:insurance, salary_min: 30_000, salary_max: 31_999, premium_base: 30_000)
        # 字串數字應該能正常處理
        result = Insurance.calculate_premium('labor', '30500')
        expect(result).to_not be_nil
      end

      it "空字串保險類型回傳nil" do
        result = Insurance.calculate_premium('', 30_000)
        expect(result).to be_nil
      end
    end

    describe "邊界錯誤處理" do
      it "找不到對應級距時回傳nil" do
        result = Insurance.find_grade_by_salary('labor', 100_000)
        expect(result).to be_nil
      end

      it "calculate_premium找不到級距時回傳nil" do
        result = Insurance.calculate_premium('labor', 100_000)
        expect(result).to be_nil
      end

      it "過期的保險級距不會被查詢到" do
        expired = create(:insurance, :expired)
        result = Insurance.find_grade_by_salary('labor', 30_000)
        expect(result).to_not eq(expired)
      end
    end

    describe "資料一致性檢查" do
      it "同一保險類型同一時期不應有重疊級距" do
        base_attrs = {
          insurance_type: 'labor',
          effective_date: Date.new(2025, 1, 1),
          expiry_date: nil,
          rate: 0.125,
          employee_ratio: 0.2,
          employer_ratio: 0.7,
          government_ratio: 0.1
        }

        create(:insurance, base_attrs.merge(
          grade_level: 1,
          salary_min: 28_590,
          salary_max: 30_000,
          premium_base: 28_590
        ))

        # 重疊級距應該通過業務邏輯控制，這裡只測試查詢邏輯
        create(:insurance, base_attrs.merge(
          grade_level: 2,
          salary_min: 29_500, # 與第一個級距重疊
          salary_max: 31_000,
          premium_base: 30_000
        ))

        # 查詢重疊薪資範圍時應該回傳第一個匹配的級距
        result = Insurance.find_grade_by_salary('labor', 29_800)
        expect(result).to_not be_nil
        expect(result.grade_level).to eq(1) # 應該回傳第一個匹配的
      end
    end
  end

  describe "薪資範圍文字顯示測試" do
    it "有上限級距顯示範圍格式" do
      insurance = create(:insurance, salary_min: 30_000, salary_max: 31_999)
      expect(insurance.salary_range_text).to eq("30000~31999元")
    end

    it "最高級距顯示以上格式" do
      insurance = create(:insurance, :highest_grade)
      expect(insurance.salary_range_text).to eq("45800元以上")
    end

    it "基本工資級距格式正確" do
      insurance = create(:insurance, salary_min: 28_590, salary_max: 29_999)
      expect(insurance.salary_range_text).to eq("28590~29999元")
    end
  end
end