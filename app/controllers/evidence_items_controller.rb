class EvidenceItemsController < ApplicationController
  @actions_without_auth = [:index, :show]
  skip_before_filter :ensure_signed_in, only: @actions_without_auth
  after_action :verify_authorized, except: @actions_without_auth

  def index
    items = EvidenceItem.joins(variant: [:gene])
      .view_scope
      .where(variants: { name: params[:variant_id] }, genes: { entrez_id: params[:gene_id] })

    render json: items.map { |item| EvidenceItemPresenter.new(item) }
  end

  def show
    item = EvidenceItem.joins(variant: [:gene])
      .view_scope
      .find_by(id: params[:id], variants: { id: params[:variant_id] }, genes: { entrez_id: params[:gene_id] })

    render json: EvidenceItemPresenter.new(item)
  end

  def update
    item = EvidenceItem.view_scope.find_by(id: params[:id])
    authorize item
    status = if item.update_attributes(evidence_item_params)
               :ok
             else
               :unprocessable_entity
             end
    render json: EvidenceItemPresenter.new(item), status: status
  end

  private
  def evidence_item_params
    params.permit(:text, :outcome, :clinical_direction)
  end

end
