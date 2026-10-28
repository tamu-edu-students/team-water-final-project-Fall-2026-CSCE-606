require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "is valid with a name, email, and password" do
      user = User.new(
        name: "Aditi",
        email: "aditi@example.com",
        password: "password123"
      )

      expect(user).to be_valid
    end

    it "requires a name" do
      user = User.new(
        email: "aditi@example.com",
        password: "password123"
      )

      expect(user).not_to be_valid
      expect(user.errors[:name]).not_to be_empty
    end

    it "requires an email" do
      user = User.new(
        name: "Aditi",
        password: "password123"
      )

      expect(user).not_to be_valid
      expect(user.errors[:email]).not_to be_empty
    end

    it "does not allow duplicate emails" do
      User.create!(
        name: "Test User",
        email: "test@example.com",
        password: "password123"
      )

      duplicate = User.new(
        name: "Another User",
        email: "test@example.com",
        password: "password123"
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).not_to be_empty
    end

    it "requires a password for new users" do
      user = User.new(
        name: "Test User",
        email: "test@example.com"
      )

      expect(user).not_to be_valid
      expect(user.errors[:password]).not_to be_empty
    end

    it "authenticates with the correct password" do
      user = User.create!(
        name: "Test User",
        email: "test@example.com",
        password: "password123"
      )

      expect(user.authenticate("password123")).to eq(user)
      expect(user.authenticate("wrongpassword")).to be(false)
    end

    it "normalizes email addresses" do
      user = User.create!(
        name: "Test User",
        email: " TEST@Example.com ",
        password: "password123"
      )

      expect(user.email).to eq("test@example.com")
    end
  end
end
