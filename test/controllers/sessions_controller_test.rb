require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "renders the login form and registration link" do
    get login_path

    assert_response :success
    assert_select "h1", "ログイン"
    assert_select "input[type=email][name='email']"
    assert_select "input[type=password][name='password']"
    assert_select "a[href='#{new_user_path}']", "新規登録"
    assert_select "header.site-header .site-header__brand", "ちょい動き"
    assert_select "footer.site-footer", text: /小さく始める、今日の運動/
    assert_select "header.site-header nav", count: 0
    assert_select "header.site-header form[action='#{logout_path}']", count: 0
  end

  test "authenticates the user and starts a session" do
    user = User.create!(email: "login@example.com", password: "password123")

    post login_path, params: { email: "LOGIN@example.com", password: "password123" }

    assert_equal user.id, session[:user_id]
    assert_redirected_to root_path
  end

  test "shows the logout action in the shared header when logged in" do
    user = User.create!(email: "header@example.com", password: "password123")
    post login_path, params: { email: user.email, password: "password123" }

    get root_path

    assert_response :success
    assert_select "header.site-header a.site-header__brand", "ちょい動き"
    assert_select "header.site-header a[href='#{root_path}']", "今日"
    assert_select "header.site-header .site-header__nav-item", "タスク"
    assert_select "header.site-header .site-header__nav-item", "履歴"
    assert_select "header.site-header form[action='#{logout_path}']"
  end

  test "shows a generic error for invalid credentials" do
    post login_path, params: { email: "missing@example.com", password: "wrongpassword" }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", "メールアドレスまたはパスワードが違います"
    assert_nil session[:user_id]
  end

  test "logs out and clears the session" do
    user = User.create!(email: "logout@example.com", password: "password123")
    post login_path, params: { email: user.email, password: "password123" }

    delete logout_path

    assert_nil session[:user_id]
    assert_redirected_to login_path
  end

  test "redirects unauthenticated visitors to the login page" do
    get root_path

    assert_redirected_to login_path
  end
end
