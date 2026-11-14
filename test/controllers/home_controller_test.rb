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
    assert_select ".weekly-completion-count", "今週できた回数：0回"
    assert_select "#daily-achievements-title", "今日の達成状況"
    assert_select ".home-page__daily-empty", "今日の達成はまだありません"
    assert_select "form[action='#{task_completions_path}'] button", "できた"
  end

  test "shows today's five newest achievements and excludes other dates and users" do
    travel_to Time.zone.local(2026, 11, 14, 12)
    user = User.create!(email: "home-achievements@example.com", password: "password123")
    post login_path, params: { email: user.email, password: "password123" }
    tasks = 7.times.map { |index| Task.create!(user_id: nil, name: "今日の達成#{index}") }
    tasks.each_with_index do |task, index|
      user.task_completions.create!(task:, completed_on: Date.current, created_at: (6 - index).minutes.ago)
    end
    yesterday_task = Task.create!(user_id: nil, name: "昨日の達成")
    user.task_completions.create!(task: yesterday_task, completed_on: Date.new(2026, 11, 8))
    other_user = User.create!(email: "home-achievements-other@example.com", password: "password123")
    other_user.task_completions.create!(task: tasks.last, completed_on: Date.current)
    other_users_task = other_user.tasks.create!(name: "他のユーザーの達成")
    other_user.task_completions.create!(task: other_users_task, completed_on: Date.current)

    get root_path

    assert_response :success
    assert_select ".weekly-completion-count", "今週できた回数：7回"
    assert_select ".home-page__daily-achievement", 5
    achievement_names = css_select(".home-page__daily-achievement-name").map(&:text)
    assert_equal [ "今日の達成6", "今日の達成5", "今日の達成4", "今日の達成3", "今日の達成2" ], achievement_names
    assert_not_includes achievement_names, "昨日の達成"
    assert_not_includes achievement_names, "他のユーザーの達成"
  ensure
    travel_back
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
