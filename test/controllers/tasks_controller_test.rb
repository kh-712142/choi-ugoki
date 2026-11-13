require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email: "task-list@example.com", password: "password123")
    post login_path, params: { email: @user.email, password: "password123" }
  end

  test "lists only the current user's tasks in creation order" do
    @user.tasks.create!(name: "最初に作成したタスク")
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
    assert_select "a.task-list__add-button[href='#{new_task_path}']", "タスクを追加"
  end

  test "shows an empty state when the current user has no tasks" do
    get tasks_path

    assert_response :success
    assert_select ".task-list__empty", "作成したタスクはまだありません"
    assert_select "a.task-list__add-button[href='#{new_task_path}']", "タスクを追加"
  end

  test "creates a trimmed task for the current user and redirects to the list" do
    assert_difference("@user.tasks.count", 1) do
      post tasks_path, params: { task: { name: "  肩を10秒伸ばす  " } }
    end

    assert_equal "肩を10秒伸ばす", @user.tasks.order(:created_at, :id).last.name
    assert_redirected_to tasks_path
  end

  test "renders the task form with a link back to the list" do
    get new_task_path

    assert_response :success
    assert_select "h1", "タスクを登録"
    assert_select "input[name='task[name]'][maxlength='100']"
    assert_select "input[placeholder='例：肩を10秒伸ばす']"
    assert_select "a[href='#{tasks_path}']", "タスク一覧へ戻る"
    assert_no_match "登録成功後は自分のタスク一覧へ", response.body
  end

  test "rejects a blank task name and shows a flash error" do
    assert_no_difference("@user.tasks.count") do
      post tasks_path, params: { task: { name: "   " } }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", "空欄では登録できません"
  end

  test "rejects task names longer than 100 characters" do
    assert_no_difference("@user.tasks.count") do
      post tasks_path, params: { task: { name: "a" * 101 } }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", "タスク名は100文字以内で入力してください"
  end

  test "redirects unauthenticated visitors to login" do
    delete logout_path

    get tasks_path

    assert_redirected_to login_path
  end
end
