Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token

  # Dashboard (role-based, will be implemented in Task 6)
  get "dashboard", to: "dashboards#show", as: :dashboard

  # Root redirects to sign in for now (will redirect to dashboard when authenticated)
  root "sessions#new"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
