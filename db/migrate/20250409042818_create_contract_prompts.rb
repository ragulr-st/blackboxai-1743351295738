class CreateContractPrompts < ActiveRecord::Migration[8.0]
  def change
    create_table :contract_prompts do |t|
      t.references :contract, null: false, foreign_key: true
      t.text :prompt_text
      t.text :response

      t.timestamps
    end
  end
end