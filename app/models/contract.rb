class Contract < ApplicationRecord
  validates :content, presence: true

  GEMINI_KEY = "AIzaSyCpmi_nX_mlX1BqbfBdau4mwoBw9GkwkAo"

  def preview
    summary.presence || content.to_s
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
    p extracted_text
  
  
    # Get contract type from Gemini
    uri = URI("https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash-lite:generateContent?key=#{GEMINI_KEY}")
    request_body = {
      "contents" => [{
        "parts" => [{
          "text" => "You are a legal document classifier. From the following contract text, identify ONLY these two pieces of information:
1. Contract Type: What specific type of legal agreement is this? (e.g., employment, lease, loan, NDA, etc.)
2. Locality/Jurisdiction: What geographic location (city, state, country) governs this agreement, if specified?

Provide only these two data points in the format:
- Type: [contract type]
- Locality: [jurisdiction or 'Not specified' if absent]

Contract text:
#{extracted_text}"
        }]
      }]
    }
  
    #contract_type_response = send_gemini_request(uri, request_body)
    #contract_type = contract_type_response.dig("candidates", 0, "content", "parts", 0, "text")
  
    # Generate detailed summary
    summary_request_body = {
      "contents" => [{
        "parts" => [{
          "text" => <<~PROMPT
          You are an expert legal contract analyst with extensive experience in summarizing, extracting, and analyzing contract terms and obligations. Your task is to analyze the provided contract and extract all relevant details in a structured, clause-wise format with precise categorization. Ensure that no obligations, clauses, or important details are missed.

Please provide the analysis strictly in the following JSON format:

```json
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
      "FullText": "",
      "KeyObligations": "",
      "Category": "",
      "SubClauses": [],
      "ImportanceAssessment": ""
    }
  ],
  "ObligationsAndResponsibilities": {
    "Obligations": [],
    "Categories": {
      "Legal": [],
      "Financial": [],
      "Operational": []
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
  
    summary_response = send_gemini_request(uri, summary_request_body)
    summary = summary_response.dig("candidates", 0, "content", "parts", 0, "text")  
   
    create(
      content: extracted_text,
      contract_type: "contract_type",
      summary: summary
    )
  end

  private

  def self.send_gemini_request(uri, request_body)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request.body = request_body.to_json

    response = http.request(request)
    
    unless response.is_a?(Net::HTTPSuccess)
      error_body = JSON.parse(response.body) rescue nil
      error_message = error_body&.dig("error", "message") || response.message
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
end
