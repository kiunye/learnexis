module NoticeUpdates
  extend ActiveSupport::Concern

  included do
    after_action :broadcast_notice_update, only: [ :create, :update, :destroy ]
  end

  private

  def broadcast_notice_update
    return unless @notice.persisted? || action == :destroy

    # Broadcast to all users for public notices
    ActionCable.server.broadcast("notice_channel", {
      action: action.to_sym,
      notice: action == :destroy ? { id: params[:id] } : @notice
    })

    # Also broadcast to specific role channels based on target audience
    unless action == :destroy || @notice.target_audience == "all"
      ActionCable.server.broadcast("notice_channel_#{@notice.target_audience}", {
        action: action.to_sym,
        notice: action == :destroy ? { id: params[:id] } : @notice
      })
    end
  end
end
