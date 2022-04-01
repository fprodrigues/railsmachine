Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "home#index"
  post "/home/import", to: "home#import"
  post "/home/classify", to: "home#classify"

  match 'download', to: 'home#download', as: 'download', via: :get
end
