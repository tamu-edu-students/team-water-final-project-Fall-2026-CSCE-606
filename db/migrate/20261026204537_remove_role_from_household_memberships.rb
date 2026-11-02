class RemoveRoleFromHouseholdMemberships < ActiveRecord::Migration[8.1]
  def up
    # Preserve roles on databases that already ran the newer admin/member migration.
    return if check_constraint_exists?(:household_memberships, name: "household_memberships_valid_role")

    remove_column :household_memberships, :role if column_exists?(:household_memberships, :role)
  end

  def down
    unless column_exists?(:household_memberships, :role)
      add_column :household_memberships, :role, :string, null: false, default: "member"
    end
  end
end
