class Users::SessionsController < Devise::SessionsController
  # Skip authentication for destroy action (logout)
  skip_before_action :authenticate_user!, only: [:destroy]

  protected

  # Redirect to root path after logout
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end
end