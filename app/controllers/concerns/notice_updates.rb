module NoticeUpdates
  extend ActiveSupport::Concern

  included do
    after_action :broadcast_notice_update, only: [ :create, :update, :destroy ]
  end

  private

  def broadcast_notice_update
    return unless @notice.persisted? || action_name == "destroy"

    # Broadcast to all users for public notices
    ActionCable.server.broadcast("notice_channel", {
      action: action_name.to_sym,
      notice: action_name == "destroy" ? { id: params[:id] } : @notice
    })

    # Also broadcast to specific role channels based on target audience (skip when notice is for "all")
    unless action_name == "destroy" || @notice.target_audience.nil?
      ActionCable.server.broadcast("notice_channel_#{@notice.target_audience_symbol}", {
        action: action_name.to_sym,
        notice: action_name == "destroy" ? { id: params[:id] } : @notice
      })
    end
  end
end
