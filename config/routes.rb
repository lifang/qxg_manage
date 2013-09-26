<<<<<<< HEAD
QxgManage::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'

  namespace :api do
    resources :users do
      collection do
      get :digest
      post  :login, :regist, :set_password
      end
    end
    resources :user_manages do
      collection do
        get :selected_courses
      end
    end
  end
end
=======
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
      post  :login, :regist, :set_password
      end
    end
    resources :user_manages do
      get :selected_courses
    end
  end
end
>>>>>>> 121ae6dc3ce5060c9a82847c8505611682f8b839
