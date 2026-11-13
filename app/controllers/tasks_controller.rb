class TasksController < ApplicationController
  def index
    @tasks = current_user.tasks.order(:created_at, :id)
  end
end
