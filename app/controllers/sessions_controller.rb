class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.authenticate_by(email: params[:email].to_s.strip.downcase, password: params[:password])

    if user
      reset_session
      session[:user_id] = user.id
      redirect_to root_path
    else
      flash.now[:alert] = t("sessions.new.invalid_credentials")
      render :new, status: :unprocessable_entity
    end
  end
  skip_before_action :require_authentication, only: %i[ new create ]

  def destroy
    reset_session
    redirect_to login_path
  end
end
