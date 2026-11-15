require "test_helper"

class TaskTest < ActiveSupport::TestCase
  setup do
    Task.default_tasks.delete_all
  end

  test "同じ日付には同じ標準タスクを返す" do
    create_default_tasks(3)

    first_recommendation = Task.daily_recommendation(Date.new(2026, 11, 13))
    second_recommendation = Task.daily_recommendation(Date.new(2026, 11, 13))

    assert_equal first_recommendation, second_recommendation
    assert Task.default_tasks.exists?(first_recommendation.id)
  end

  test "翌日はおすすめタスクが変わる" do
    create_default_tasks(3)

    today_recommendation = Task.daily_recommendation(Date.new(2026, 11, 13))
    tomorrow_recommendation = Task.daily_recommendation(Date.new(2026, 11, 14))

    refute_equal today_recommendation, tomorrow_recommendation
  end

  test "標準タスクがない場合はおすすめを返さない" do
    assert_nil Task.daily_recommendation
  end

  private

  def create_default_tasks(count)
    count.times.map do |index|
      Task.create!(user_id: nil, name: "標準タスク#{index + 1}")
    end
  end
end
