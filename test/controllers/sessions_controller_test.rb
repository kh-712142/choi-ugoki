require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "renders the login form and registration link" do
    get login_path

    assert_response :success
    assert_select "h1", "ログイン"
    assert_select "input[type=email][name='email']"
    assert_select "input[type=password][name='password']"
    assert_select "a[href='#{new_user_path}']", "新規登録"
  end

  test "authenticates the user and starts a session" do
    user = User.create!(email: "login@example.com", password: "password123")

    post login_path, params: { email: "LOGIN@example.com", password: "password123" }

    assert_equal user.id, session[:user_id]
    assert_redirected_to root_path
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
