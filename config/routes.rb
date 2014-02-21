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
        post :search, :uploadfile
      end
      member do
        get :view #编辑题目加载原题
        post :edit
      end
      resources :branch_questions
    end
  end
  resources :users
  get "/", :to => "sessions#new"
  post "/login", :to => "sessions#create"
  get '/logout', :to => "sessions#destroy"
  get '/remove_knowledge_card/:question_id', :to => "questions#remove_knowledge_card", :as => "remove_knowledge_card"
  post '/md_to_html', :to => "knowledge_cards#md_to_html"
  post '/upload_kcard/:kcard_id', :to => "knowledge_cards#upload_kcard"
  root :to => 'courses#index'

  # See how all your routes lay out with "rake routes"

  namespace :api do
    resources :chapters do
      collection do
        get :user_chapter,:user_achieve,:user_prop,:user_round,:user_rank,:user_card,:user_cards,:list_card
        post :used_prop,:save_card,:delete_card,:add_tag_to_card,:add_remark_to_card,:user_add_tag,:user_update_tag,
          :user_del_tag, :add_wrong_question, :buy_card_slot, :save_user_course,:save_achieve,:user_delete_course,
          :rouns_used_prop
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
          :everyday_tasks, :set_task_day,:achieve_points_ranking,:add_friend,:course_to_chapter,:course_level,:return_round_ids, :weibo_list, :contact_list
        post :bind_weibo, :remove_wrong_questions, :after_everyday_tasks
      end
    end
  end

end


