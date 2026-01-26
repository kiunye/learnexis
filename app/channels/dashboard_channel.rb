class DashboardChannel < ApplicationCable::Channel
  def subscribed
    # Subscribe to dashboard updates for the current user
    # Each user gets their own stream based on their ID
    stream_from "dashboard:#{current_user.id}" if current_user
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
