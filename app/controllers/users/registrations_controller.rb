# Custom Devise registrations controller to handle badge notifications safely
class Users::RegistrationsController < Devise::RegistrationsController
  protected

  # Override after_sign_up_path_for to handle badge notifications after successful registration
  def after_sign_up_path_for(resource)
    # Award initial badges
    begin
      newly_earned_badges = resource.check_and_award_badges
      set_badge_notification(newly_earned_badges) if newly_earned_badges.any?
    rescue => e
      Rails.logger.error "[Registration] Error awarding badges after signup for user #{resource.id}: #{e.message}"
      # Don't fail registration due to badge errors
    end
    
    super
  end
  
  # Override after_inactive_sign_up_path_for to handle confirmation case
  def after_inactive_sign_up_path_for(resource)
    # Award initial badges even for unconfirmed users
    begin
      newly_earned_badges = resource.check_and_award_badges
      set_badge_notification(newly_earned_badges) if newly_earned_badges.any?
    rescue => e
      Rails.logger.error "[Registration] Error awarding badges after inactive signup for user #{resource.id}: #{e.message}"
      # Don't fail registration due to badge errors
    end
    
    super
  end
end