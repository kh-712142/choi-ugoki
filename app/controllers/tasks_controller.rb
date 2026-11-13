class TasksController < ApplicationController
  def index
    @tasks = current_user.tasks.order(:created_at, :id)
  end

  def new
    @task = current_user.tasks.new
  end

  def create
    @task = current_user.tasks.new(task_params)

    if @task.save
      redirect_to tasks_path
    else
      flash.now[:alert] = task_validation_message
      render :new, status: :unprocessable_entity
    end
  end

  private

  def task_params
    params.expect(task: [ :name ])
  end

  def task_validation_message
    if @task.errors.of_kind?(:name, :blank)
      t("tasks.new.blank_error")
    else
      @task.errors.full_messages.to_sentence
    end
  end
end
