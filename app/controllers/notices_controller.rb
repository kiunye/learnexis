class NoticesController < ApplicationController
  before_action :set_notice, only: %i[show edit update destroy]
  before_action :authorize_notice
  include NoticeUpdates

  # GET /notices or /notices.json
  def index
    @notices = filtered_notices
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

    respond_with_notice_save(
      ok: @notice.save,
      ok_status: :created,
      ok_notice: "Notice was successfully created.",
      error_template: :new
    )
  end

  # PATCH/PUT /notices/1 or /notices/1.json
  def update
    respond_with_notice_save(
      ok: @notice.update(notice_params),
      ok_status: :ok,
      ok_notice: "Notice was successfully updated.",
      error_template: :edit
    )
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
    @notices = filtered_notices

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

    def filtered_notices
      scope = Notice.active.for_role(current_user.role)
      scope = scope.where(priority: params[:priority]) if params[:priority].present?
      scope = scope.where(target_audience: params[:target_audience]) if params[:target_audience].present?

      if params[:query].present?
        search_term = "%#{params[:query]}%"
        scope = scope.where("title LIKE ? OR content LIKE ?", search_term, search_term)
      end

      scope.order(published_at: :desc)
    end

    def respond_with_notice_save(ok:, ok_status:, ok_notice:, error_template:)
      respond_to do |format|
        if ok
          format.html { redirect_to notice_url(@notice), notice: ok_notice }
          format.json { render :show, status: ok_status, location: @notice }
          format.turbo_stream
        else
          format.html { render error_template, status: :unprocessable_entity }
          format.json { render json: @notice.errors, status: :unprocessable_entity }
          format.turbo_stream { render :form_update, status: :unprocessable_entity }
        end
      end
    end
end
