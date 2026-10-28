class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(
      email: params[:email].to_s.strip.downcase
    )

    if user&.authenticate(params[:password])
      reset_session
      session[:user_id] = user.id

      redirect_to root_path, notice: "Logged in successfully!"
    else
      flash.now[:alert] = "Invalid email or password"
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    reset_session
    redirect_to login_path, notice: "Logged out successfully!"
  end
end
