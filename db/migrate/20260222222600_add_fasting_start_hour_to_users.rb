class AddFastingStartHourToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :fasting_start_hour, :integer, default: 20
  end
end
