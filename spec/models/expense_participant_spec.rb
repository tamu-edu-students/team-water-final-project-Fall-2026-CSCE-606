# spec/models/expense_participant_spec.rb
require 'rails_helper'

RSpec.describe ExpenseParticipant, type: :model do
  let(:creator) do
    User.create!(name: "John", email: "john@example.com", password: "password123")
  end

  let(:participant) do
    User.create!(name: "Sarah", email: "sarah@example.com", password: "password123")
  end

  let(:household) do
    h = Household.create!(name: "Test Household", creator: creator)
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
      expense_date: Date.current
    )
  end

  def build_participant(**overrides)
    ExpenseParticipant.new(
      { expense: expense, user: participant, amount_owed: 50.00, payment_status: 'pending' }.merge(overrides)
    )
  end

  describe 'validations' do
    it 'is valid with all required attributes' do
      expect(build_participant).to be_valid
    end

    it 'requires amount_owed to be non-negative' do
      expect(build_participant(amount_owed: -10.00)).not_to be_valid
    end

    it 'allows an amount_owed of zero' do
      expect(build_participant(amount_owed: 0)).to be_valid
    end

    it 'requires amount_owed to be present' do
      expect(build_participant(amount_owed: nil)).not_to be_valid
    end

    it 'requires an expense' do
      expect(build_participant(expense: nil)).not_to be_valid
    end

    it 'requires a user' do
      expect(build_participant(user: nil)).not_to be_valid
    end
  end

  describe 'associations' do
    it 'is reachable from its expense and exposes the user through participants' do
      record = build_participant.tap(&:save!)

      expect(expense.expense_participants).to include(record)
      expect(expense.participants).to include(participant)
    end
  end

  describe '#mark_as_paid!' do
    let(:expense_participant) { build_participant.tap(&:save!) }

    it 'updates payment_status to paid' do
      expense_participant.mark_as_paid!
      expect(expense_participant.payment_status).to eq('paid')
      expect(expense_participant.paid_at).not_to be_nil
    end

    it 'persists the change' do
      expense_participant.mark_as_paid!
      expense_participant.reload

      expect(expense_participant.payment_status).to eq('paid')
      expect(expense_participant.paid_at).to be_within(5.seconds).of(Time.current)
    end

    it 'does not change amount_owed' do
      expect { expense_participant.mark_as_paid! }
        .not_to change { expense_participant.reload.amount_owed }
    end

    it 'starts unpaid and only affects the targeted participant' do
      other = build_participant(user: creator).tap(&:save!)

      expect(expense_participant.payment_status).to eq('pending')
      expect(expense_participant.paid_at).to be_nil

      expense_participant.mark_as_paid!

      other.reload
      expect(other.payment_status).to eq('pending')
      expect(other.paid_at).to be_nil
    end
  end
end
