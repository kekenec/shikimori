class Api::V1::CommentsController < Api::V1::ApiController
  respond_to :json

  before_filter :authenticate_user!, only: [:create, :update, :destroy]
  before_filter :check_post_permission, only: [:create, :update, :destroy]
  before_filter :prepare_edition, only: [:edit, :create, :update, :destroy]

  # DOC GENERATED AUTOMATICALLY: REMOVE THIS LINE TO PREVENT REGENARATING NEXT TIME
  api :GET, "/comments/:id", "Show a comment"
  def show
    respond_with Comment.find(params[:id]).decorate
  end

  # DOC GENERATED AUTOMATICALLY: REMOVE THIS LINE TO PREVENT REGENARATING NEXT TIME
  api :GET, "/comments", "List comments"
  def index
    @limit = [[params[:limit].to_i, 1].max, 30].min
    @page = [params[:page].to_i, 1].max
    @desc = params[:desc].nil? || params[:desc] == '1'

    respond_with CommentsQuery
      .new(params[:commentable_type], params[:commentable_id])
      .fetch(@page, @limit, @desc)
      .with_viewed(current_user)
      .decorate
  end

  def create
    @comment = Comment.new comment_params.merge(user: current_user)

    if faye.create @comment
      respond_with @comment.decorate
    else
      render json: @comment.errors, status: :unprocessable_entity, notice: 'Комментарий создан'
    end
  end

  def update
    raise CanCan::AccessDenied unless @comment.can_be_edited_by? current_user

    if faye.update @comment, comment_params.except(:offtopic, :review)
      respond_with @comment
    else
      render json: @comment.errors, status: :unprocessable_entity, notice: 'Комментарий не изменен'
    end
  end

  def destroy
    raise CanCan::AccessDenied unless @comment.can_be_deleted_by? current_user
    faye.destroy @comment

    render json: { notice: 'Комментарий удален' }
  end

private
  def comment_params
    params
      .require(:comment)
      .permit(:body, :review, :offtopic, :commentable_id, :commentable_type, :user_id)
  end

  def prepare_edition
    @comment = Comment.find(params[:id]).decorate if params[:id]
  end

  def faye
    FayeService.new current_user, faye_token
  end
end
