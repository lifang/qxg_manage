QxgManage::Application.routes.draw do



  resources :courses do
    member do
      get :verify
    end
    resources :chapters do
      resources :rounds
    end
  end

  root :to => 'courses#index'

  # See how all your routes lay out with "rake routes"

  namespace :api do
    resources :users do
      collection do
        get :login, :digest
        post :regist, :set_password
      end
    end
  end
end
