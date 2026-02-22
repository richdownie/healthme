class AddHealthProfileToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :weight, :decimal, precision: 5, scale: 1
    add_column :users, :height, :decimal, precision: 4, scale: 1
    add_column :users, :date_of_birth, :date
    add_column :users, :sex, :string
    add_column :users, :race_ethnicity, :string
    add_column :users, :activity_level, :string, default: "moderately_active"
    add_column :users, :health_concerns, :text
    add_column :users, :blood_pressure_systolic, :integer
    add_column :users, :blood_pressure_diastolic, :integer
    add_column :users, :goal, :string, default: "maintain"
  end
end
