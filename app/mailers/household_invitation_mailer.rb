class HouseholdInvitationMailer < ApplicationMailer
  def invite(email:, household:, invited_by:)
    @household_name = household.name
    @invited_by_name = invited_by.name
    @invite_code = household.invite_code
    @join_url = join_household_url

    mail(
      to: email,
      from: email_address_with_name(
        ENV.fetch("MAIL_FROM", "no-reply@example.test"),
        "Roommate OS"
      ),
      subject: "Invitation to join #{@household_name} on Roommate OS"
    )
  end
end
