module Admin
  class UsersController < Admin::BaseController
    def index
      @users = User.order(created_at: :desc)
    end

    def destroy
      @user = User.find(params[:id])
      
      if @user.admin?
        redirect_to admin_users_path, alert: '管理者ユーザーは削除できません。'
        return
      end

      @user.destroy
      redirect_to admin_users_path, notice: 'ユーザーを削除しました。'
    end
  end
end
