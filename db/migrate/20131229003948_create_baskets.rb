class CreateBaskets < ActiveRecord::Migration
  def change
    create_table :baskets do |t|
      t.string :shop_name
      t.datetime :submitted

      t.timestamps
    end
  end
end
