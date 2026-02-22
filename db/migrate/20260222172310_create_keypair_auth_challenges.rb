class CreateKeypairAuthChallenges < ActiveRecord::Migration[8.1]
  def change
    create_table :keypair_auth_challenges do |t|
      t.string :challenge, null: false
      t.string :pubkey_hex
      t.datetime :expires_at, null: false
      t.boolean :consumed, default: false, null: false

      t.timestamps
    end
    add_index :keypair_auth_challenges, :challenge, unique: true
  end
end
