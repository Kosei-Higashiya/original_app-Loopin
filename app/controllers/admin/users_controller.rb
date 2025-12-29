module Admin
  class UsersController < Admin::BaseController
    def index
      @users = User.includes(:posts, :habits).order(created_at: :desc)
    end

    def destroy
      @user = User.find(params[:id])
      
      if @user.admin?
        redirect_to admin_users_path, alert: '管理者ユーザーは削除できません。'
        return
      end

      if @user == current_user
        redirect_to admin_users_path, alert: '自分自身を削除することはできません。'
        return
      end

      if @user.destroy
        redirect_to admin_users_path, notice: 'ユーザーを削除しました。'
      else
        redirect_to admin_users_path, alert: 'ユーザーの削除に失敗しました。'
      end
    end
  end
end
