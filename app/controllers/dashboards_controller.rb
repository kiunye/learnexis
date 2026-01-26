class DashboardsController < ApplicationController
  def show
    # All authenticated users can access their dashboard
    # Authorization is handled at the controller level via authentication
    # Role-specific content will be implemented in Task 6
  end
end
