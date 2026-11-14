class CompletionHistoriesController < ApplicationController
  DAILY_DISPLAY_LIMIT = 5

  def index
    completions = current_user.task_completions
                              .includes(:task)
                              .order(completed_on: :desc, created_at: :desc, id: :desc)
                              .to_a

    @weekly_completion_count = current_user.task_completions.where(
      completed_on: Date.current.beginning_of_week(:monday)..Date.current.end_of_week(:monday)
    ).count
    @daily_completions = completions.group_by(&:completed_on).transform_values do |daily_completions|
      daily_completions.first(DAILY_DISPLAY_LIMIT)
    end
  end
end
