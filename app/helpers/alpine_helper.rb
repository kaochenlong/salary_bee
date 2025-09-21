module AlpineHelper
  # Generate x-data attribute with proper JSON formatting
  def alpine_data(data = {})
    { "x-data" => data.is_a?(String) ? data : data.to_json }
  end

  # Generate @click attribute
  def alpine_click(action)
    { "@click" => action }
  end

  # Generate @submit attribute for forms
  def alpine_submit(action)
    { "@submit.prevent" => action }
  end

  # Generate x-show attribute
  def alpine_show(condition)
    { "x-show" => condition }
  end

  # Generate x-if attribute (requires template tag)
  def alpine_if(condition)
    { "x-if" => condition }
  end

  # Generate x-for attribute (requires template tag)
  def alpine_for(expression)
    { "x-for" => expression }
  end

  # Generate x-model attribute for two-way binding
  def alpine_model(property)
    { "x-model" => property }
  end

  # Generate x-text attribute
  def alpine_text(expression)
    { "x-text" => expression }
  end

  # Generate x-html attribute
  def alpine_html(expression)
    { "x-html" => expression }
  end

  # Generate x-bind attribute
  def alpine_bind(attribute, value)
    { "x-bind:#{attribute}" => value }
  end

  # Generate x-on attribute for custom events
  def alpine_on(event, action)
    { "x-on:#{event}" => action }
  end

  # Generate x-transition attributes
  def alpine_transition(options = {})
    attrs = {}
    if options[:enter]
      attrs["x-transition:enter"] = options[:enter]
    end
    if options[:leave]
      attrs["x-transition:leave"] = options[:leave]
    end
    attrs["x-transition"] = "" if attrs.empty?
    attrs
  end

  # Generate x-cloak attribute (to prevent FOUC)
  def alpine_cloak
    { "x-cloak" => "" }
  end
end
