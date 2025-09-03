class HabitsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_habit, only: [:show, :edit, :update, :destroy, :individual_calendar, :toggle_record_for_date]

  def index
    @habits = current_user.habits.recent
  end

  def show
  end

  def individual_calendar
    @habit_records = @habit.habit_records.includes(:habit)
  end

  def toggle_record_for_date
    date = Date.parse(params[:date])
    record = @habit.habit_records.find_by(recorded_at: date, user: current_user)
    
    if record
      # Toggle completion status
      record.update!(completed: !record.completed)
    else
      # Create new record with completed status
      @habit.habit_records.create!(
        user: current_user,
        recorded_at: date,
        completed: true
      )
    end

    respond_to do |format|
      format.json { render json: { success: true } }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.json { render json: { success: false, error: e.message }, status: :unprocessable_entity }
    end
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
