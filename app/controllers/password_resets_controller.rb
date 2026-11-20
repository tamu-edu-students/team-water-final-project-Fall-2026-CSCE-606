class PasswordResetsController < ApplicationController
  rate_limit to: 5, within: 1.hour, only: :create
  before_action :set_user_from_token, only: %i[edit update]

  def new
  end

  def create
    email = params[:email].to_s.strip.downcase
    user = User.find_by(email: email)

    if user
      begin
        PasswordResetMailer.reset_password(user).deliver_now
      rescue StandardError => e
        Rails.logger.error(
          "Password reset email delivery failed: #{e.class}"
        )
      end
    end

    redirect_to login_path,
                notice: "If an account exists with that email, " \
                        "you will receive a password reset link."
  end

  def edit
  end

  def update
    @user.assign_attributes(password_params)

    if @user.password.blank?
      @user.errors.add(:password, "can't be blank")
    end

    if @user.errors.empty? && @user.save
      reset_session
      redirect_to login_path,
                  notice: "Password updated successfully. Please log in."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_user_from_token
    @user = User.find_by_password_reset_token(params[:token])
    return if @user

    redirect_to new_password_reset_path,
                alert: "This password reset link is invalid or has expired."
  end

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
