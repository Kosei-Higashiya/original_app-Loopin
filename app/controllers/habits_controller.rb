class HabitsController < ApplicationController
  include BadgeNotifications

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
    begin
      date = Date.parse(params[:date])
    rescue ArgumentError => e
      respond_to do |format|
        format.json { render json: { success: false, error: "Invalid date format: #{params[:date]}" }, status: :bad_request }
      end
      return
    end

    record = @habit.habit_records.find_by(recorded_at: date, user: current_user)
    newly_earned_badges = []

    if record
      # Delete existing record (toggle from completed to unrecorded)
      record.destroy!
      Rails.logger.info "Deleted habit record for habit #{@habit.id}, date #{date}, user #{current_user.id}"

       # Check for badges after deletion as well (stats might have changed)
      # Note: Don't set notifications for deletions to avoid confusing users
      current_user.check_and_award_badges
    else
      # Create new completed record
      new_record = @habit.habit_records.build(
        user: current_user,
        recorded_at: date,
        completed: true
      )

      if new_record.save
        Rails.logger.info "Created habit record for habit #{@habit.id}, date #{date}, user #{current_user.id}"
        
        # Ensure associations are reloaded to include the new record for accurate badge checking
        current_user.habits.reload
        @habit.habit_records.reload
        
        # バッジ獲得チェック（カレンダーからの操作では即座にJavaScriptで通知するため、セッションには保存しない）
        newly_earned_badges = current_user.check_and_award_badges
      else
        Rails.logger.error "Failed to create habit record: #{new_record.errors.full_messages.join(', ')}"
        respond_to do |format|
          format.json { render json: { success: false, error: "Failed to create record: #{new_record.errors.full_messages.join(', ')}" }, status: :unprocessable_entity }
        end
        return
      end
    end

    # Include badge information in response for immediate notification
    badge_info = newly_earned_badges.map { |badge| { id: badge.id, name: badge.name } }

    respond_to do |format|
      format.json { render json: { success: true, badges: badge_info } }
    end

  rescue => e
    Rails.logger.error "Unexpected error in toggle_record_for_date: #{e.class.name}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    respond_to do |format|
      format.json { render json: { success: false, error: "Unexpected error: #{e.message}" }, status: :internal_server_error }
    end
  end


  def new
    @habit = current_user.habits.build
  end

  def create
    @habit = current_user.habits.build(habit_params)

    if @habit.save
      # バッジ獲得チェックと通知設定
      newly_earned_badges = current_user.check_and_award_badges
      set_badge_notification(newly_earned_badges) if newly_earned_badges.any?

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
    params.require(:habit).permit(:title, :description)
  end
end
