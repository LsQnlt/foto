class AddPseudonymToUsers < ActiveRecord::Migration[8.0]
  def up
    add_column :users, :pseudonym, :string, null: true, default: nil

    User.reset_column_information
    User.where(pseudonym: nil).find_each do |user|
      user.update_columns(pseudonym: "anonymous_#{user.id}")
    end

    change_column_null :users, :pseudonym, false
    add_index :users, :pseudonym, unique: true
  end

  def down
    remove_index :users, :pseudonym
    remove_column :users, :pseudonym
  end
end
