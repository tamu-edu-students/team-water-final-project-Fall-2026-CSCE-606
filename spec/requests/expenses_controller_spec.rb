require 'rails_helper'

RSpec.describe ExpensesController, type: :controller do
  let(:user) do
    User.create!(
      name: "John",
      email: "john@example.com",
      password: "password123"
    )
  end

  let(:member) do
    User.create!(name: "Sarah", email: "sarah@example.com", password: "password123")
  end

  let(:outsider) do
    User.create!(name: "Eve", email: "eve@example.com", password: "password123")
  end

  let(:household) do
    h = Household.create!(name: "Test House", creator: user)
    HouseholdMembership.create!(household: h, user: user)
    HouseholdMembership.create!(household: h, user: member)
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

    it 'splits only among selected members and ignores the blank hidden-field entry' do
      post :create, params: {
        household_id: household.id,
        expense: { title: "Dinner", amount: 100.00, expense_date: Date.current },
        split_type: 'equal',
        selected_members: [ "", member.id.to_s ]
      }

      participants = Expense.last.expense_participants
      expect(participants.pluck(:user_id)).to eq([ member.id ])
      expect(participants.first.amount_owed).to eq(100.00)
      expect(response).to redirect_to(household_path(household))
    end

    it 'creates participants from a valid custom split' do
      post :create, params: {
        household_id: household.id,
        expense: { title: "Utilities", amount: 120.00, expense_date: Date.current },
        split_type: 'custom',
        custom_splits: { user.id.to_s => "75", member.id.to_s => "25" }
      }

      participants = Expense.last.expense_participants
      expect(participants.find_by(user: user).amount_owed).to eq(90.00)
      expect(participants.find_by(user: member).amount_owed).to eq(30.00)
    end

    it 'rolls everything back and re-renders when custom percentages do not total 100' do
      expect {
        post :create, params: {
          household_id: household.id,
          expense: { title: "Utilities", amount: 120.00, expense_date: Date.current },
          split_type: 'custom',
          custom_splits: { user.id.to_s => "60", member.id.to_s => "20" }
        }
      }.to change(Expense, :count).by(0).and change(ExpenseParticipant, :count).by(0)

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'saves an optional due date' do
      post :create, params: { household_id: household.id,
                              expense: { title: "Rent", amount: 100, expense_date: Date.current,
                                        due_date: Date.current + 7 } }

      expect(Expense.last.due_date).to eq(Date.current + 7)
end
  end

  describe 'membership check' do
    it 'blocks non-members from creating expenses' do
      allow(controller).to receive(:current_user).and_return(outsider)

      expect {
        post :create, params: {
          household_id: household.id,
          expense: { title: "Sneaky", amount: 10, expense_date: Date.current }
        }
      }.not_to change(Expense, :count)

      expect(response).to redirect_to(root_path)
    end
  end

  describe 'PATCH #mark_paid' do
    let(:expense) do
      Expense.create!(household: household, title: "Rent", amount: 100.00,
                      created_by: user, expense_date: Date.current).tap(&:split_equally)
    end

    it 'lets a user mark only their own payment as paid' do
      own   = expense.expense_participants.find_by(user: user)
      other = expense.expense_participants.find_by(user: member)

      patch :mark_paid, params: { household_id: household.id, id: expense.id, participant_id: own.id }
      expect(own.reload.payment_status).to eq('paid')

      patch :mark_paid, params: { household_id: household.id, id: expense.id, participant_id: other.id }
      expect(other.reload.payment_status).to eq('pending')
      expect(flash[:alert]).to eq('You can only mark your own payments.')
    end
  end

  describe 'editing and deleting' do
    let!(:expense) do
      Expense.create!(household: household, title: "Rent", amount: 100.00,
                      created_by: user, expense_date: Date.current).tap(&:split_equally)
    end

    describe 'PATCH #update' do
      it 'updates details and rescales shares when the amount changes' do
        patch :update, params: { household_id: household.id, id: expense.id,
                                expense: { title: "Rent (Nov)", amount: 200.00 } }

        expect(response).to redirect_to(household_expense_path(household, expense))
        expect(expense.reload.title).to eq("Rent (Nov)")
        expect(expense.expense_participants.sum(:amount_owed)).to eq(200.00)
      end

      it 'rejects an invalid amount and changes nothing' do
        patch :update, params: { household_id: household.id, id: expense.id,
                                expense: { amount: -5 } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(expense.reload.amount).to eq(100.00)
      end

      it 'rejects an amount change after a payment, and rolls back' do
        expense.expense_participants.find_by(user: member).mark_as_paid!

        patch :update, params: { household_id: household.id, id: expense.id,
                                expense: { amount: 300.00 } }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(expense.reload.amount).to eq(100.00)
        expect(expense.expense_participants.sum(:amount_owed)).to eq(100.00)
      end

      it 'does not let a non-creator edit' do
        allow(controller).to receive(:current_user).and_return(member)

        patch :update, params: { household_id: household.id, id: expense.id,
                                expense: { title: "Hacked" } }

        expect(expense.reload.title).to eq("Rent")
        expect(flash[:alert]).to match(/Only the person who created/)
      end
    end

    describe 'DELETE #destroy' do
      it 'deletes the expense and its participants' do
        expect {
          delete :destroy, params: { household_id: household.id, id: expense.id }
        }.to change(Expense, :count).by(-1).and change(ExpenseParticipant, :count).by(-2)

        expect(response).to redirect_to(household_path(household))
      end

      it 'does not let a non-creator delete' do
        allow(controller).to receive(:current_user).and_return(member)

        expect {
          delete :destroy, params: { household_id: household.id, id: expense.id }
        }.not_to change(Expense, :count)
      end

      it 'does not let a non-member delete' do
        allow(controller).to receive(:current_user).and_return(outsider)

        expect {
          delete :destroy, params: { household_id: household.id, id: expense.id }
        }.not_to change(Expense, :count)
      end
    end
  end
end
