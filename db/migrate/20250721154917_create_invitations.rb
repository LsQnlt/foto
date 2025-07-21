class CreateInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :invitations do |t|
      t.string :email
      t.string :token
      t.boolean :used, default: false
      t.datetime :expires_at

      t.timestamps
    end
  end
end
