class HomeController < ApplicationController
  layout "marketing"
  allow_unauthenticated_access only: %i[index]

  def index
    # Redirect authenticated users to dashboard
    if authenticated?
      redirect_to dashboard_path
    end
    # Marketing homepage - accessible without authentication
  end
end
