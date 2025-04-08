class ContractsController < ApplicationController
  before_action :set_contract, only: %i[ show edit update destroy process_prompt ]

  def index
    @contracts = Contract.all
  end
#ok
def show
  p @contract.summary_json
  
  @json_data.each do |item|
    puts item["key_name"]  # Replace 'key_name' with the actual key
  end
fdfdfd  

  @json_data.each do |key, value|
    p key
    p value
  end

  xxxxxx
    @json_data = parse_summary(@contract.summary)
  p @json_data
  ffff
end


  def new
    @contract = Contract.new
  end

  def create
    contract_file = params.dig(:contract, :file)

    if contract_file.present?
      begin
        @contract = Contract.upload_and_analyze(params[:contract][:file])
        redirect_to @contract, notice: "Contract was successfully analyzed."
      rescue StandardError => e
        p e
        fffff
        redirect_to new_contract_path, alert: "Error processing contract: #{e.message}"
      end
    else
      redirect_to new_contract_path, alert: "Please select a PDF file to upload."
    end
  end

  def edit
  end

  def update
    if @contract.update(contract_params)
      redirect_to @contract, notice: "Contract was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @contract.destroy
    redirect_to contracts_url, notice: "Contract was successfully deleted."
  end

  def process_prompt
    prompt_text = params[:prompt_text]

    
    if prompt_text.present?
      begin
        @response = @contract.process_custom_prompt(prompt_text)
        puts "-----------------response--------------------------"+@response.to_s
        fff
        render json: { success: true, response: @response }
      rescue StandardError => e
        render json: { success: false, error: e.message }, status: :unprocessable_entity
      end
    else
      render json: { success: false, error: "Prompt text is required" }, status: :unprocessable_entity
    end
  end

  private

  def set_contract
    @contract = Contract.find(params[:id])
  end

  def contract_params
    params.require(:contract).permit(:content, :contract_type, :summary, :file, :output_format, :llm_provider)
  end
  def parse_summary(text)
    return {} if text.blank?
  
    sections = {}
    current_section = nil
    current_content = []
    started = false
  
    text.each_line do |line|
      line = line.strip
  
      # Wait until we reach the ```json marker
      if !started
        started = true if line == '```json'
        next
      end
  
      # End of json block
      break if line == '```'
  
      # Section header like: ContractIdentification:
      if line.end_with?(":") && !line.start_with?("-")
        sections[current_section] = process_content(current_content) if current_section
        current_section = line.chomp(":")
        current_content = []
      else
        current_content << line
      end
    end
  
    sections[current_section] = process_content(current_content) if current_section
    sections
  end
  
  def process_content(lines)
    hash = {}
  
    lines.each do |line|
      if line =~ /^-?\s*"?(.+?)"?:\s*(.+)$/
        key = $1.strip
        value = $2.strip
        hash[key] = value
      end
    end
  
    hash
  end
  
end
