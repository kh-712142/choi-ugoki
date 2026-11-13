require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "returns the same default task for the same date" do
    tasks = create_default_tasks(3)

    first_recommendation = Task.daily_recommendation(Date.new(2026, 11, 13))
    second_recommendation = Task.daily_recommendation(Date.new(2026, 11, 13))

    assert_equal first_recommendation, second_recommendation
    assert_includes tasks, first_recommendation
  end

  test "changes the recommendation on the next date" do
    create_default_tasks(3)

    today_recommendation = Task.daily_recommendation(Date.new(2026, 11, 13))
    tomorrow_recommendation = Task.daily_recommendation(Date.new(2026, 11, 14))

    refute_equal today_recommendation, tomorrow_recommendation
  end

  test "returns no recommendation when there are no default tasks" do
    assert_nil Task.daily_recommendation
  end

  private

  def create_default_tasks(count)
    count.times.map do |index|
      Task.create!(user_id: nil, name: "標準タスク#{index + 1}")
    end
  end
end
