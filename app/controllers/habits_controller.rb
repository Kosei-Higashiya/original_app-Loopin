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
        # バッジ獲得チェックと通知設定
        newly_earned_badges = current_user.check_and_award_badges
        set_badge_notification(newly_earned_badges) if newly_earned_badges.any?

        Rails.logger.info "Created habit record for habit #{@habit.id}, date #{date}, user #{current_user.id}"
      else
        Rails.logger.error "Failed to create habit record: #{new_record.errors.full_messages.join(', ')}"
        respond_to do |format|
          format.json { render json: { success: false, error: "Failed to create record: #{new_record.errors.full_messages.join(', ')}" }, status: :unprocessable_entity }
        end
        return
      end
    end

    respond_to do |format|
      format.json { 
        # Include badge information in the JSON response
        badge_message = nil
        if session[:newly_earned_badges].present? && session[:newly_earned_badges].any?
          badges = session[:newly_earned_badges]
          badge_message = if badges.size == 1
                           "🎉おめでとうございます! バッジ「#{badges.first['name']}」を獲得しました！"
                         else
                           "🎉おめでとうございます! #{badges.size}個のバッジを獲得しました！"
                         end
          
          # Clear badge notifications from session after including in response
          session.delete(:newly_earned_badges)
          session[:newly_earned_badges] = nil
          session[:badge_notification_processed] = true
        end
        
        render json: { 
          success: true,
          badge_notification: badge_message
        }
      }
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
