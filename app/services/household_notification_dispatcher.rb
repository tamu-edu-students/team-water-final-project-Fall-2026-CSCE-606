class HouseholdNotificationDispatcher
  def self.member_joined(household:, actor:)
    household.users.includes(:notification_preference).each do |recipient|
      next if recipient.id == actor.id
      next if recipient.notification_preference&.email_household_activity == false

      HouseholdNotificationMailer.member_joined(
        household, actor, recipient
      ).deliver_later
    end
  end

  def self.rule_proposed(rule:, actor:)
    rule.household.users.includes(:notification_preference).each do |recipient|
      next if recipient.id == actor.id
      next if recipient.notification_preference&.email_household_activity == false

      HouseholdNotificationMailer.rule_proposed(
        rule, recipient
      ).deliver_later
    end
  end

  def self.expense_created(expense:, actor:)
    expense.participants.distinct
           .includes(:notification_preference)
           .each do |recipient|
      next if recipient.id == actor.id
      next if recipient.notification_preference&.email_bills == false

      HouseholdNotificationMailer.expense_added(
        expense, recipient
      ).deliver_later
    end
  end

  def self.chore_created(chore:, actor:)
    chore.assignees.distinct
         .includes(:notification_preference)
         .each do |recipient|
      next if recipient.id == actor.id
      next if recipient.notification_preference&.email_chores == false

      HouseholdNotificationMailer.chore_assigned(
        chore, recipient
      ).deliver_later
    end
  end
end
