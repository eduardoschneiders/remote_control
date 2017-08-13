class Plane < ActiveRecord::Migration[5.1]
  def change
    create_table :planes do |t|
      t.string :name
      t.text :code
      t.text :seats, default: [].to_yaml
      t.text :reserved_seats, default: [].to_yaml

      t.timestamps
    end
  end
end
