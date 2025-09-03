module HabitsHelper
  def calendar_title(date)
    date.strftime("%Y年%m月")
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

  def habit_status_badge(record)
    if record.completed?
      content_tag(:span, "✓", class: "badge bg-success", title: "完了")
    else
      content_tag(:span, "○", class: "badge bg-warning text-dark", title: "未完了")
    end
  end
end
