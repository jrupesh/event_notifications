# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html
# resources :watchers do
#   member do
#     get 'preview_watchers'
#   end
# end
match 'issues/:id/preview_watchers', :to => 'watchers#preview_watchers', :as => 'preview_watchers', :via => :get