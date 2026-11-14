require "test_helper"

class CompletionHistoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "history@example.com", password: "password123")
    post login_path, params: { email: @user.email, password: "password123" }
  end

  test "counts this week's records Monday through Sunday and lists newest dates first" do
    travel_to Time.zone.local(2026, 11, 11, 12)
    task = Task.create!(user: nil, name: "今週のタスク")
    previous_week_task = Task.create!(user: nil, name: "先週のタスク")
    next_week_task = Task.create!(user: nil, name: "来週のタスク")
    other_user = User.create!(email: "history-other@example.com", password: "password123")

    @user.task_completions.create!(task:, completed_on: Date.new(2026, 11, 9))
    @user.task_completions.create!(task:, completed_on: Date.new(2026, 11, 15))
    @user.task_completions.create!(task:, completed_on: Date.new(2026, 11, 15))
    @user.task_completions.create!(task: previous_week_task, completed_on: Date.new(2026, 11, 8))
    @user.task_completions.create!(task: next_week_task, completed_on: Date.new(2026, 11, 16))
    other_user.task_completions.create!(task:, completed_on: Date.new(2026, 11, 12))

    get history_path

    assert_response :success
    assert_select "h1", "達成履歴"
    assert_select ".completion-history__weekly-count", "今週できた回数：3回"
    assert_select ".completion-history__item", 5
    assert_operator response.body.index("11/16"), :<, response.body.index("11/15")
    assert_includes response.body, "先週のタスク"
    assert_includes response.body, "来週のタスク"
    assert_select "a[href='#{root_path}']", "今日の画面へ戻る"
    assert_select ".site-header__navigation a[href='#{history_path}']", "履歴"
    assert_not_includes response.body, "他のユーザー"
  ensure
    travel_back
  end

  test "shows only the five newest completions for each date" do
    travel_to Time.zone.local(2026, 11, 14, 12)
    7.times do |index|
      task = Task.create!(user: nil, name: "達成タスク#{index}")
      @user.task_completions.create!(
        task:,
        completed_on: Date.current,
        created_at: (6 - index).minutes.ago
      )
    end

    get history_path

    assert_response :success
    assert_select ".completion-history__item", 5
    assert_operator response.body.index("達成タスク6"), :<, response.body.index("達成タスク5")
    assert_operator response.body.index("達成タスク5"), :<, response.body.index("達成タスク4")
    assert_includes response.body, "達成タスク2"
    assert_not_includes response.body, "達成タスク1"
    assert_not_includes response.body, "達成タスク0"
  ensure
    travel_back
  end

  test "shows separate empty states when no completions exist" do
    get history_path

    assert_response :success
    assert_select ".completion-history__weekly-count", "今週の達成はまだありません"
    assert_select ".completion-history__empty", "達成履歴はまだありません"
    assert_select ".completion-history__item", 0
  end

  test "requires login" do
    delete logout_path

    get history_path

    assert_redirected_to login_path
  end
end
