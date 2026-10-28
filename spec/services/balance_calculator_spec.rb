require 'rails_helper'

RSpec.describe BalanceCalculator do
  let(:user1) do
    User.create!(
      name: "Alice",
      email: "alice@example.com",
      password: "password123"
    )
  end

  let(:user2) do
    User.create!(
      name: "Bob",
      email: "bob@example.com",
      password: "password123"
    )
  end

  let(:household) do
    h = Household.create!(name: "Test House", creator: user1)
    HouseholdMembership.create!(household: h, user: user1)
    HouseholdMembership.create!(household: h, user: user2)
    h
  end

  describe '#calculate' do
    it 'returns zero balance when no expenses exist' do
      calculator = BalanceCalculator.new(household, user1)
      result = calculator.calculate

      expect(result[:net_balance]).to eq(0)
    end

    it 'calculates correct balance when user paid for others' do
      # User1 paid $100, split equally between 2 people
      expense = Expense.create!(
        household: household,
        title: "Groceries",
        amount: 100,
        created_by: user1,
        expense_date: Date.today
      )
      expense.split_equally

      calculator = BalanceCalculator.new(household, user1)
      result = calculator.calculate

      # User1 paid $100 but only owes $50, so is owed $50
      expect(result[:net_balance]).to eq(50)
    end

    it 'handles precise decimal calculations correctly' do
      # Testing precise decimal arithmetic per risk mitigation [1]
      expense = Expense.create!(
        household: household,
        title: "Pizza",
        amount: 33.33,
        created_by: user2,
        expense_date: Date.today
      )
      expense.split_equally

      calculator = BalanceCalculator.new(household, user1)
      result = calculator.calculate

      # User1 owes half of 33.33
      expect(result[:total_i_owe]).to be_within(0.01).of(16.67)
    end
  end
end
