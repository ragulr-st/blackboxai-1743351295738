Rails.application.routes.draw do
  root 'contracts#index'
  resources :contracts do
    member do
      post 'process_prompt'
    end
  end
end
