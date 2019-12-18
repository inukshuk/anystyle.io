class CreateAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :accounts do |t|
      t.string :user, null: false, limit: 256
      t.string :access_token, null: false
      t.integer :access_count, default: 0, limit: 256

      t.timestamps
    end

    add_index :accounts, :user, unique: true
    add_index :accounts, :access_token, unique: true
  end
end
