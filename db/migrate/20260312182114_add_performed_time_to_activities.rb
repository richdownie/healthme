class AddPerformedTimeToActivities < ActiveRecord::Migration[8.1]
  def up
    add_column :activities, :performed_time, :time
    # Backfill existing records with their created_at time
    execute <<~SQL
      UPDATE activities SET performed_time = time(created_at)
    SQL
  end

  def down
    remove_column :activities, :performed_time
  end
end
