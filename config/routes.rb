QxgManage::Application.routes.draw do

  # The priority is based upon order of creation:
  # first created -> highest priority.

  resources :courses do
    member do
      get :verify #审核课程
    end
    resources :chapters do
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
    collection do
      post :uploadfile
    end
    member do
      get :verify #审核关卡
    end
    resources :questions do
      collection do
        post :search
      end
      resources :branch_questions
    end
  end
  resources :users
  get "/", :to => "sessions#new"
  post "/login", :to => "sessions#create"
  get '/logout', :to => "sessions#destroy"
  get '/remove_knowledge_card/:question_id', :to => "questions#remove_knowledge_card", :as => "remove_knowledge_card"
  root :to => 'courses#index'

  # See how all your routes lay out with "rake routes"

  namespace :api do
    resources :chapters do
      collection do
        get :user_chapter,:user_achieve,:user_prop,:user_round,:user_rank,:user_card,:user_cards,:list_card
        post :used_prop,:save_card,:delete_card,:add_tag_to_card,:add_remark_to_card,:user_add_tag,:user_update_tag,
          :user_del_tag, :add_wrong_question, :buy_card_slot
      end
    end
    resources :users do
      collection do
        get   :digest
        post  :login, :regist, :set_password, :update_user_date, :upload_head_img, :set_email
      end
    end
    resources :user_manages do
      collection do
        get :selected_courses, :search_course, :search_single_course, :props_list, :buy_prop,
          :everyday_tasks, :set_task_day,:achieve_points_ranking,:add_friend,:course_to_chapter
        post :contact_list, :weibo_list,:bind_weibo
      end
    end
  end

end


