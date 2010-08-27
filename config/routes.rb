# encoding: utf-8

#  _     _              _          
# | |___| |_ _ ___ _  _| |_ ___ ___
# | / _ \ | '_/ _ \ || |  _/ -_)_ /
# |_\___/_|_| \___/\_,_|\__\___/__|

Vvo::Application.routes.draw do |map|
  # Main paths
  resources :reports
  resources :lists
  resources :facts
  resources :dimensions do
    member do
      post :search
      get :search
    end
  end
  
  # Cut
  resource :cut
  
  # Pages
  resources :pages
  
  # Root path
  root :to => "reports#index"
  
  match '/:anything', :to => "global#not_found", :constraints => { :anything => /.*/ }
end
