class ContractsController < ApplicationController
  before_action :set_contract, only: %i[ show edit update destroy process_prompt ]

  def index
    @contracts = Contract.all
  end
#ok
def show
  
  begin
    clean_data = @contract.summary_json.gsub(/```json|```/, '')
    @json_data = JSON.parse(clean_data)
    
    #@prompts = @contract.contract_prompts.order(created_at: :desc)
    
    if @contract.output_format == 'PDF'
      pdf_content = generate_pdf_from_json(@json_data)
      send_data pdf_content, 
                filename: "contract_analysis.pdf", 
                type: 'application/pdf', 
                disposition: 'inline'
    end
  rescue JSON::ParserError => e
    ffff
    flash.now[:alert] = "Error parsing contract summary: #{e.message}"
    @json_data = {}
  rescue StandardError => e
    mmmmmm
    flash.now[:alert] = "Error processing contract: #{e.message}"
    @json_data = {}
  end
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
    contract_id = params[:id]
    
    if prompt_text.present? && contract_id.present?
      begin
        @response = @contract.process_custom_prompt(prompt_text)
        puts "-----------------response--------------------------"+@response.to_s
        @dummay = "We are dping good we can "
        render json: { success: true, response: @response }
      rescue StandardError => e
        p e
        ddddd
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
  # def generate_pdf_from_json(json_data)
  #   require 'prawn'

  #   pdf = Prawn::Document.new

  #   pdf.font_families.update(
  #     "OpenSans" => {
  #       normal: Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf"),
  #       bold: Rails.root.join("app/assets/fonts/OpenSans-Bold.ttf")
  #     }
  #   )
  #   pdf.font "OpenSans"

  #   # Add title
  #   pdf.text "Contract Analysis Report", size: 24, style: :bold, align: :center
  #   pdf.move_down 20

  #   json_data.each do |section_name, section_data|
  #     # Add section header
  #     pdf.text section_name.to_s.gsub(/(?=[A-Z])/, ' '), size: 16, style: :bold
  #     pdf.move_down 10

  #     case section_data
  #     when Hash
  #       section_data.each do |key, value|
  #         if value.is_a?(Hash)
  #           # Handle nested hash
  #           pdf.text key.to_s.gsub(/(?=[A-Z])/, ' '), size: 12, style: :bold
  #           value.each do |sub_key, sub_value|
  #             pdf.text "#{sub_key.to_s.gsub(/(?=[A-Z])/, ' ')}: #{sub_value}", size: 10
  #           end
  #         else
  #           # Handle direct key-value pairs
  #           pdf.text "#{key.to_s.gsub(/(?=[A-Z])/, ' ')}: #{value}", size: 10
  #         end
  #       end
  #     when Array
  #       # Handle array of items
  #       section_data.each do |item|
  #         if item.is_a?(Hash)
  #           item.each do |key, value|
  #             pdf.text "#{key.to_s.gsub(/(?=[A-Z])/, ' ')}: #{value}", size: 10
  #           end
  #           pdf.move_down 5
  #         else
  #           pdf.text "- #{item}", size: 10
  #         end
  #       end
  #     else
  #       pdf.text section_data.to_s, size: 10
  #     end
  #     pdf.move_down 15
  #   end

  #   pdf.render
  # end
  
  def generate_pdf_from_json(json_data)
    require 'prawn'
    require 'prawn/table'
  
    pdf = Prawn::Document.new(page_size: 'A4', margin: 40)
  
    # Font settings
    pdf.font_families.update(
      "OpenSans" => {
        normal: Rails.root.join("app/assets/fonts/OpenSans-Regular.ttf"),
        bold: Rails.root.join("app/assets/fonts/OpenSans-Bold.ttf")
      }
    )
    pdf.font "OpenSans"
  
    # Title
    pdf.text "📄 Contract Analysis Report", size: 26, style: :bold, align: :center, color: "2E86C1"
    pdf.move_down 30
  
    json_data.each do |section_name, section_data|
      # Section Header
      pdf.text section_name.to_s.gsub(/(?=[A-Z])/, ' ').strip.titleize, size: 18, style: :bold, color: "117864"
      pdf.stroke_horizontal_rule
      pdf.move_down 10
  
      case section_data
      when Hash
        section_data.each do |key, value|
          if value.is_a?(Hash)
            # Nested Hash
            pdf.text "#{key.to_s.gsub(/(?=[A-Z])/, ' ').strip.titleize}", size: 14, style: :bold, color: "5B2C6F"
            data = value.map do |sub_key, sub_value|
              [sub_key.to_s.gsub(/(?=[A-Z])/, ' ').strip.titleize, sub_value.to_s]
            end
            pdf.table(data, cell_style: { size: 10, padding: 6 }, row_colors: ["F9F9F9", "EAF2F8"])
            pdf.move_down 10
          else
            # Direct Key-Value
            pdf.text "<b>#{key.to_s.gsub(/(?=[A-Z])/, ' ').strip.titleize}:</b> #{value}", inline_format: true, size: 11
          end
        end
  
      when Array
        section_data.each_with_index do |item, index|
          if item.is_a?(Hash)
            pdf.text "Item #{index + 1}", style: :bold, size: 12, color: "154360"
            data = item.map do |key, value|
              [key.to_s.gsub(/(?=[A-Z])/, ' ').strip.titleize, value.to_s]
            end
            pdf.table(data, cell_style: { size: 10, padding: 6 }, row_colors: ["FDFEFE", "EBF5FB"])
            pdf.move_down 10
          else
            pdf.text "• #{item}", size: 11
          end
        end
  
      else
        pdf.text section_data.to_s, size: 10
      end
  
      pdf.move_down 20
    end
  
    pdf.render
  end
end
