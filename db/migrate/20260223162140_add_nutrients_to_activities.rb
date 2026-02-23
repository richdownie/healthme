class AddNutrientsToActivities < ActiveRecord::Migration[8.1]
  def change
    add_column :activities, :protein_g, :decimal, precision: 6, scale: 1
    add_column :activities, :carbs_g,   :decimal, precision: 6, scale: 1
    add_column :activities, :fat_g,     :decimal, precision: 6, scale: 1
    add_column :activities, :fiber_g,   :decimal, precision: 6, scale: 1
    add_column :activities, :sugar_g,   :decimal, precision: 6, scale: 1
  end
end
