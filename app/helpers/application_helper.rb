module ApplicationHelper
  def flash_css_class(type)
    case type.to_s
    when "alert"
      "text-red-600 bg-red-50 border border-red-200 p-4 rounded"
    when "notice"
      "text-green-600 bg-green-50 border border-green-200 p-4 rounded"
    else
      "text-gray-600 bg-gray-50 border border-gray-200 p-4 rounded"
    end
  end
end
