# encoding: utf-8

#  _     _              _          
# | |___| |_ _ ___ _  _| |_ ___ ___
# | / _ \ | '_/ _ \ || |  _/ -_)_ /
# |_\___/_|_| \___/\_,_|\__\___/__|

Vvo::Application.routes.draw do |map|
  resources :reports
  resources :dumps
  resources :facts
  
  # Root path
  root :to => "reports#index"
end
