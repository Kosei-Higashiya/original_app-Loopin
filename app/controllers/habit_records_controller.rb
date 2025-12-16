class HabitRecordsController < ApplicationController
  include BadgeNotifications

  before_action :authenticate_user!
  before_action :set_habit
  before_action :set_habit_record, only: %i[show update destroy]

  # habits/:habit_id/habit_records/:id を取得する
  def show
    respond_to do |format|
      format.html
      format.json { render json: @habit_record }
    end
  end

  # habits/:habit_id/habit_recordsを作成する
  def create
    @habit_record = @habit.habit_records.build(habit_record_params)
    @habit_record.user = current_user

    respond_to do |format|
      if @habit_record.save
        # バッジ獲得チェックと通知設定
        newly_earned_badges = current_user.check_and_award_badges
        badge_notification(newly_earned_badges) if newly_earned_badges.any?

        format.html { redirect_to calendar_habit_path(@habit), notice: '記録が作成されました。' }
        format.json { render json: @habit_record, status: :created }
      else
        format.html { redirect_to calendar_habit_path(@habit), alert: '記録の作成に失敗しました。' }
        format.json { render json: @habit_record.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @habit_record.update(habit_record_params)
        # バッジ獲得チェックと通知設定
        newly_earned_badges = current_user.check_and_award_badges
        badge_notification(newly_earned_badges) if newly_earned_badges.any?

        format.html { redirect_to calendar_habit_path(@habit), notice: '記録が更新されました。' }
        format.json { render json: @habit_record }
      else
        format.html { redirect_to calendar_habit_path(@habit), alert: '記録の更新に失敗しました。' }
        format.json { render json: @habit_record.errors, status: :unprocessable_entity }
      end
    end
  end

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
