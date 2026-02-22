class RenamePhotoToPhotosOnActivities < ActiveRecord::Migration[8.1]
  def up
    ActiveStorage::Attachment.where(record_type: "Activity", name: "photo").update_all(name: "photos")
  end

  def down
    ActiveStorage::Attachment.where(record_type: "Activity", name: "photos").update_all(name: "photo")
  end
end
