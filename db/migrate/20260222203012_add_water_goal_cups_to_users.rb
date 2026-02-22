class AddWaterGoalCupsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :water_goal_cups, :decimal, precision: 4, scale: 1
  end
end
