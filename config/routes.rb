Rails.application.routes.draw do
  resources :snippets
  resources :users
  # get 'welcome' => 'landing#landingpage'
  root 'landing#landingpage'
  get '/index' => 'display#showIndex'
  get '/login' => 'display#showLogin'
  get '/lock' => 'display#showLock'
  get '/register' => 'users#new'
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

end
