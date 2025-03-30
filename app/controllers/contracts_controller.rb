class ContractsController < ApplicationController
  before_action :set_contract, only: %i[ show edit update destroy ]

  def index
    @contracts = Contract.all
  end

  def show
  end

  def new
    @contract = Contract.new
  end

  def create
    if params[:contract][:file].present?
      begin
        @contract = Contract.upload_and_analyze(params[:contract][:file])
        redirect_to @contract, notice: "Contract was successfully analyzed."
      rescue StandardError => e
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

  private

  def set_contract
    @contract = Contract.find(params[:id])
  end

  def contract_params
    params.require(:contract).permit(:content, :contract_type, :summary, :file)
  end
end
