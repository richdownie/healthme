class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :pubkey_hex, null: false
      t.string :npub, null: false
      t.string :display_name

      t.timestamps
    end
    add_index :users, :pubkey_hex, unique: true
    add_index :users, :npub, unique: true
  end
end
