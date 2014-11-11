class CreateOmniauthRefs < ActiveRecord::Migration
  def change
    create_table :omniauth_refs do |t|
      t.integer :pid, limit: 1, null: false
      t.string :uuid, null: false
      t.references :user, null: false
      t.string :account
      t.timestamps
    end

    add_index :omniauth_refs, [:pid, :uuid], unique: true
  end
end
