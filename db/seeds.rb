# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# 2025年台灣勞健保級距資料
puts "建立2025年勞健保級距資料..."

effective_date = Date.new(2025, 1, 1)

# 清除舊資料
Insurance.where(effective_date: effective_date).destroy_all

# 勞保級距 (2025年費率12.5%，負擔比例：勞工20%、雇主70%、政府10%)
labor_grades = [
  { grade: 1, min: 28590, max: 29999, base: 28590 },
  { grade: 2, min: 30000, max: 31199, base: 30000 },
  { grade: 3, min: 31200, max: 32399, base: 31200 },
  { grade: 4, min: 32400, max: 33599, base: 32400 },
  { grade: 5, min: 33600, max: 34799, base: 33600 },
  { grade: 6, min: 34800, max: 35999, base: 34800 },
  { grade: 7, min: 36000, max: 37199, base: 36000 },
  { grade: 8, min: 37200, max: 38399, base: 37200 },
  { grade: 9, min: 38400, max: 39599, base: 38400 },
  { grade: 10, min: 39600, max: 40799, base: 39600 },
  { grade: 11, min: 40800, max: 41999, base: 40800 },
  { grade: 12, min: 42000, max: 43199, base: 42000 },
  { grade: 13, min: 43200, max: 44399, base: 43200 },
  { grade: 14, min: 44400, max: 45799, base: 44400 },
  { grade: 15, min: 45800, max: nil, base: 45800 }
]

labor_grades.each do |grade_data|
  Insurance.create!(
    insurance_type: 'labor',
    grade_level: grade_data[:grade],
    salary_min: grade_data[:min],
    salary_max: grade_data[:max],
    premium_base: grade_data[:base],
    rate: 0.125,
    employee_ratio: 0.2,
    employer_ratio: 0.7,
    government_ratio: 0.1,
    effective_date: effective_date
  )
end

# 健保級距 (2025年費率5.17%，負擔比例：勞工30%、雇主60%、政府10%)
health_grades = [
  { grade: 1, min: 28590, max: 29999, base: 28590 },
  { grade: 2, min: 30000, max: 31199, base: 30000 },
  { grade: 3, min: 31200, max: 32399, base: 31200 },
  { grade: 4, min: 32400, max: 33599, base: 32400 },
  { grade: 5, min: 33600, max: 34799, base: 34800 },
  { grade: 6, min: 34800, max: 36299, base: 36300 },
  { grade: 7, min: 36300, max: 37999, base: 38200 },
  { grade: 8, min: 38000, max: 39999, base: 40100 },
  { grade: 9, min: 40000, max: 42999, base: 42000 },
  { grade: 10, min: 43000, max: 45999, base: 45800 },
  { grade: 11, min: 46000, max: 47999, base: 48200 },
  { grade: 12, min: 48000, max: 51999, base: 51000 },
  { grade: 13, min: 52000, max: 54999, base: 54500 },
  { grade: 14, min: 55000, max: 57999, base: 57800 },
  { grade: 15, min: 58000, max: 61999, base: 60800 },
  { grade: 16, min: 62000, max: 65999, base: 64000 },
  { grade: 17, min: 66000, max: 69999, base: 67500 },
  { grade: 18, min: 70000, max: 74999, base: 72800 },
  { grade: 19, min: 75000, max: 79999, base: 76500 },
  { grade: 20, min: 80000, max: 84999, base: 80200 },
  { grade: 21, min: 85000, max: 89999, base: 83000 },
  { grade: 22, min: 90000, max: 95999, base: 87600 },
  { grade: 23, min: 96000, max: 101999, base: 92100 },
  { grade: 24, min: 102000, max: 106999, base: 96400 },
  { grade: 25, min: 107000, max: 111999, base: 100700 },
  { grade: 26, min: 112000, max: 116999, base: 105000 },
  { grade: 27, min: 117000, max: 121999, base: 109500 },
  { grade: 28, min: 122000, max: 126999, base: 114000 },
  { grade: 29, min: 127000, max: 131999, base: 118500 },
  { grade: 30, min: 132000, max: 136999, base: 123000 },
  { grade: 31, min: 137000, max: 141999, base: 127500 },
  { grade: 32, min: 142000, max: 146999, base: 132000 },
  { grade: 33, min: 147000, max: 151999, base: 136500 },
  { grade: 34, min: 152000, max: 156999, base: 141000 },
  { grade: 35, min: 157000, max: 161999, base: 145500 },
  { grade: 36, min: 162000, max: 166999, base: 150000 },
  { grade: 37, min: 167000, max: 171999, base: 154500 },
  { grade: 38, min: 172000, max: 176999, base: 159000 },
  { grade: 39, min: 177000, max: 181999, base: 163500 },
  { grade: 40, min: 182000, max: 186999, base: 168000 },
  { grade: 41, min: 187000, max: 191999, base: 172500 },
  { grade: 42, min: 192000, max: 196999, base: 177000 },
  { grade: 43, min: 197000, max: 201999, base: 181500 },
  { grade: 44, min: 202000, max: 206999, base: 186000 },
  { grade: 45, min: 207000, max: 211999, base: 190500 },
  { grade: 46, min: 212000, max: 216999, base: 195000 },
  { grade: 47, min: 217000, max: 221999, base: 199500 },
  { grade: 48, min: 222000, max: 226999, base: 204000 },
  { grade: 49, min: 227000, max: 231999, base: 208500 },
  { grade: 50, min: 232000, max: 236999, base: 213000 },
  { grade: 51, min: 237000, max: 241999, base: 217500 },
  { grade: 52, min: 242000, max: 246999, base: 222000 },
  { grade: 53, min: 247000, max: 251999, base: 226500 },
  { grade: 54, min: 252000, max: 256999, base: 231000 },
  { grade: 55, min: 257000, max: 261999, base: 235500 },
  { grade: 56, min: 262000, max: 266999, base: 240000 },
  { grade: 57, min: 267000, max: 271999, base: 244500 },
  { grade: 58, min: 272000, max: 276999, base: 249000 },
  { grade: 59, min: 277000, max: 281999, base: 253500 },
  { grade: 60, min: 282000, max: 286999, base: 258000 },
  { grade: 61, min: 287000, max: 291999, base: 262500 },
  { grade: 62, min: 292000, max: 296999, base: 267000 },
  { grade: 63, min: 297000, max: 301999, base: 271500 },
  { grade: 64, min: 302000, max: 306999, base: 276000 },
  { grade: 65, min: 307000, max: 311999, base: 280500 },
  { grade: 66, min: 312000, max: 313000, base: 285000 },
  { grade: 67, min: 313000, max: nil, base: 313000 }
]

