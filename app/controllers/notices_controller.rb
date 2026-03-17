class NoticesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_notice, only: %i[show edit update destroy]
  before_action :authorize_notice
  include NoticeUpdates

  # GET /notices or /notices.json
  def index
    @notices = Notice.active.for_role(current_user.role)

    # Apply filters
    @notices = @notices.where(priority: params[:priority]) if params[:priority].present?
    @notices = @notices.where(target_audience: params[:target_audience]) if params[:target_audience].present?

    # Search functionality
    if params[:query].present?
      search_term = "%#{params[:query]}%"
      @notices = @notices.where("title ILIKE ? OR content ILIKE ?", search_term, search_term)
    end

    @notices = @notices.order(published_at: :desc)
  end

  # GET /notices/1 or /notices/1.json
  def show
  end

  # GET /notices/new
  def new
    @notice = Notice.new
  end

  # GET /notices/1/edit
  def edit
  end

  # POST /notices or /notices.json
  def create
    @notice = Notice.new(notice_params)
    @notice.author = current_user

    respond_to do |format|
      if @notice.save
        format.html { redirect_to notice_url(@notice), notice: "Notice was successfully created." }
        format.json { render :show, status: :created, location: @notice }
        format.turbo_stream { flash.now[:notice] = "Notice was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @notice.errors, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /notices/1 or /notices/1.json
  def update
    respond_to do |format|
      if @notice.update(notice_params)
        format.html { redirect_to notice_url(@notice), notice: "Notice was successfully updated." }
        format.json { render :show, status: :ok, location: @notice }
        format.turbo_stream { flash.now[:notice] = "Notice was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @notice.errors, status: :unprocessable_entity }
        format.turbo_stream { render :form_update, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notices/1 or /notices/1.json
  def destroy
    @notice.destroy!

    respond_to do |format|
      format.html { redirect_to notices_url, notice: "Notice was successfully destroyed." }
      format.json { head :no_content }
      format.turbo_stream
    end
  end

  # GET /notices/search
  def search
    @notices = Notice.active.for_role(current_user.role)

    # Apply filters
    @notices = @notices.where(priority: params[:priority]) if params[:priority].present?
    @notices = @notices.where(target_audience: params[:target_audience]) if params[:target_audience].present?

    # Search functionality
    if params[:query].present?
      search_term = "%#{params[:query]}%"
      @notices = @notices.where("title ILIKE ? OR content ILIKE ?", search_term, search_term)
    end

    @notices = @notices.order(published_at: :desc)

    render partial: "notices/notice", collection: @notices, as: :notice
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_notice
      @notice = Notice.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def notice_params
      params.require(:notice).permit(:title, :content, :priority, :notice_type, :target_audience, :grade_levels_array, :published_at, :expires_at, :active)
    end

    # Authorization using Pundit
    def authorize_notice
      authorize Notice
    end
end
