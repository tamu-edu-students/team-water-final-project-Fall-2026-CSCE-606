# spec/models/expense_participant_spec.rb
require 'rails_helper'

RSpec.describe ExpenseParticipant, type: :model do
  let(:creator) do
    User.create!(
      name: "John",
      email: "john@example.com",
      password: "password123"
    )
  end

  let(:participant) do
    User.create!(
      name: "Sarah",
      email: "sarah@example.com",
      password: "password123"
    )
  end

  let(:household) do
    h = Household.create!(
      name: "Test Household",
      creator: creator
    )
    HouseholdMembership.create!(household: h, user: creator)
    HouseholdMembership.create!(household: h, user: participant)
    h
  end

  let(:expense) do
    Expense.create!(
      household: household,
      title: "Groceries",
      amount: 100.00,
      created_by: creator,
      expense_date: Date.today
    )
  end

  it 'is valid with all required attributes' do
    expense_participant = ExpenseParticipant.new(
      expense: expense,
      user: participant,
      amount_owed: 50.00,
      payment_status: 'pending'
    )
    expect(expense_participant).to be_valid
  end

  it 'requires amount_owed to be non-negative' do
    expense_participant = ExpenseParticipant.new(
      expense: expense,
      user: participant,
      amount_owed: -10.00,
      payment_status: 'pending'
    )
    expect(expense_participant).not_to be_valid
  end

  describe '#mark_as_paid!' do
    let(:expense_participant) do
      ExpenseParticipant.create!(
        expense: expense,
        user: participant,
        amount_owed: 50.00,
        payment_status: 'pending'
      )
    end

    it 'updates payment_status to paid' do
      expense_participant.mark_as_paid!
      expect(expense_participant.payment_status).to eq('paid')
      expect(expense_participant.paid_at).not_to be_nil
    end
  end
end
