require 'rails_helper'

RSpec.describe Expense, type: :model do
  let(:creator) do
    User.create!(
      name: "John",
      email: "john@example.com",
      password: "password123"
    )
  end

  let(:member1) do
    User.create!(
      name: "Sarah",
      email: "sarah@example.com",
      password: "password123"
    )
  end

  let(:member2) do
    User.create!(
      name: "Mike",
      email: "mike@example.com",
      password: "password123"
    )
  end

  let(:household) do
    h = Household.create!(
      name: "Test Household",
      creator: creator
    )
    # Create household memberships without role (since it doesn't exist)
    HouseholdMembership.create!(household: h, user: creator)
    HouseholdMembership.create!(household: h, user: member1)
    HouseholdMembership.create!(household: h, user: member2)
    h
  end

  describe 'validations' do
    it 'is valid with all required attributes' do
      expense = Expense.new(
        household: household,
        title: "Groceries",
        amount: 90.00,
        created_by: creator,
        expense_date: Date.today
      )
      expect(expense).to be_valid
    end

    it 'requires a title' do
      expense = Expense.new(
        household: household,
        amount: 90.00,
        created_by: creator,
        expense_date: Date.today
      )
      expect(expense).not_to be_valid
    end

    it 'requires amount to be positive' do
      expense = Expense.new(
        household: household,
        title: "Test",
        amount: -10,
        created_by: creator,
        expense_date: Date.today
      )
      expect(expense).not_to be_valid
    end
  end

  describe '#split_equally' do
    let(:expense) do
      Expense.create!(
        household: household,
        title: "Groceries",
        amount: 90.00,
        created_by: creator,
        expense_date: Date.today
      )
    end

    it 'splits amount equally among all household users' do
      expense.split_equally

      expect(expense.expense_participants.count).to eq(3)
      expect(expense.expense_participants.pluck(:amount_owed)).to all(eq(30.00))
    end

    it 'handles decimal precision correctly for accurate expense splits' do
      expense.update!(amount: 100.00)
      expense.split_equally

      # Should handle rounding properly per risk mitigation [1]
      total = expense.expense_participants.sum(:amount_owed)
      expect(total).to be_within(0.01).of(100.00)
    end

    it 'assigns pending status to all participants' do
      expense.split_equally

      expect(expense.expense_participants.pluck(:payment_status)).to all(eq('pending'))
    end
  end

  describe '#split_custom' do
    let(:expense) do
      Expense.create!(
        household: household,
        title: "Utilities",
        amount: 120.00,
        created_by: creator,
        expense_date: Date.today
      )
    end

    it 'splits amount by custom percentages' do
      splits = {
        creator.id => 50,
        member1.id => 30,
        member2.id => 20
      }

      expense.split_custom(splits)

      creator_participant = expense.expense_participants.find_by(user: creator)
      member1_participant = expense.expense_participants.find_by(user: member1)
      member2_participant = expense.expense_participants.find_by(user: member2)

      expect(creator_participant.amount_owed).to eq(60.00)
      expect(member1_participant.amount_owed).to eq(36.00)
      expect(member2_participant.amount_owed).to eq(24.00)
    end
  end
end
