class AddIndexesToUniquenessColumn < ActiveRecord::Migration[8.0]
  def up
    add_index :invitations, :token, unique: true
    add_index :invitations, :email, unique: true
  end

  def down
    remove_index :invitations, :token
    remove_index :invitations, :email
  end
end
