class HabitRecordsController < ApplicationController
  before_action :authenticate_user!

  def index
    @habit_records = HabitRecord.public_records.includes(:user).recent
  end

  def new
    @habit_record = current_user.habit_records.build
  end

  def create
    @habit_record = current_user.habit_records.build(habit_record_params)
    
    if @habit_record.save
      redirect_to habit_records_path, notice: '習慣記録を投稿しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def habit_record_params
    params.require(:habit_record).permit(:title, :content, :is_public, :recorded_at)
  end
end