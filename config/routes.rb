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
        post  :login, :regist, :set_password, :update_user_date, :upload_head_img
      end
    end
    resources :user_manages do
      get "selected_courses", "search_course", "search_single_course"
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.



  resources :courses do
    member do
      get :verify #审核课程
    end
    resources :chapters do
      collection do
        post :uploadfile
      end
      resources :rounds
    end
    resources :cardbag_tags do
      collection do
        post :search  #搜索标签
      end
    end
    resources :props
    resources :knowledge_cards
  end

  resources :chapters do
    member do
      get :verify #审核章节
    end
  end

  resources :rounds do
    member do
      get :verify #审核关卡
    end
    resources :questions do
      resources :branch_questions
    end
  end
  get "/", :to => "sessions#new"
  post "/login", :to => "sessions#create"
  get '/logout', :to => "sessions#destroy"
  get '/remove_knowledge_card/:question_id', :to => "questions#remove_knowledge_card", :as => "remove_knowledge_card"
  root :to => 'courses#index'

  # See how all your routes lay out with "rake routes"
end


