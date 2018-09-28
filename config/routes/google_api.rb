scope '-' do
  namespace :google_api do
    resource :auth, only: [], controller: :authorizations, constraints: proc { false } do  # patched
      match :callback, via: [:get, :post]
    end
  end
end
