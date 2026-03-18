class EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy register unregister attendees]
  before_action :authorize_event

  # GET /events or /events.json
  def index
    @events = filtered_events
  end

  # GET /events/1 or /events/1.json
  def show
    @event_registration = @event.event_registrations.find_by(user: current_user)
  end

  # GET /events/search
  def search
    @events = filtered_events

    render partial: "events/event", collection: @events, as: :event
  end

  # GET /events/new
  def new
    @event = Event.new
  end

  # GET /events/1/edit
  def edit
  end

  # POST /events or /events.json
  def create
    @event = Event.new(event_params)
    @event.organizer = current_user

    respond_with_event_save(
      ok: @event.save,
      ok_status: :created,
      ok_notice: "Event was successfully created.",
      error_template: :new
    )
  end

  # PATCH/PUT /events/1 or /events/1.json
  def update
    respond_with_event_save(
      ok: @event.update(event_params),
      ok_status: :ok,
      ok_notice: "Event was successfully updated.",
      error_template: :edit
    )
  end

  # DELETE /events/1 or /events/1.json
  def destroy
    @event.destroy!

    respond_to do |format|
      format.html { redirect_to events_url, notice: "Event was successfully destroyed." }
      format.json { head :no_content }
      format.turbo_stream
    end
  end

  # POST /events/1/register
  def register
    @event_registration = @event.event_registrations.new(user: current_user)

    respond_with_registration_save
  end

  # DELETE /events/1/unregister
  def unregister
    @event_registration = @event.event_registrations.find_by(user: current_user)
    @event_registration.destroy if @event_registration

    respond_to do |format|
      format.html { redirect_to event_url(@event), notice: "You have successfully unregistered from this event." }
      format.json { head :no_content }
      format.turbo_stream
    end
  end

  # GET /events/1/attendees
  def attendees
    @attendees = @event.participants
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def event_params
      params.require(:event).permit(:title, :description, :event_type, :start_datetime, :end_datetime, :location, :registration_required, :max_participants)
    end

    # Authorization using Pundit
    def authorize_event
      authorize Event
    end

    def filtered_events
      scope = Event.upcoming
      scope = scope.where(event_type: params[:event_type]) if params[:event_type].present?

      if params[:query].present?
        search_term = "%#{params[:query]}%"
        scope = scope.where("title LIKE ? OR description LIKE ?", search_term, search_term)
      end

      scope.order(start_datetime: :asc)
    end

    def respond_with_event_save(ok:, ok_status:, ok_notice:, error_template:)
      respond_to do |format|
        if ok
          format.html { redirect_to event_url(@event), notice: ok_notice }
          format.json { render :show, status: ok_status, location: @event }
          format.turbo_stream
        else
          format.html { render error_template, status: :unprocessable_entity }
          format.json { render json: @event.errors, status: :unprocessable_entity }
          format.turbo_stream { render :form_update, status: :unprocessable_entity }
        end
      end
    end

    def respond_with_registration_save
      respond_to do |format|
        if @event_registration.save
          format.html { redirect_to event_url(@event), notice: "You have successfully registered for this event." }
          format.json { render :show, status: :created }
          format.turbo_stream
        else
          format.html { render :show, status: :unprocessable_entity }
          format.json { render json: @event_registration.errors, status: :unprocessable_entity }
          format.turbo_stream { render :form_update, status: :unprocessable_entity }
        end
      end
    end
end
