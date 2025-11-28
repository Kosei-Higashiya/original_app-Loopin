module HabitsHelper
  def calendar_title(date)
    I18n.l(date, format: '%Y年%m月')
  end

  def habit_completion_rate(habit, date = Date.current)
    start_of_month = date.beginning_of_month
    end_of_month = date.end_of_month

    total_days = (end_of_month - start_of_month).to_i + 1
    completed_days = habit.habit_records
                          .where(recorded_at: start_of_month..end_of_month, completed: true)
                          .count

    return 0 if total_days.zero?

    (completed_days.to_f / total_days * 100).round(1)
  end

  def habit_status_badge(_record)
    content_tag(:span, '✓', class: 'badge bg-success', title: '完了')
  end

  # 計算習慣の現在の連続達成日数
  def count_streak(habit)
    # Get all completed records for this habit, sorted by date descending
    completed_dates = habit.habit_records
                           .where(completed: true)
                           .order(recorded_at: :desc)
                           .pluck(:recorded_at)
                           .uniq

    return 0 if completed_dates.empty?

    current_date = Date.current
    streak = 0

    # Check if today or yesterday has a record to start counting
    if completed_dates.include?(current_date)
      streak = 1
      check_date = current_date - 1.day
    elsif completed_dates.include?(current_date - 1.day)
      streak = 1
      check_date = current_date - 2.days
    else
      return 0 # No recent activity
    end

    # Count consecutive days backwards
    while completed_dates.include?(check_date)
      streak += 1
      check_date -= 1.day
    end

    streak
  end
end