health_grades.each do |grade_data|
  Insurance.create!(
    insurance_type: 'health',
    grade_level: grade_data[:grade],
    salary_min: grade_data[:min],
    salary_max: grade_data[:max],
    premium_base: grade_data[:base],
    rate: 0.0517,
    employee_ratio: 0.3,
    employer_ratio: 0.6,
    government_ratio: 0.1,
    effective_date: effective_date
  )
end

# 勞退級距 (提繳率6%，雇主負擔100%)
labor_pension_grades = [
  { grade: 1, min: 28590, max: 29999, base: 28590 },
  { grade: 2, min: 30000, max: 31199, base: 30000 },
  { grade: 3, min: 31200, max: 32399, base: 31200 },
  { grade: 4, min: 32400, max: 33599, base: 32400 },
  { grade: 5, min: 33600, max: 34799, base: 33600 },
  { grade: 6, min: 34800, max: 35999, base: 34800 },
  { grade: 7, min: 36000, max: 37199, base: 36000 },
  { grade: 8, min: 37200, max: 38399, base: 37200 },
  { grade: 9, min: 38400, max: 39599, base: 38400 },
  { grade: 10, min: 39600, max: 40799, base: 39600 },
  { grade: 11, min: 40800, max: 41999, base: 40800 },
  { grade: 12, min: 42000, max: 43199, base: 42000 },
  { grade: 13, min: 43200, max: 44399, base: 43200 },
  { grade: 14, min: 44400, max: 45799, base: 44400 },
  { grade: 15, min: 45800, max: 46999, base: 45800 },
  { grade: 16, min: 47000, max: 48199, base: 47000 },
  { grade: 17, min: 48200, max: 49399, base: 48200 },
  { grade: 18, min: 49400, max: 50599, base: 49400 },
  { grade: 19, min: 50600, max: 51799, base: 50600 },
  { grade: 20, min: 51800, max: 52999, base: 51800 },
  { grade: 21, min: 53000, max: 54199, base: 53000 },
  { grade: 22, min: 54200, max: 55399, base: 54200 },
  { grade: 23, min: 55400, max: 56599, base: 55400 },
  { grade: 24, min: 56600, max: 57799, base: 56600 },
  { grade: 25, min: 57800, max: 58999, base: 57800 },
  { grade: 26, min: 59000, max: 149999, base: 59000 },
  { grade: 27, min: 150000, max: nil, base: 150000 }
]

