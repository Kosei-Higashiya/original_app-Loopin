class HabitRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_habit_record, only: [:show, :edit, :update, :destroy]
  before_action :authorize_user!, only: [:show, :edit, :update, :destroy]

  def index
    @habit_records = HabitRecord.public_records.includes(:user).recent
    @my_records = current_user.habit_records.recent if user_signed_in?
  end

  def show
  end

  def new
    @habit_record = current_user.habit_records.build
  end

  def create
    @habit_record = current_user.habit_records.build(habit_record_params)
    
    if @habit_record.save
      redirect_to @habit_record, notice: '習慣記録を投稿しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @habit_record.update(habit_record_params)
      redirect_to @habit_record, notice: '習慣記録を更新しました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @habit_record.destroy
    redirect_to habit_records_path, notice: '習慣記録を削除しました。'
  end

  private

  def set_habit_record
    @habit_record = HabitRecord.find(params[:id])
  end

  def authorize_user!
    unless @habit_record.user == current_user || @habit_record.is_public?
      redirect_to habit_records_path, alert: 'アクセス権限がありません。'
    end
  end

  def habit_record_params
    params.require(:habit_record).permit(:title, :content, :is_public, :recorded_at)
  end
end