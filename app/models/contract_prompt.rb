class ContractPrompt < ApplicationRecord
    belongs_to :contract
    
    validates :prompt_text, presence: true
    validates :response, presence: true
    
    # Format the response text for display
    def formatted_response
      response.to_s.gsub(/\n/, '<br>').html_safe
    end
    
    # Get a preview of the prompt text (first 100 characters)
    def prompt_preview
      prompt_text.to_s.truncate(100)
    end
  end