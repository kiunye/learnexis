class NoticeChannel < ApplicationCable::Channel
  def subscribed
    # Stream notices based on user's role and target audience
    if current_user.admin?
      # Admins see all notices
      stream_from "notice_channel"
    else
      # Other users see notices targeted to their role or "all"
      stream_from "notice_channel_#{current_user.role}"
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  # Methods to broadcast notices
  def self.broadcast_create(notice)
    ActionCable.server.broadcast("notice_channel", {
      action: "create",
      notice: notice_attributes(notice)
    })

    # Also broadcast to specific role channels based on target audience
    # Notice: target_audience is nil for 'all', 0 for teachers, 1 for parents, etc.
    unless notice.target_audience.nil?
      ActionCable.server.broadcast("notice_channel_#{notice.target_audience_symbol}", {
        action: "create",
        notice: notice_attributes(notice)
      })
    end
  end

  def self.broadcast_update(notice)
    ActionCable.server.broadcast("notice_channel", {
      action: "update",
      notice: notice_attributes(notice)
    })

    # Also broadcast to specific role channels based on target audience
    # Notice: target_audience is nil for 'all', 0 for teachers, 1 for parents, etc.
    unless notice.target_audience.nil?
      ActionCable.server.broadcast("notice_channel_#{notice.target_audience_symbol}", {
        action: "update",
        notice: notice_attributes(notice)
      })
    end
  end

  def self.broadcast_destroy(notice_id)
    ActionCable.server.broadcast("notice_channel", {
      action: "destroy",
      notice_id: notice_id
    })
  end

  private

  def self.notice_attributes(notice)
    {
      id: notice.id,
      title: notice.title,
      content: notice.content,
      priority: notice.priority,
      notice_type: notice.notice_type,
      target_audience: notice.target_audience,
      target_audience_symbol: notice.target_audience_symbol,
      grade_levels: notice.grade_levels,
      grade_levels_array: notice.grade_levels_array,
      published_at: notice.published_at,
      expires_at: notice.expires_at,
      active: notice.active,
      created_at: notice.created_at,
      updated_at: notice.updated_at,
      author: notice.author ? {
        id: notice.author.id,
        email_address: notice.author.email_address,
        first_name: notice.author.first_name,
        last_name: notice.author.last_name,
        role: notice.author.role,
        full_name: notice.author.full_name
      } : nil
    }
  end
end
