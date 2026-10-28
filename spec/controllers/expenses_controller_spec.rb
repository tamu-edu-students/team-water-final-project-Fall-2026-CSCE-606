require 'rails_helper'

RSpec.describe ExpensesController, type: :controller do
  let(:user) do
    User.create!(
      name: "John",
      email: "john@example.com",
      password: "password123"
    )
  end

  let(:household) do
    h = Household.create!(name: "Test House", creator: user)
    HouseholdMembership.create!(household: h, user: user)
    h
  end

  before do
    # Mock authentication since it's not implemented
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'POST #create' do
    it 'creates an expense with valid params' do
      # Test without authentication enforcement
      expect {
        post :create, params: {
          household_id: household.id,
          expense: { title: "Groceries", amount: 50.00, expense_date: Date.today },
          split_type: 'equal'
        }
      }.to change(Expense, :count).by(1)
    end

    it 'rejects negative amounts' do
      post :create, params: {
        household_id: household.id,
        expense: { title: "Bad", amount: -10, expense_date: Date.today }
      }

      expect(Expense.count).to eq(0)
    end
  end
end
