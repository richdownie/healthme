class CreateActivities < ActiveRecord::Migration[8.1]
  def change
    create_table :activities do |t|
      t.string :category
      t.decimal :value
      t.string :unit
      t.text :notes
      t.date :performed_on

      t.timestamps
    end
  end
end
