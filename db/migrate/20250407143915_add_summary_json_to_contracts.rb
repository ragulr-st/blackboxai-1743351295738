class AddSummaryJsonToContracts < ActiveRecord::Migration[8.0]
  def change
    add_column :contracts, :summary_json, :json
  end
end
