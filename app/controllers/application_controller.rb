class ApplicationController < ActionController::Base
  include BadgeNotifications

  before_action :configure_permitted_parameters, if: :devise_controller?
  after_action :set_badge_notification_flash, if: :user_signed_in?, unless: :devise_controller?

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end
end
