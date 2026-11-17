class PasswordResetMailer < ApplicationMailer
  def reset_password(user)
    @user = user
    @reset_url = edit_password_reset_url(
      token: user.password_reset_token
    )

    mail(
      to: user.email,
      from: email_address_with_name(
        ENV.fetch("MAIL_FROM", "no-reply@example.test"),
        "Roommate OS"
      ),
      subject: "Reset your Roommate OS password"
    )
  end
end