labor_pension_grades.each do |grade_data|
  Insurance.create!(
    insurance_type: 'labor_pension',
    grade_level: grade_data[:grade],
    salary_min: grade_data[:min],
    salary_max: grade_data[:max],
    premium_base: grade_data[:base],
    rate: 0.06,
    employee_ratio: 0.0,
    employer_ratio: 1.0,
    government_ratio: 0.0,
    effective_date: effective_date
  )
end

# 職災險級距 (平均費率0.2%，雇主負擔100%)
occupational_injury_grades = [
  { grade: 1, min: 28590, max: 29999, base: 28590 },
  { grade: 2, min: 30000, max: 31199, base: 30000 },
  { grade: 3, min: 31200, max: 32399, base: 31200 },
  { grade: 4, min: 32400, max: 33599, base: 32400 },
  { grade: 5, min: 33600, max: 34799, base: 33600 },
  { grade: 6, min: 34800, max: 35999, base: 34800 },
  { grade: 7, min: 36000, max: 37199, base: 36000 },
  { grade: 8, min: 37200, max: 38399, base: 37200 },
  { grade: 9, min: 38400, max: 39599, base: 38400 },
  { grade: 10, min: 39600, max: 40799, base: 39600 },
  { grade: 11, min: 40800, max: 41999, base: 40800 },
  { grade: 12, min: 42000, max: 43199, base: 42000 },
  { grade: 13, min: 43200, max: 44399, base: 43200 },
  { grade: 14, min: 44400, max: 45799, base: 44400 },
  { grade: 15, min: 45800, max: 46999, base: 45800 },
  { grade: 16, min: 47000, max: 48199, base: 47000 },
  { grade: 17, min: 48200, max: 49399, base: 48200 },
  { grade: 18, min: 49400, max: 50599, base: 49400 },
  { grade: 19, min: 50600, max: 51799, base: 50600 },
  { grade: 20, min: 51800, max: 52999, base: 51800 },
  { grade: 21, min: 53000, max: 54199, base: 53000 },
  { grade: 22, min: 54200, max: 55399, base: 54200 },
  { grade: 23, min: 55400, max: 56599, base: 55400 },
  { grade: 24, min: 56600, max: 57799, base: 56600 },
  { grade: 25, min: 57800, max: 58999, base: 57800 },
  { grade: 26, min: 59000, max: 60199, base: 59000 },
  { grade: 27, min: 60200, max: 61399, base: 60200 },
  { grade: 28, min: 61400, max: 62599, base: 61400 },
  { grade: 29, min: 62600, max: 63799, base: 62600 },
  { grade: 30, min: 63800, max: 64999, base: 63800 },
  { grade: 31, min: 65000, max: 66199, base: 65000 },
  { grade: 32, min: 66200, max: 67399, base: 66200 },
  { grade: 33, min: 67400, max: 68599, base: 67400 },
  { grade: 34, min: 68600, max: 69799, base: 68600 },
  { grade: 35, min: 69800, max: 70999, base: 69800 },
  { grade: 36, min: 71000, max: 72199, base: 71000 },
  { grade: 37, min: 72200, max: 72800, base: 72200 },
  { grade: 38, min: 72800, max: nil, base: 72800 }
]

occupational_injury_grades.each do |grade_data|
  Insurance.create!(
    insurance_type: 'occupational_injury',
    grade_level: grade_data[:grade],
    salary_min: grade_data[:min],
    salary_max: grade_data[:max],
    premium_base: grade_data[:base],
    rate: 0.002,
    employee_ratio: 0.0,
    employer_ratio: 1.0,
    government_ratio: 0.0,
    effective_date: effective_date
  )
end

puts "完成建立2025年勞健保級距資料！"
puts "勞保級距: #{Insurance.by_type('labor').count} 筆"
puts "健保級距: #{Insurance.by_type('health').count} 筆"
puts "勞退級距: #{Insurance.by_type('labor_pension').count} 筆"
puts "職災險級距: #{Insurance.by_type('occupational_injury').count} 筆"
