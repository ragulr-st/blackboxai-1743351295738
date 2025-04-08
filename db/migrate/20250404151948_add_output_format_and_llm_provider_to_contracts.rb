class AddOutputFormatAndLlmProviderToContracts < ActiveRecord::Migration[8.0]
  def change
    add_column :contracts, :output_format, :string, default: 'JSON', null: false
    add_column :contracts, :llm_provider, :string, default: 'Gemini', null: false
  end
end
