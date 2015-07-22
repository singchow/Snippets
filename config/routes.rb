Rails.application.routes.draw do
  resources :snippets

  get '/dashboard' => 'snippets#index'

end
