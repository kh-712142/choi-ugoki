class TaskCompletionsController < ApplicationController
  def create
    task = current_user.recommended_task_for
    return redirect_to root_path unless task

    current_user.with_lock do
      task = current_user.recommended_task_for
      current_user.task_completions.create!(task: task, completed_on: Date.current)

      next_task = current_user.alternative_recommendation_tasks.first
      current_user.select_daily_recommendation!(next_task) if next_task
      flash[:completion_count] = current_user.task_completions.where(completed_on: Date.current).count
    end

    redirect_to root_path
  end
end
