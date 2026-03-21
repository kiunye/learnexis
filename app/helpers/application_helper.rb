module ApplicationHelper
  # Best link for "mark attendance today" (first accessible classroom), else classrooms index.
  def mark_attendance_quick_path
    user = Current.user
    return classrooms_path unless user&.admin? || user&.teacher?

    classroom = Pundit.policy_scope!(user, Classroom).order(:name).first
    if classroom
      mark_classroom_attendances_path(classroom, date: Date.current)
    else
      classrooms_path
    end
  end

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
