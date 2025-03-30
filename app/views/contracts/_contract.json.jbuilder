json.extract! contract, :id, :content, :contract_type, :summary, :created_at, :updated_at
json.url contract_url(contract, format: :json)
