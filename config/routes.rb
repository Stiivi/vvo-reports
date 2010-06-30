Vvo::Application.routes.draw do |map|
  # General routes
  resources :reports
  resources :facts
  
  # Entities
  resources :suppliers
  resources :procurers
  
  # Root path
  root :to => "reports#index"
end
