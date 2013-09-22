QxgManage::Application.routes.draw do



  resources :courses do
    member do
      get :verify
    end
    resources :chapters do
      resources :rounds
    end
  end

  get "/", :to => "sessions#new"
  post "/login", :to => "sessions#create"
  get '/logout', :to => "sessions#destroy"

  root :to => 'courses#index'

  # See how all your routes lay out with "rake routes"

  namespace :api do
    resources :users do
      collection do
      get :digest
      post  :login, :regist, :set_password
      end
    end
    resources :user_manages do
      get :selected_courses
    end
  end
end
