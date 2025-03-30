class CreateContracts < ActiveRecord::Migration[8.0]
  def change
    create_table :contracts do |t|
      t.text :content
      t.string :contract_type
      t.text :summary

      t.timestamps
    end
  end
end
