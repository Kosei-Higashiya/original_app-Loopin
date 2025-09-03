class HabitRecordsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_habit
  before_action :set_habit_record, only: [:show, :update, :destroy]

  # GET /habits/:habit_id/habit_records/:id
  def show
    respond_to do |format|
      format.html
      format.json { render json: @habit_record }
    end
  end

  # POST /habits/:habit_id/habit_records
  def create
    @habit_record = @habit.habit_records.build(habit_record_params)
    @habit_record.user = current_user

    respond_to do |format|
      if @habit_record.save
        format.html { redirect_to calendar_habit_path(@habit), notice: '記録が作成されました。' }
        format.json { render json: @habit_record, status: :created }
      else
        format.html { redirect_to calendar_habit_path(@habit), alert: '記録の作成に失敗しました。' }
        format.json { render json: @habit_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /habits/:habit_id/habit_records/:id
  def update
    respond_to do |format|
      if @habit_record.update(habit_record_params)
        format.html { redirect_to calendar_habit_path(@habit), notice: '記録が更新されました。' }
        format.json { render json: @habit_record }
      else
        format.html { redirect_to calendar_habit_path(@habit), alert: '記録の更新に失敗しました。' }
        format.json { render json: @habit_record.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /habits/:habit_id/habit_records/:id
  def destroy
    @habit_record.destroy
    respond_to do |format|
      format.html { redirect_to calendar_habit_path(@habit), notice: '記録が削除されました。' }
      format.json { head :no_content }
    end
  end

  private

  def set_habit
    @habit = current_user.habits.find(params[:habit_id])
  end

  def set_habit_record
    @habit_record = @habit.habit_records.find(params[:id])
  end

  def habit_record_params
    params.require(:habit_record).permit(:recorded_at, :completed, :note)
  end
end