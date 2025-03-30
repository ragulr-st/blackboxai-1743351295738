Rails.application.routes.draw do
  root 'contracts#index'
  resources :contracts
end
