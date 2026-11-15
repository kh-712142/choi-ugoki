require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "ログインフォームと新規登録リンクを表示する" do
    get login_path

    assert_response :success
    assert_select "link[href*='/assets/application-']"
    assert_select "link[href*='/assets/sessions-']"
    assert_select "link[href*='/assets/users-']", count: 0
    assert_select "h1", "ログイン"
    assert_select "input[type=email][name='email']"
    assert_select "input[type=password][name='password']"
    assert_select "a[href='#{new_user_path}']", "新規登録"
    assert_select "header.site-header .site-header__brand", "ちょい動き"
    assert_select "footer.site-footer", text: /小さく始める、今日の運動/
    assert_select "header.site-header nav", count: 0
    assert_select "header.site-header form[action='#{logout_path}']", count: 0
  end

  test "ログインに成功するとセッションを開始する" do
    user = User.create!(email: "login@example.com", password: "password123")

    post login_path, params: { email: "LOGIN@example.com", password: "password123" }

    assert_equal user.id, session[:user_id]
    assert_redirected_to root_path
  end

  test "ログイン中は共通ヘッダーにログアウト操作を表示する" do
    user = User.create!(email: "header@example.com", password: "password123")
    post login_path, params: { email: user.email, password: "password123" }

    get root_path

    assert_response :success
    assert_select "header.site-header a.site-header__brand", "ちょい動き"
    assert_select "header.site-header a[href='#{root_path}']", "今日"
    assert_select "header.site-header a[href='#{tasks_path}']", "タスク"
    assert_select "header.site-header a[href='#{history_path}']", "履歴"
    assert_select "header.site-header form[action='#{logout_path}']"
  end

  test "認証情報が違う場合は共通エラーを表示する" do
    post login_path, params: { email: "missing@example.com", password: "wrongpassword" }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", "メールアドレスまたはパスワードが違います"
    assert_nil session[:user_id]
  end

  test "ログアウトするとセッションを終了する" do
    user = User.create!(email: "logout@example.com", password: "password123")
    post login_path, params: { email: user.email, password: "password123" }

    delete logout_path

    assert_nil session[:user_id]
    assert_redirected_to login_path
  end

  test "未ログインの場合はログイン画面へ遷移する" do
    get root_path

    assert_redirected_to login_path
  end
end
