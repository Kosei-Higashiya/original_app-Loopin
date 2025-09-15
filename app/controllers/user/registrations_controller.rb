class Users::RegistrationsController < Devise::RegistrationsController
  # 本番確認用に CSRF チェックを一時的にスキップ
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    Rails.logger.debug "=== RegistrationsController#create called ==="
    Rails.logger.debug "=== sign_up_params: #{sign_up_params.inspect} ==="

    super

    Rails.logger.debug "=== after super, resource.persisted? #{resource.persisted?} ==="
  end
end
