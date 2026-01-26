class DashboardsController < ApplicationController
  include DashboardUpdates

  def show
    # All authenticated users can access their dashboard
    # Authorization is handled at the controller level via authentication
    
    # Cache dashboard data for 5 minutes (will be populated with real data in Task 7)
    # Cache key includes user role to ensure role-specific content is cached separately
    cache_key = "dashboard/#{Current.user&.id}/#{Current.user&.role}/#{Time.current.to_i / 300}"
    
    @dashboard_data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      {
        # Placeholder data - will be replaced with real queries in Task 7
        total_students: 0,
        total_classrooms: 0,
        pending_fees: 0,
        attendance_rate: 0,
        monthly_revenue: 0
      }
    end
  end
end
