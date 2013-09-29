QxgManage::Application.routes.draw do



  resources :courses do
    member do
      get :verify #审核课程
    end
    resources :chapters do
      resources :rounds
    end
    resources :cardbag_tags
    resources :props
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

  root :to => 'courses#index'

  # See how all your routes lay out with "rake routes"

  namespace :api do
    resources :users do
      collection do
      get :digest
      post  :login, :regist, :set_password, :update_user_date, :upload_head_img
      end
    end
    resources :user_manages do
      collection do
        get "selected_courses", "search_course", "search_single_course"
      end
      
    end
  end
end
