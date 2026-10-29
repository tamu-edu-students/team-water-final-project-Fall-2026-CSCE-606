# spec/services/balance_calculator_spec.rb
require 'rails_helper'

RSpec.describe BalanceCalculator do
  let(:alice) { User.create!(name: "Alice", email: "alice@example.com", password: "password123") }
  let(:bob)   { User.create!(name: "Bob",   email: "bob@example.com",   password: "password123") }
  let(:carol) { User.create!(name: "Carol", email: "carol@example.com", password: "password123") }

  let(:household_a) do
    Household.create!(name: "Apartment A", creator: alice).tap do |h|
      [alice, bob].each { |u| HouseholdMembership.create!(household: h, user: u) }
    end
  end

  let(:household_b) do
    Household.create!(name: "House B", creator: alice).tap do |h|
      [alice, carol].each { |u| HouseholdMembership.create!(household: h, user: u) }
    end
  end

  def add_expense(household, creator, title, amount, participants)
    Expense.create!(household: household, title: title, amount: amount,
                    created_by: creator, expense_date: Date.current)
           .tap { |e| e.split_equally(participants.map(&:id)) }
  end

  before do
    # Household A
    add_expense(household_a, alice, "Groceries", 90, [alice, bob])  # bob owes alice 45
    add_expense(household_a, bob,   "Internet",  60, [alice, bob])  # alice owes bob 30
    old = add_expense(household_a, alice, "Old", 20, [alice, bob])  # bob's 10 is paid -> ignored
    old.expense_participants.find_by(user: bob).mark_as_paid!

    # Household B
    add_expense(household_b, carol, "Rent",   200, [alice, carol])  # alice owes carol 100
    add_expense(household_b, alice, "Dinner",  40, [alice, carol])  # carol owes alice 20
  end

  describe '#calculate for a single household' do
    it 'computes alice\'s balance in household A' do
      expect(described_class.new(household_a, alice).calculate).to eq(
        total_owed_to_me: 45, total_i_owe: 30, net_balance: 15
      )
    end

    it 'computes alice\'s balance in household B, unaffected by household A' do
      expect(described_class.new(household_b, alice).calculate).to eq(
        total_owed_to_me: 20, total_i_owe: 100, net_balance: -80
      )
    end

    it 'computes the mirror balance for the other person' do
      expect(described_class.new(household_a, bob).calculate).to eq(
        total_owed_to_me: 30, total_i_owe: 45, net_balance: -15
      )
    end

    it 'returns zeros for a household where the user has no expenses' do
      expect(described_class.new(household_b, bob).calculate).to eq(
        total_owed_to_me: 0, total_i_owe: 0, net_balance: 0
      )
    end

    it 'excludes shares that are already paid' do
      result = described_class.new(household_a, alice).calculate
      expect(result[:total_owed_to_me]).to eq(45) # not 55
    end
  end

  describe '.for_all_households' do
    it 'combines every household' do
      expect(described_class.for_all_households(alice)).to eq(
        total_owed_to_me: 65, total_i_owe: 130, net_balance: -65
      )
    end

    it 'equals the sum of the per-household balances' do
      combined = described_class.for_all_households(alice)
      parts = [household_a, household_b].map { |h| described_class.new(h, alice).calculate }

      expect(combined[:net_balance]).to eq(parts.sum { |p| p[:net_balance] })
    end
  end

  describe '.by_household' do
    it 'breaks the balance down per household id' do
      expect(described_class.by_household(alice)).to eq(
        household_a.id => { total_owed_to_me: 45, total_i_owe: 30,  net_balance: 15 },
        household_b.id => { total_owed_to_me: 20, total_i_owe: 100, net_balance: -80 }
      )
    end
  end

  it 'reflects a payment once the share is marked paid' do
    share = household_a.expenses.find_by!(title: "Internet").expense_participants.find_by!(user: alice)
    share.mark_as_paid!

    expect(described_class.new(household_a, alice).calculate).to eq(
      total_owed_to_me: 45, total_i_owe: 0, net_balance: 45
    )
  end
end