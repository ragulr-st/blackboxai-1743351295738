class Contract < ApplicationRecord
  validates :content, presence: true

  def preview
    summary.presence || content.to_s
  end

  def self.upload_and_analyze(file)
    # Extract text from PDF
    response = HTTParty.post(
      "http://103.16.202.150:8080/upload_contract",
      body: { file: file },
      headers: { 'Content-Type' => 'multipart/form-data' }
    )

    if response.success?
      extracted_text = response.body.force_encoding("UTF-8")
      
      # Get contract type from Gemini
      uri = URI("https://generativelanguage.googleapis.com/v1/models/gemini-1.5-pro-002:generateContent?key=#{Rails.application.credentials.gemini_api_key}")
      request_body = {
        "contents" => [{
          "parts" => [{
            "text" => "You are an AI contract expert. Identify the type of contract below and provide a brief description:\n\n#{extracted_text}"
          }]
        }]
      }

      contract_type_response = send_gemini_request(uri, request_body)
      contract_type = contract_type_response.dig("candidates", 0, "content", "parts", 0, "text")

      # Generate detailed summary
      summary_request_body = {
        "contents" => [{
          "parts" => [{
            "text" => "You are a legal AI expert. Provide a detailed analysis of the following #{contract_type} contract, including key terms, obligations, risks, and important clauses:\n\n#{extracted_text}"
          }]
        }]
      }

      summary_response = send_gemini_request(uri, summary_request_body)
      summary = summary_response.dig("candidates", 0, "content", "parts", 0, "text")

      create(
        content: extracted_text,
        contract_type: contract_type,
        summary: summary
      )
    else
      raise "Failed to extract text from PDF: #{response.code} - #{response.message}"
    end
  end

  private

  def self.send_gemini_request(uri, request_body)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = request_body.to_json

    response = http.request(request)
    JSON.parse(response.body)
  rescue JSON::ParserError, Net::HTTPError => e
    raise "Failed to process with Gemini API: #{e.message}"
  end
end
