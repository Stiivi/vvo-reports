Vvo::Application.routes.draw do |map|
 resources :reports
 root :to => "reports#index"
end
