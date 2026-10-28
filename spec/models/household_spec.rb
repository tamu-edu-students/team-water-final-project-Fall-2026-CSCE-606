require "rails_helper"

RSpec.describe Household, type: :model do
  let(:creator) do
  User.create!(
    name: "Aditi",
    email: "aditi@example.com",
    password: "password123"
  )
end

  it "is valid with a name and creator" do
    household = Household.new(
      name: "Apartment 101",
      creator: creator
    )

    expect(household).to be_valid
  end

  it "requires a household name" do
    household = Household.new(
      creator: creator
    )

    expect(household).not_to be_valid
  end

  it "requires a creator" do
    household = Household.new(
      name: "Apartment 101"
    )

    expect(household).not_to be_valid
  end
end
