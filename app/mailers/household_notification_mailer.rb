class HouseholdNotificationMailer < ApplicationMailer
  def expense_added(expense, recipient)
    @household_name = expense.household.name
    @expense_title = expense.title
    @amount_owed = expense.expense_participants
                          .find_by!(user_id: recipient.id)
                          .amount_owed
    @due_date = expense.due_date
    @details_url = household_expense_url(expense.household, expense)

    mail(
      to: recipient.email,
      from: sender_address,
      subject: "New shared expense: #{@expense_title}"
    )
  end

  def chore_assigned(chore, recipient)
    @household_name = chore.household.name
    @chore_title = chore.title
    @due_at = chore.due_at
    @details_url = household_chores_url(chore.household)

    mail(
      to: recipient.email,
      from: sender_address,
      subject: "New chore assignment: #{@chore_title}"
    )
  end

  def member_joined(household, member, recipient)
    @household_name = household.name
    @member_name = member.name
    @details_url = household_url(household)

    mail(
      to: recipient.email,
      from: sender_address,
      subject: "New roommate joined #{@household_name}"
    )
  end

  def rule_proposed(rule, recipient)
    @household_name = rule.household.name
    @rule_title = rule.title
    @proposer_name = rule.created_by.name
    @details_url = household_rules_url(rule.household)

    mail(
      to: recipient.email,
      from: sender_address,
      subject: "New household rule proposed: #{@rule_title}"
    )
  end

  private

  def sender_address
    email_address_with_name(
      ENV.fetch("MAIL_FROM", "no-reply@example.test"),
      "Roommate OS"
    )
  end
end
