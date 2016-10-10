GradeCraft::Application.routes.draw do

  mount RailsEmailPreview::Engine, at: "emails" if Rails.env.development?

  require "admin_constraint"

  #1. Analytics & Charts
  #2. Announcements
  #3. Assignments, Submissions, Grades
  #4. Assignment Types
  #5. Assignment Type Weights
  #6. Badges
  #7. Challenges
  #8. Integrations
  #9. Courses
  #10. Groups
  #11. Informational Pages
  #12. Grade Schemes
  #13. Teams
  #14. Users
  #15. User Auth
  #16. Uploads
  #17. Events
  #18. Predictor
  #19. Exports

  #1. Analytics & Charts
  namespace :analytics do
    get :staff
    get :students
    get :all_events
    get :login_events
    get :login_role_events
    get :role_events
    get :all_pageview_events
    get :all_role_pageview_events
    get :all_user_pageview_events
    get :pageview_events
    get :role_pageview_events
    get :user_pageview_events
  end

  post "analytics_events/predictor_event"
  post "analytics_events/tab_select_event"

  #2. Announcements
  resources :announcements, except: [:destroy, :edit, :update]

  #3. Assignments, Submissions, Grades
  namespace :assignments do
    resources :importers, param: :provider_id, only: :index do
      get "/courses/:id/assignments", action: :assignments, as: :assignments
      post "/courses/:id/assignments/import", action: :assignments_import,
        as: :assignments_import
      post "/assignments/:id/refresh", action: :refresh_assignment, as: :refresh_assignment
      post "/assignments/:id/update", action: :update_assignment, as: :update_assignment
    end
  end

  resources :assignments do
    collection do
      post :sort
      get :feed
      get :settings
      post "copy" => "assignments#copy"
      get "export_structure"
    end

    # routes for all grades that are associated with an assignment
    # single resources should go directly on the grades controller
    resources :grades, only: [:index], module: :assignments do
      collection do
        get :export
        get :export_earned_levels
        get :mass_edit
        put :mass_update
        get :edit_status
        put :update_status
        post :self_log
        delete :delete_all
      end
    end

    namespace :grades do
      resources :importers, param: :provider_id, only: [:index, :show] do
        get :download
        post :upload
        get "/courses/:id/assignments", action: :assignments, as: :assignments
        get "/courses/:id/grades", action: :grades, as: :grades
        post "/courses/:id/grades/import", action: :grades_import, as: :grades_import
      end
    end

    resources :groups, only: [], module: :assignments do
      get :grade, on: :member
      put :graded, on: :member
    end

    resources :students, only: [], module: :assignments do
      post :grade
    end

    resources :submissions, except: :index

    resource :rubrics, except: [:edit, :index, :new] do
      get :design, on: :collection
      get :index_for_copy, on: :collection
      post :copy, on: :collection
      get :export, on: :collection
    end
  end

  resources :grades, only: [:show, :destroy, :edit, :update] do
    member do
      post :exclude
      post :feedback_read
      post :include
    end
  end

  resources :submission_files, only: [] do
    get :download
  end

  resources :unlock_states, only: [:create, :destroy, :update] do
    member do
      post :manually_unlock
    end
  end
  resources :unlock_conditions, only: [:create, :destroy, :update]

  resources :criteria, only: [:create, :destroy, :update] do
    put :update_order, on: :collection
  end

  resources :levels, only: [:create, :destroy, :update]
  resources :level_badges, only: [:create, :destroy]

  #4. Assignment Types
  resources :assignment_types, except: [:show] do
    get :all_grades, on: :member
    get :export_scores, on: :member
    get :export_all_scores, on: :collection
    post :sort, on: :collection
  end

  #5. Assignment Type Weights
  resources :assignment_type_weights, only: [:index]

  #6. Badges
  resources :badges do
    post :sort, on: :collection
    get "export_structure", on: :collection
    resources :earned_badges do
      get :mass_edit, on: :collection
      post :mass_earn, on: :collection
    end
  end

  #7. Challenges
  resources :challenges do
    resources :challenge_grades, only: [:new, :create], module: :challenges do
      collection do
        post :edit_status
        put :update_status
        get :mass_edit
        put :mass_update
      end
    end
  end

  resources :challenge_grades, except: [:index, :new, :create]

  #8. Integrations

  resources :integrations, only: [:create, :index] do
    resources :courses, only: [:create, :destroy, :index], module: :integrations
  end

  #9. Courses

  resources :courses do
    post :copy, on: :collection
    get :badges, on: :member
    get :change, on: :member
    resources :badges do
      resources :earned_badges do
        get :confirm_earned, on: :member
      end
    end
  end

  controller :courses do
    get :course_details
    get :custom_terms
    get :multiplier_settings
    get :player_settings
    get :student_onboarding_setup
  end

  resources :course_memberships, only: [:create, :delete, :destroy]
  get :course_creation_wizard, to: "courses#course_creation_wizard"

  #10. Groups
  resources :groups

  #11. Informational Pages
  controller :info do
    get :dashboard
    get :predictor
    get :earned_badges
    get :export_earned_badges
    get :final_grades
    get :gradebook
    get :submissions
    get :grading_status
    get :multiplied_gradebook
    get :multiplier_choices
    get :per_assign
    get :research_gradebook
    get :timeline_events
    get :top_10
  end

  controller :pages do
    get :brand_and_style_guidelines
    get :features
    get :our_team, to: "pages#team"
    get :press
    get :research
    get :um_pilot
  end

  #12. Grade Schemes
  resources :grade_scheme_elements, only: [:index, :edit, :show, :update] do
    collection do
      get :mass_edit
      put :mass_update
      get :export_structure
    end
  end

  #13. Teams
  resources :teams

  #14. Users
  %w{students gsis professors admins}.each do |role|
    get "users/#{role}/new" => "users#new", as: "new_#{role.singularize}",
      role: role.singularize
  end

  resources :users, except: :show do
    member do
      get :activate
      post :activate, action: :activated
      post :flag
    end
    collection do
      get :edit_profile
      put :update_profile
      get :import
      post :upload
    end
  end

  get :leaderboard, to: "students#leaderboard"

  resources :students, only: [:index, :show] do
    resources :badges, only: [:index, :show], module: :students
    resources :assignment_type_weights, only: [:index], module: :students
    member do
      get :grade_index
      get :recalculate
    end
    collection do
      get :autocomplete_student_name
      get :flagged
    end
  end

  resources :staff, only: [:index, :show]

  #15. User Auth
  post "auth/lti/callback", to: "user_sessions#lti_create"
  get "/auth/:provider/callback", to: "authorizations#create"
  get "auth/failure", to: "pages#auth_failure", as: :auth_failure

  get :login, to: "user_sessions#new", as: :login
  get :logout, to: "user_sessions#destroy", as: :logout
  get :reset, to: "user_sessions#new"
  resources :user_sessions, only: [:new, :create, :destroy]
  resources :passwords, path_names: { new: "reset" },
    except: [:destroy, :index, :show]

  get "impersonate_student/:student_id", to: "user_sessions#impersonate_student", as: :student_preview
  get "exit_student_impersonation", to: "user_sessions#exit_student_impersonation"

  #SAML
  get "saml/init"
  post "saml/consume"
  get "saml/metadata"
  get "saml/logout"

  get "lti/:provider/launch", to: "lti#launch", as: :launch_lti_provider

  #16. Uploads
  resource :uploads, only: [] do
    get :remove
  end

  #17. Events
  resources :events

  #18. API Calls

  namespace :api, defaults: { format: :json } do

    resources :assignments, only: [] do
      resources :criteria, only: :index
      resources :students, only: [] do
        resources :criteria, only: [] do
          member do
            put :update_fields, to: 'criterion_grades#update_fields'
          end
        end
        resources :criterion_grades, only: :index
        get "grade", to: 'grades#show'
        put "criterion_grades", to: "criterion_grades#update"
      end
      resources :groups, only: [] do
        get 'grades', to: 'grades#group_index'
        put "criterion_grades", to: "criterion_grades#group_update"
        get 'criterion_grades', to: 'criterion_grades#group_index'
      end
    end

    resources :assignments, only: :index
    resources :assignment_types, only: :index do
      resources :assignment_type_weights, only: :create
    end
    resources :badges, only: :index
    resources :earned_badges, only: [:create, :destroy]
    resources :grades, only: :update do
      resources :earned_badges, only: :create, module: :grades do
        delete :delete_all, on: :collection
      end
      resources :grade_files, only: [:create, :destroy], module: :grades
    end
    resources :grade_scheme_elements, only: :index
    resources :levels, only: :update

    # Student Predictor View, Predictor Preview
    resources :predicted_earned_badges, only: [:update]
    resources :predicted_earned_challenges, only: [:index, :update]
    resources :predicted_earned_grades, only: [:index, :update]

    # Instructor View of Student's Predictor
    resources :students, only: [], module: :students do
      resources :badges, only: :index
      get "assignment_types", to: "assignment_types#index"
      get "predicted_earned_challenges", to: "predicted_earned_challenges#index"
      get "predicted_earned_grades", to: "predicted_earned_grades#index"
    end
  end

  #19. Exports
  resources :downloads, only: :index

  resources :submissions_exports, only: [:create, :destroy] do
    member do
      get :download
      get '/secure_download/:secure_token_uuid/secret_key/:secret_key',
        action: "secure_download", as: "secure_download"
    end
  end

  resources :course_analytics_exports, only: [:create, :destroy] do
    member do
      get :download
      get '/secure_download/:secure_token_uuid/secret_key/:secret_key',
        action: "secure_download", as: "secure_download"
    end
  end

  # root, bro
  root to: "pages#home"
end
