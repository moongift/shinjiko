class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.integer :user_id, :issue_id, :patchset_id, :patch_id, :line, :draft, :parrent_id
      t.text    :text
      t.timestamps
    end
  end

  def self.down
    drop_table :comments
  end
end