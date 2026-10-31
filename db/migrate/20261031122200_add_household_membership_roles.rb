class AddHouseholdMembershipRoles < ActiveRecord::Migration[8.1]
  def up
    add_column :household_memberships, :role, :string, null: false, default: "member"
    execute <<~SQL
      UPDATE household_memberships
      SET role = 'admin'
      FROM households
      WHERE household_memberships.household_id = households.id
        AND household_memberships.user_id = households.creator_id
    SQL
    add_check_constraint :household_memberships, "role IN ('admin', 'member')",
                         name: "household_memberships_valid_role"
  end

  def down
    remove_check_constraint :household_memberships, name: "household_memberships_valid_role"
    remove_column :household_memberships, :role
  end
end
