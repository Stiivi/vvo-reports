Vvo::Application.routes.draw do |map|
 resources :reports
 resources :facts
 root :to => "reports#index"
end
