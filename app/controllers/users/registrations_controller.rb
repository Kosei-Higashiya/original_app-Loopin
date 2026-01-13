module Users
  class RegistrationsController < Devise::RegistrationsController
    # 本番確認用に CSRF チェックを一時的にスキップ
    skip_before_action :verify_authenticity_token, only: [:create]

    def create
      super
    end

    def destroy
      # ログインしているユーザーのみ削除を許可
      if user_signed_in?
        super
      else
        redirect_to root_path, alert: 'アカウントを削除するにはログインが必要です。'
      end
    end
  end
end
