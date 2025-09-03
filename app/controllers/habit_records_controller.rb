class HabitRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_habit
  before_action :set_habit_record, only: [:show, :edit, :update, :destroy]

  def index
    @habit_records = @habit.habit_records.includes(:user).recent
  end

  def show
  end

  def new
    @habit_record = @habit.habit_records.build(recorded_at: Date.current)
  end

  def create
    @habit_record = @habit.habit_records.build(habit_record_params)
    @habit_record.user = current_user

    if @habit_record.save
      redirect_to [@habit, @habit_record], notice: '習慣の記録が正常に作成されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @habit_record.update(habit_record_params)
      redirect_to [@habit, @habit_record], notice: '習慣の記録が正常に更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @habit_record.destroy
    redirect_to @habit, notice: '習慣の記録が削除されました。'
  end

  private

  def set_habit
    @habit = current_user.habits.find(params[:habit_id])
  end

  def set_habit_record
    @habit_record = @habit.habit_records.find(params[:id])
  end

  def habit_record_params
    params.require(:habit_record).permit(:recorded_at, :note, :completed)
  end
end