Feature: User Authentication
  As a prospective roommate
  I want to create and access my account
  So that I can use the household management system

  Background:
    Given the system is initialized

  Scenario: Successful user registration
    When I visit the registration page
    And I fill in "Email" with "john@example.com"
    And I fill in "Name" with "John Doe"
    And I fill in "Password" with "SecurePass123!"
    And I click "Sign Up"
    Then I should see "Welcome to Roommate OS"
    And I should receive a confirmation email

  Scenario: Registration with invalid email
    When I visit the registration page
    And I fill in "Email" with "invalid-email"
    And I fill in "Password" with "SecurePass123!"
    And I click "Sign Up"
    Then I should see "Email is invalid"
    And I should remain on the registration page

  Scenario: Successful login
    Given a user exists with email "john@example.com"
    When I visit the login page
    And I fill in "Email" with "john@example.com"
    And I fill in "Password" with "SecurePass123!"
    And I click "Log In"
    Then I should see "Dashboard"
    And I should be logged in

  Scenario: Login with incorrect password
    Given a user exists with email "john@example.com"
    When I visit the login page
    And I fill in "Email" with "john@example.com"
    And I fill in "Password" with "WrongPassword"
    And I click "Log In"
    Then I should see "Invalid email or password"
