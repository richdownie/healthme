class AddTimezoneToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :timezone, :string, default: "Eastern Time (US & Canada)"
  end
end
