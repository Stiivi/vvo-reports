Vvo::Application.routes.draw do |map|
 resources :reports
 resources :organisations
 root :to => "reports#index"
end
