class HabitsController < ApplicationController
  include BadgeNotifications

  before_action :authenticate_user!
  before_action :set_habit, only: %i[show edit update destroy individual_calendar toggle_record_for_date]

  def index
    @habits = current_user.habits.recent
  end

  def graphs
    @habits = current_user.habits.includes(:habit_records)
    
    # Calculate daily achievement rate for the last 30 days
    end_date = Date.current
    start_date = end_date - 29.days
    @date_range = (start_date..end_date).to_a
    
    # Calculate achievement rate per habit (last 30 days)
    @habit_data = @habits.map do |habit|
      total_days = 30
      completed_days = habit.habit_records
                            .where(recorded_at: start_date..end_date, completed: true)
                            .count
      achievement_rate = total_days.zero? ? 0 : (completed_days.to_f / total_days * 100).round(1)
      
      {
        title: habit.title,
        achievement_rate: achievement_rate,
        completed_days: completed_days
      }
    end
  end

  def show; end

  def individual_calendar
    @habit_records = @habit.habit_records.includes(:habit)
  end

  # 日付を指定して記録をトグル（完了⇔未記録）
  def toggle_record_for_date
    begin
      date = Date.parse(params[:date])
    rescue ArgumentError => e
      respond_to do |format|
        format.json do
          render json: { success: false, error: "Invalid date format: #{params[:date]}" }, status: :bad_request
        end
      end
      return
    end

    record = @habit.habit_records.find_by(recorded_at: date, user: current_user)

    if record
      # 既存の記録があれば削除（未記録に戻す）
      record.destroy!
      Rails.logger.info "Deleted habit record for habit #{@habit.id}, date #{date}, user #{current_user.id}"
    else
      # 新しい完了記録を作成
      new_record = @habit.habit_records.build(
        user: current_user,
        recorded_at: date,
        completed: true
      )

      if new_record.save
        # バッジ獲得チェックと通知設定
        newly_earned_badges = current_user.check_and_award_badges
        badge_notification(newly_earned_badges) if newly_earned_badges.any?

        Rails.logger.info "Created habit record for habit #{@habit.id}, date #{date}, user #{current_user.id}"
      else
        Rails.logger.error "Failed to create habit record: #{new_record.errors.full_messages.join(', ')}"
        respond_to do |format|
          format.json do
            render json: { success: false, error: "Failed to create record: #{new_record.errors.full_messages.join(', ')}" },
                   status: :unprocessable_entity
          end
        end
        return
      end
    end

    respond_to do |format|
      format.json { render json: { success: true } }
    end
  rescue StandardError => e
    Rails.logger.error "Unexpected error in toggle_record_for_date: #{e.class.name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    respond_to do |format|
      format.json do
        render json: { success: false, error: "Unexpected error: #{e.message}" }, status: :internal_server_error
      end
    end
  end

  def new
    @habit = current_user.habits.build
  end

  def edit; end

  def create
    @habit = current_user.habits.build(habit_params)

    if @habit.save
      flash[:success] = '習慣が作成されました！'

      # バッジチェック実行（通知は session に積むだけ）
      newly_earned = current_user.check_and_award_badges
      badge_notification(newly_earned) if newly_earned.any?

      redirect_to habits_path
    else
      render :new, status: :unprocessable_entity
    end
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
    params.require(:habit).permit(:title, :description)
  end
end
