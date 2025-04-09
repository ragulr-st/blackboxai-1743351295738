require 'net/http'
require 'json'

class Contract < ApplicationRecord
  validates :content, presence: true
  validates :output_format, presence: true, inclusion: { in: %w[PDF Word Excel HTML JSON] }
  validates :llm_provider, presence: true, inclusion: { in: %w[ChatGPT Claude Gemini] }

  GEMINI_KEY = "AIzaSyCpmi_nX_mlX1BqbfBdau4mwoBw9GkwkAo"
  ALLOWED_OUTPUT_FORMATS = %w[PDF Word Excel HTML JSON].freeze
  ALLOWED_LLM_PROVIDERS = %w[ChatGPT Claude Gemini].freeze

  def preview
    summary.presence || content.to_s
  end

  def process_custom_prompt(prompt_text)
    uri = URI("https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-lite:generateContent?key=#{GEMINI_KEY}")
    
    # Adjust the prompt based on output format
    formatted_prompt = format_prompt_for_output(prompt_text)
    
    request_body = {
      "contents" => [{
        "parts" => [{
          "text" => "#{formatted_prompt}\n\nContract text:\n#{content}"
        }]
      }]
    }

    response = send_gemini_request(uri, request_body)
    response.dig("candidates", 0, "content", "parts", 0, "text")
  end

  private

  def format_prompt_for_output(prompt_text)
    base_prompt = case output_format
    when 'JSON'
      "Please provide the response in valid JSON format."
    when 'HTML'
      "Please provide the response in HTML format with appropriate tags and styling."
    when 'PDF', 'Word'
      "Please provide the response in a well-structured document format with clear headings and paragraphs."
    when 'Excel'
      "Please provide the response in a tabular format suitable for Excel, with clear column headers and structured data."
    end

    "#{prompt_text}\n\n#{base_prompt}"
  end

  def self.send_gemini_request(uri, request_body)
    puts "-----------------request_body--------------------------"+request_body.to_s
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = request_body.to_json

    response = http.request(request)
    p response
    
    unless response.is_a?(Net::HTTPSuccess)
      error_body = JSON.parse(response.body) rescue nil
      error_message = error_body&.dig("error", "message") || response.message
      puts "-----------------error_message--------------------------"+error_message.to_s
      fffff
      raise "Gemini API error (#{response.code}): #{error_message}"
    end

    parsed_response = JSON.parse(response.body)
    
    unless parsed_response["candidates"]&.any? && 
           parsed_response["candidates"][0]["content"]&.dig("parts", 0, "text")
      raise "Invalid response format from Gemini API"
    end

    parsed_response
  rescue JSON::ParserError => e
    raise "Failed to parse Gemini API response: #{e.message}"
  rescue Net::HTTPError => e
    raise "Network error with Gemini API: #{e.message}"
  rescue StandardError => e
    raise "Error processing Gemini API request: #{e.message}"
  end

  def send_gemini_request(uri, request_body)
    puts "-----------------request_body--------------------------"+request_body.to_s
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = request_body.to_json

    response = http.request(request)
    p response
    
    unless response.is_a?(Net::HTTPSuccess)
      error_body = JSON.parse(response.body) rescue nil
      error_message = error_body&.dig("error", "message") || response.message
      puts "-----------------error_message--------------------------"+error_message.to_s
      fffff
      raise "Gemini API error (#{response.code}): #{error_message}"
    end

    parsed_response = JSON.parse(response.body)
    
    unless parsed_response["candidates"]&.any? && 
           parsed_response["candidates"][0]["content"]&.dig("parts", 0, "text")
      raise "Invalid response format from Gemini API"
    end

    parsed_response
  rescue JSON::ParserError => e
    raise "Failed to parse Gemini API response: #{e.message}"
  rescue Net::HTTPError => e
    raise "Network error with Gemini API: #{e.message}"
  rescue StandardError => e
    raise "Error processing Gemini API request: #{e.message}"
  end

  def self.upload_and_analyze(file)
    puts "-----------------fffffffffffff--------------------------"+file.to_s
  
    # Extract text from PDF
    response = HTTParty.post(
      "http://103.16.202.150:8080/upload_contract",
      body: { file: file },
      headers: { 'Content-Type' => 'multipart/form-data' },
      timeout: 180 # Increase timeout to 60 seconds
    )
  
    unless response.success?
      raise "Failed to extract text from PDF: #{response.code} - #{response.message}"
    end
  
    extracted_text = response.body.force_encoding("UTF-8")  # ✅ Move this outside `unless`
    puts"coming from gemini"+extracted_text.to_s

    # Generate detailed summary
  summary_request_body = {
      "contents" => [{
        "parts" => [{
          "text" => <<~PROMPT
          You are an expert legal contract analyst with extensive experience in summarizing, extracting, and analyzing contract terms and obligations. Your task is to analyze the provided contract and extract all relevant details in a structured, clause-wise format with precise categorization. Ensure that no obligations, clauses, or important details are missed.

Please provide the analysis strictly in the following JSON format:

{
  "ContractIdentification": {
    "ContractTitle": "",
    "ContractType": "",
    "Purpose": "",
    "PartiesInvolved": {
      "Obligor": "",
      "Obligee": "",
      "ThirdPartyBeneficiaries": []
    },
    "ContractExecutionDate": "",
    "ContractDuration": "",
    "Version": "",
    "Background": ""
  },
  "DefinitionsAndInterpretations": {
    "DefinedTerms": {},
    "InterpretationRules": "",
    "Clarifications": ""
  },
  "Clauses": [
    {
      "ClauseName": "",
      "ShortSummary": "",
      "KeyObligations": "",
      "Category": "",
      "SubClauses summary": "",
      "ImportanceAssessment": ""
    }
  ],
  "ObligationsAndResponsibilities": {
    "Obligations": [],
    "Categories": {
      "Legal": [],
      "Financial": [],
      "Operational": [],
      "other": []
    },
    "References": [],
    "Prioritization": []
  },
  "FinancialTerms": {
    "PaymentStructure": "",
    "Pricing": "",
    "Currency": "",
    "Penalties": "",
    "RefundPolicies": ""
  },
  "RiskAndLiabilities": {
    "LiabilityLimitations": "",
    "RiskFactors": {
      "Financial": "",
      "Operational": "",
      "Legal": ""
    },
    "Indemnification": ""
  },
  "ServiceLevelAgreements": {
    "PerformanceObligations": "",
    "ConsequencesOfBreaches": "",
    "MonitoringMechanisms": ""
  },
  "TerminationAndRenewal": {
    "TerminationRights": "",
    "NoticePeriod": "",
    "RenewalConditions": ""
  },
  "GoverningLawAndCompliance": {
    "GoverningLaw": "",
    "DisputeResolution": "",
    "ComplianceObligations": ""
  },
  "ConfidentialityAndSecurity": {
    "ConfidentialityObligations": "",
    "DataSecurityRequirements": ""
  },
  "ChangeManagement": {
    "ChangeProcedures": "",
    "ImpactAssessment": ""
  },
  "AssignmentAndSubcontracting": {
    "AssignmentProvisions": "",
    "SubcontractingProvisions": ""
  },
  "InsuranceRequirements": {
    "InsuranceObligations": "",
    "CoverageRequirements": ""
  },
  "RepresentationsAndWarranties": {
    "Representations": "",
    "Warranties": ""
  },
  "NoticeRequirements": {
    "NotificationMethods": "",
    "Timeframes": ""
  },
  "ForceMajeureAndExceptions": {
    "ForceMajeure": "",
    "CarveOuts": ""
  },
  "AuditRights": {
    "AuditScope": ""
  },
  "ESGObligations": {
    "Responsibilities": ""
  },
  "TechnologyAndDataUse": {
    "DataUsageRights": ""
  },
  "CrossReferences": {
    "Checks": ""
  }
}

find the contract details #{extracted_text}
 
          PROMPT
        }]
      }]
}

    uri = URI("https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-lite:generateContent?key=#{GEMINI_KEY}")
  
    summary_response = send_gemini_request(uri, summary_request_body)
    summary = summary_response.dig("candidates", 0, "content", "parts", 0, "text")  
    puts "-----------------summary_response--------------------------"+summary_response.to_s

    
   
    create(
      content: extracted_text,
      contract_type: "determine_contract_type(summary)",
      summary: summary,
      summary_json: summary
    )
  end
  def self.determine_contract_type(summary)
    begin
      clean_data = summary.gsub(/```json|```/, '')
      json_data = JSON.parse(clean_data)
      contract_type = json_data.dig("ContractIdentification", "ContractType")
      contract_type.presence || "Unknown"
    rescue JSON::ParserError
      "Unknown"
    end
  end
end
