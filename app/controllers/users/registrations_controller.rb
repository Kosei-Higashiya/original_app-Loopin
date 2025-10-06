module Users
  class RegistrationsController < Devise::RegistrationsController
    # 本番確認用に CSRF チェックを一時的にスキップ
    skip_before_action :verify_authenticity_token, only: [:create]

    def create
      Rails.logger.debug '=== RegistrationsController#create called ==='
      Rails.logger.debug { "=== sign_up_params: #{sign_up_params.inspect} ===" }

      super

      Rails.logger.debug { "=== after super, resource.persisted? #{resource.persisted?} ===" }
    end

    def destroy
      Rails.logger.debug '=== RegistrationsController#destroy called ==='
      Rails.logger.debug { "=== current_user: #{current_user.inspect} ===" }

      # Ensure user is authenticated before destroying account
      if user_signed_in?
        super
      else
        redirect_to root_path, alert: 'アカウントを削除するにはログインが必要です。'
      end
    end
  end
end
