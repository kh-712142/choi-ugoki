require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    Task.default_tasks.delete_all
  end

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
    candidate_names = css_select("[data-recommendation-candidate] span").map(&:text)
    assert_equal 3, candidate_names.size
    assert_includes candidate_names, "ユーザー専用タスク"
    assert_not_includes candidate_names, Task.daily_recommendation.name
    assert_select "[data-recommendation-open]", "別候補を見る"
    assert_select "dialog[data-recommendation-dialog]"
    assert_select "[data-recommendation-next]", "別候補を見る"
    assert_select "input[data-recommendation-choose][disabled][value='これにする']"
    assert_select "script[src*='recommendation_picker']"
    assert_no_match(/今週できた回数|今日の達成状況/, response.body)
    assert_select "form[action='#{task_completions_path}'] button", "できた"
  end

  test "shows a message when no default tasks exist" do
    user = User.create!(email: "empty-home@example.com", password: "password123")
    post login_path, params: { email: user.email, password: "password123" }

    get root_path

    assert_response :success
    assert_select ".home-page__empty", "おすすめタスクは準備中です。"
    assert_select "[data-recommendation-open][disabled]", "別候補を見る"
    assert_select ".recommendation-dialog__empty", "ほかの候補はありません。"
  end

  test "saves a selected task for the current user and today" do
    user = User.create!(email: "selection@example.com", password: "password123")
    post login_path, params: { email: user.email, password: "password123" }
    selected_task = Task.create!(user_id: nil, name: "選択した候補")
    Task.create!(user_id: nil, name: "別の候補")

    post daily_recommendation_path, params: { task_id: selected_task.id }

    assert_redirected_to root_path
    assert_equal selected_task.id, user.reload.daily_recommendation_task_id
    assert_equal Date.current, user.daily_recommendation_date

    get root_path

    assert_select ".home-page__recommendation-name", "選択した候補"
  end

  test "does not allow selecting another user's task" do
    user = User.create!(email: "selection-owner@example.com", password: "password123")
    post login_path, params: { email: user.email, password: "password123" }
    another_user = User.create!(email: "not-selectable@example.com", password: "password123")
    task = another_user.tasks.create!(name: "他のユーザーのタスク")

    post daily_recommendation_path, params: { task_id: task.id }

    assert_response :not_found
    assert_nil user.reload.daily_recommendation_task_id
  end
end
