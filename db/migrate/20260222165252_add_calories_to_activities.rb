class AddCaloriesToActivities < ActiveRecord::Migration[8.1]
  def change
    add_column :activities, :calories, :integer
  end
end
