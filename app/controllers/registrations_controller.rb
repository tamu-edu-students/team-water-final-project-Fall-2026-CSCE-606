class RegistrationsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      redirect_to log_in(@user), notice: "Account created successfully!"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def registration_params
    params.require(:user).permit(
      :name,
      :email,
      :password,
      :password_confirmation
    )
  end
end
