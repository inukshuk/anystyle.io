class CreateSequences < ActiveRecord::Migration[6.0]
  def change
    create_table :sequences do |t|
      t.string :xml, null: false, limit: 4096
      t.timestamps
    end

    add_index :sequences, :xml, unique: true
  end
end
