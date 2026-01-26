module DashboardUpdates
  extend ActiveSupport::Concern

  private

  # Broadcast a refresh for a specific dashboard widget
  # Usage: broadcast_dashboard_widget(user_id, "widget_metrics_admin")
  def broadcast_dashboard_widget(user_id, widget_name)
    return unless user_id

    user = User.find_by(id: user_id)
    return unless user

    # Broadcast update to refresh the specific widget
    # The widget Turbo Frame will automatically fetch fresh content
    Turbo::StreamsChannel.broadcast_replace_to(
      "dashboard:#{user_id}",
      target: widget_name,
      partial: "dashboards/#{widget_name}",
      locals: { user: user }
    )
  end

  # Broadcast dashboard update to refresh all widgets for a user
  # This will be called from controllers when significant data changes
  def broadcast_dashboard_refresh(user_ids: nil)
    user_ids ||= [Current.user&.id].compact

    user_ids.each do |user_id|
      # Clear cache first
      clear_dashboard_cache_for_user(user_id)

      # Broadcast refresh signal - widgets will refetch via their Turbo Frames
      # In a real implementation, you might want to broadcast specific widget updates
      Turbo::StreamsChannel.broadcast_action_to(
        "dashboard:#{user_id}",
        action: :refresh,
        target: "dashboard_content"
      )
    end
  end

  # Clear dashboard cache for a specific user
  def clear_dashboard_cache_for_user(user_id)
    user = User.find_by(id: user_id)
    return unless user

    # Clear cache entries for this user
    # Note: delete_matched may not be available in all cache stores
    if Rails.cache.respond_to?(:delete_matched)
      cache_pattern = "dashboard/#{user_id}/#{user.role}/*"
      Rails.cache.delete_matched(cache_pattern)
    else
      # Fallback: clear with a known pattern
      # In production with Solid Cache, entries expire automatically
      Rails.cache.delete("dashboard/#{user_id}/#{user.role}/#{Time.current.to_i / 300}")
    end
  end

  # Clear dashboard cache for multiple users (e.g., when admin makes a change)
  def clear_dashboard_cache(user_ids: nil)
    user_ids ||= User.pluck(:id)

    user_ids.each do |user_id|
      clear_dashboard_cache_for_user(user_id)
    end
  end
end
