class Moderations::VersionsController < ModerationsController
  load_and_authorize_resource except: [:index]
  before_action { og page_title: i18n_t('content_changes') }

  def index
    @versions = VersionsView.new
  end

  def show
    og noindex: true
    og page_title: i18n_t('content_change', version_id: @resource.id)
  end

  def create
    if @resource.save
      @resource.accept current_user if can? :accept, @resource
      redirect_back(
        fallback_location: @resource.item.decorate.url,
        notice: i18n_t("version_#{@resource.state}")
      )
    else
      redirect_back(
        fallback_location: @resource.item.decorate.url,
        alert: @resource.errors.full_messages.join(', ')
      )
    end
  end

  def tooltip
    og noindex: true
  end

  def accept
    transition :accept, 'changes_accepted'
  end

  def take
    transition :take, 'changes_accepted'
  end

  def reject
    transition :reject, 'changes_rejected'
  end

  def accept_taken
    transition :accept_taken, 'changes_accepted'
  end

  def take_accepted
    transition :take_accepted, 'changes_accepted'
  end

  def destroy
    transition :to_deleted, 'changes_deleted'
  end

private

  def transition action, success_message
    @resource.send(
      action,
      current_user,
      params[:reason]
    ) rescue StateMachine::InvalidTransition

    render json: { notice: i18n_t(success_message) }
  end

  def create_params
    params
      .require(:version)
      .permit(:type, :item_id, :item_type, :user_id, :reason)
      .to_h
      .merge(item_diff: build_item_diff)
  end

  def build_item_diff
    if params[:version][:item_diff].is_a?(String)
      JSON.parse(params[:version][:item_diff], symbolize_names: true)
    else
      params[:version][:item_diff]
    end
  end
end
