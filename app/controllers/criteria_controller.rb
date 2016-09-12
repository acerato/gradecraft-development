class CriteriaController < ApplicationController
  before_action :ensure_staff?

  before_action :find_criterion, only: [:update, :destroy]

  respond_to :json

  def create
    @criterion = Criterion.create criterion_params
    respond_with @criterion, layout: false, serializer: ExistingCriterionSerializer
  end

  def destroy
    @rubric = @criterion.rubric
    @criterion.destroy
    render head: :ok, body: :nothing
  end

  def update
    @criterion.update_attributes criterion_params
    respond_with @criterion, layout: false
  end

  def update_order
    Criterion.update params[:criterion_order].keys, params[:criterion_order].values
    render head: :ok, body: :nothing
  end

  private

  def criterion_params
    params.require(:criterion).permit :description, :level_count, :full_credit_level_id, :max_points,
      :meets_expectations_level_id, :meets_expectations_points, :name, :order, :rubric_id
  end

  def serialized_criterion
    ExistingCriterionSerializer.new(@criterion.includes(:levels)).to_json
  end

  def find_criterion
    @criterion = Criterion.find params[:id]
  end
end
