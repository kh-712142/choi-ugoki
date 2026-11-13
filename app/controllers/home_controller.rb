class HomeController < ApplicationController
  def index
    @recommended_task = Task.daily_recommendation
  end
end
