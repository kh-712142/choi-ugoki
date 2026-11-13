require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "task-list@example.com", password: "password123")
    post login_path, params: { email: @user.email, password: "password123" }
  end

  test "lists only the current user's tasks in creation order" do
    first_task = @user.tasks.create!(name: "最初に作成したタスク")
    @user.tasks.create!(name: "次に作成したタスク")
    Task.create!(user_id: nil, name: "標準タスク")
    other_user = User.create!(email: "other-task-list@example.com", password: "password123")
    other_user.tasks.create!(name: "他のユーザーのタスク")

    get tasks_path

    assert_response :success
    assert_select "h1", "自分のタスク"
    assert_select ".task-list__item", 2
    assert_select ".task-list__item", text: /最初に作成したタスク/
    assert_select ".task-list__item", text: /次に作成したタスク/
    assert_operator response.body.index("最初に作成したタスク"), :<, response.body.index("次に作成したタスク")
    assert_no_match(/標準タスク|他のユーザーのタスク/, response.body)
    assert_select "a[href='#{root_path}']", "今日の画面へ戻る"
    assert_select "button.task-list__add-button[disabled]", "タスクを追加"
  end

  test "shows an empty state when the current user has no tasks" do
    get tasks_path

    assert_response :success
    assert_select ".task-list__empty", "作成したタスクはまだありません"
    assert_select "button.task-list__add-button[disabled]", "タスクを追加"
  end

  test "redirects unauthenticated visitors to login" do
    delete logout_path

    get tasks_path

    assert_redirected_to login_path
  end
end
