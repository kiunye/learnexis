module ApplicationHelper
  # Renders a DaisyUI-style badge. variant: info, warning, error, success, secondary, primary, etc.
  def badge_tag(text, variant: "neutral", **options)
    css = options.delete(:class).to_s
    badge_class = "badge badge-#{variant} #{css}".strip
    content_tag(:span, text, options.merge(class: badge_class))
  end

  def flash_class(type)
    case type.to_s
    when "notice", "success"
      "bg-green-900/90 border border-green-700 text-green-100"
    when "alert", "error"
      "bg-red-900/90 border border-red-700 text-red-100"
    when "warning"
      "bg-yellow-900/90 border border-yellow-700 text-yellow-100"
    else
      "bg-blue-900/90 border border-blue-700 text-blue-100"
    end
  end
end
