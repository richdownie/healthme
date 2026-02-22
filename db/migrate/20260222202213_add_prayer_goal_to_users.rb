class AddPrayerGoalToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :prayer_goal_minutes, :integer, default: 15
  end
end
