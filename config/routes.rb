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
  
  # Pages
  resources :pages
  
  # Root path
  root :to => "reports#index"
end
