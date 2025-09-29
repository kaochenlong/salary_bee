class CompaniesController < ApplicationController
  before_action :set_company, only: [ :show, :edit, :update, :destroy ]

  def index
    @companies = Current.user.companies
  end

  def show
  end

  def new
    @company = Company.new
  end

  def create
    @company = Company.new(company_params)

    if @company.save
      Current.user.user_companies.create!(company: @company)
      redirect_to @company, notice: "公司建立成功！"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @company.update(company_params)
      redirect_to @company, notice: "公司更新成功！"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @company.destroy
    redirect_to companies_path, notice: "公司已刪除。"
  end

  private

  def set_company
    @company = Current.user.companies.find(params[:id])
  end

  def company_params
    params.require(:company).permit(:name, :description, :tax_id)
  end
end