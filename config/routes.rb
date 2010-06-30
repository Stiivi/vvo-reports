Vvo::Application.routes.draw do |map|
  # Reports
  resources :reports
  match '/reports/:report/:id', :to => 'reports#show', :as => 'report'
  
  # Facts
  resources :facts
  
  # Root path
  root :to => "reports#index"
end
