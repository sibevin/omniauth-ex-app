class AddBindTokenToOmniauthRefs < ActiveRecord::Migration
  def change
    add_column :omniauth_refs, :bind_token, :string
    add_index :omniauth_refs, :bind_token, unique: true
  end
end
