QxgManage::Application.routes.draw do
  namespace :api do
    resources :chapters do
      collection do
        get :user_chapter,:user_achieve,:user_prop,:user_round,:user_rank,:user_card,:search_card,:list_card
        post :used_prop,:save_card,:delete_card
      end
    end
    resources :users do
      collection do
        get   :digest
        post  :login, :regist, :set_password
      end
    end
    resources :user_manages do
      get :selected_courses
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.



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
end