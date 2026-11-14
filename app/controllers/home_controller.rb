class HomeController < ApplicationController
  def index
    @recommended_task = current_user.recommended_task_for
    @alternative_tasks = current_user.alternative_recommendation_tasks
    @can_change_recommendation = @alternative_tasks.any?
    @completion_count = flash[:completion_count]
    @weekly_completion_count = current_user.weekly_completion_count
    @today_completions = current_user.recent_completions_on
  end

  def select_recommendation
    task = Task.available_to(current_user).find(params.expect(:task_id))
    current_user.select_daily_recommendation!(task)

    redirect_to root_path
  end
end
