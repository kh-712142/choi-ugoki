require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "shows one daily recommendation from the default tasks" do
    user = User.create!(email: "home@example.com", password: "password123")
    post login_path, params: { email: user.email, password: "password123" }
    tasks = 3.times.map do |index|
      Task.create!(user_id: nil, name: "標準タスク#{index + 1}")
    end
    Task.create!(user_id: user.id, name: "ユーザー専用タスク")

    get root_path

    assert_response :success
    assert_select "h1", "今日の小さな運動"
    assert_select "h2", "今日のおすすめ"
    assert_select ".home-page__recommendation-name", Task.daily_recommendation.name
    assert_includes tasks.map(&:name), Task.daily_recommendation.name
    assert_no_match(/ユーザー専用タスク/, response.body)
    assert_no_match(/今週できた回数|別候補を見る|できた|今日の達成状況/, response.body)
  end

  test "shows a message when no default tasks exist" do
    user = User.create!(email: "empty-home@example.com", password: "password123")
    post login_path, params: { email: user.email, password: "password123" }

    get root_path

    assert_response :success
    assert_select ".home-page__empty", "おすすめタスクは準備中です。"
  end
end
