class AddRepeatDailyToActivities < ActiveRecord::Migration[8.1]
  def change
    add_column :activities, :repeat_daily, :boolean, default: false, null: false
  end
end
