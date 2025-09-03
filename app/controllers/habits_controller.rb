class HabitsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_habit, only: [:show, :edit, :update, :destroy]

  def index
    @habits = current_user.habits.recent
  end

  def calendar
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    @habits = current_user.habits.where(active: true)
    
    # Get all habit records for the current month
    start_date = @date.beginning_of_month.beginning_of_week
    end_date = @date.end_of_month.end_of_week
    @habit_records = current_user.habit_records
                                 .includes(:habit)
                                 .where(recorded_at: start_date..end_date)
                                 .group_by(&:recorded_at)
  end

  def show
  end

  def new
    @habit = current_user.habits.build
  end

  def create
    @habit = current_user.habits.build(habit_params)

    if @habit.save
      redirect_to @habit, notice: '習慣が正常に作成されました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @habit.update(habit_params)
      redirect_to @habit, notice: '習慣が正常に更新されました。'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @habit.destroy
    redirect_to habits_path, notice: '習慣が削除されました。'
  end

  private

  def set_habit
    @habit = current_user.habits.find(params[:id])
  end

  def habit_params
    params.require(:habit).permit(:title, :description, :active)
  end
end
