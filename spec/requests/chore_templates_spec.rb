require "rails_helper"

RSpec.describe "Predefined chores", type: :request do
  let!(:member) { User.create!(name: "Member", email: "templates@example.com", password: "password123") }
  let!(:household) { Household.create!(name: "Template House", creator: member) }

  before do
    household.household_memberships.create!(user: member)
    post login_path, params: { email: member.email, password: "password123" }
  end

  def page = Nokogiri::HTML(response.body)

  it "offers the common household chores alongside a custom option" do
    get household_chores_path(household)

    titles = page.css(".chore-template strong").map(&:text)
    expect(titles).to include("Take out the trash", "Clean the kitchen", "Wash the dishes", "Vacuum", "Custom chore")
    expect(Chore::TEMPLATES.map { |t| t[:category] }).to all(be_in(Chore::CATEGORIES))
    expect(Chore::TEMPLATES.map { |t| t[:frequency] }).to all(be_in(Chore::FREQUENCIES))
  end

  it "prefills the form from a predefined chore" do
    get household_chores_path(household, template: "dishes")

    expect(page.at_css("#chore_title")["value"]).to eq("Wash the dishes")
    expect(page.at_css("#chore_category option[selected]")["value"]).to eq("Kitchen")
    expect(page.at_css("#chore_frequency option[selected]")["value"]).to eq("DAILY")
    expect(page.at_css("a.chore-template.is-selected strong").text).to eq("Wash the dishes")
  end

  it "ignores unknown templates and leaves the form blank for a custom chore" do
    get household_chores_path(household, template: "nope")

    expect(response).to have_http_status(:ok)
    expect(page.at_css("#chore_title")["value"]).to be_nil
  end

  it "creates a chore from a template and marks it as already on the list" do
    post household_chores_path(household), params: {
      chore: { title: "Take out the trash", category: "Trash", frequency: "WEEKLY", assignee_ids: [ member.id ] }
    }
    follow_redirect!

    trash = page.css("a.chore-template").find { |link| link.text.include?("Take out the trash") }
    expect(trash.at_css(".chore-template-badge").text).to eq("On list")
  end

  it "still allows fully custom chores" do
    post household_chores_path(household), params: {
      chore: { title: "Feed the cat", category: "General", frequency: "DAILY", assignee_ids: [ member.id ] }
    }

    expect(household.chores.find_by!(title: "Feed the cat").frequency).to eq("DAILY")
  end
end

RSpec.describe "Saving custom chores as common chores", type: :request do
  let!(:member) { User.create!(name: "Member", email: "saver@example.com", password: "password123") }
  let!(:roommate) { User.create!(name: "Roomie", email: "saver-roomie@example.com", password: "password123") }
  let!(:household) { Household.create!(name: "Saver House", creator: member) }

  before do
    household.household_memberships.create!(user: member, role: "admin")
    household.household_memberships.create!(user: roommate)
  end

  def login(user) = post(login_path, params: { email: user.email, password: "password123" })
  def page = Nokogiri::HTML(response.body)

  def create_chore(title, save: true, category: "General", frequency: "WEEKLY")
    params = { chore: { title:, description: "Feed and refill water", category:, frequency:,
                        assignee_ids: [ member.id ] } }
    params[:save_as_template] = "1" if save
    post household_chores_path(household), params:
  end

  it "offers the option on the add form only" do
    login(member)
    get household_chores_path(household)
    expect(page.at_css("#save_as_template")).to be_present

    chore = household.chores.create!(title: "Existing", creator: member)
    get edit_household_chore_path(household, chore)
    expect(page.at_css("#save_as_template")).to be_nil
  end

  it "saves a custom chore so it shows up in common chores for the household" do
    login(member)
    create_chore("Feed the cat", category: "General", frequency: "DAILY")
    follow_redirect!

    expect(response.body).to include("Chore created and saved to your common chores.")
    template = household.chore_templates.find_by!(title: "Feed the cat")
    expect(template.attributes.slice("category", "frequency", "description"))
      .to eq("category" => "General", "frequency" => "DAILY", "description" => "Feed and refill water")

    delete logout_path
    login(roommate)
    get household_chores_path(household)
    saved = page.css("a.chore-template--saved").find { |link| link.text.include?("Feed the cat") }
    expect(saved.text).to include("Saved by Member")

    get household_chores_path(household, template: ChoreTemplate.key_for(template.id))
    expect(page.at_css("#chore_title")["value"]).to eq("Feed the cat")
    expect(page.at_css("#chore_frequency option[selected]")["value"]).to eq("DAILY")
    expect(page.at_css(".chore-save-template")["hidden"]).not_to be_nil
  end

  it "does not save when the box is unchecked, or duplicate an existing common chore" do
    login(member)
    create_chore("Feed the cat", save: false)
    expect(household.chore_templates).to be_empty

    create_chore("Take out the trash")
    create_chore("Feed the cat")
    create_chore("feed the CAT")
    expect(household.chore_templates.pluck(:title)).to eq([ "Feed the cat" ])
  end

  it "keeps saved chores private to their household" do
    other = Household.create!(name: "Other", creator: roommate)
    other.household_memberships.create!(user: roommate)
    template = other.chore_templates.create!(title: "Secret chore", creator: roommate)

    login(member)
    get household_chores_path(household, template: ChoreTemplate.key_for(template.id))

    expect(response.body).not_to include("Secret chore")
    delete household_chore_template_path(other, template)
    expect(response).to have_http_status(:not_found)
    expect(ChoreTemplate.exists?(template.id)).to be(true)
  end

  it "lets the saver or an admin remove a saved chore, but not other members" do
    template = household.chore_templates.create!(title: "Feed the cat", creator: member)

    login(roommate)
    get household_chores_path(household)
    expect(page.at_css(".chore-template-remove")).to be_nil
    delete household_chore_template_path(household, template)
    expect(ChoreTemplate.exists?(template.id)).to be(true)

    delete logout_path
    login(member)
    delete household_chore_template_path(household, template)
    expect(response).to redirect_to(household_chores_path(household, anchor: "add-chore"))
    expect(ChoreTemplate.exists?(template.id)).to be(false)
  end
end
