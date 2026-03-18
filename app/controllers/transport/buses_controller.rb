module Transport
  class BusesController < ApplicationController
    before_action -> { authorize([ :transport, :bus ]) }
    before_action :set_bus, only: %i[edit update destroy]

    def index
      @buses = Bus.all

      @buses = @buses.where(active: params[:active]) if params[:active].present?

      if params[:query].present?
        search_term = "%#{params[:query]}%"
        @buses = @buses.where(
          "bus_number LIKE ? OR registration_number LIKE ? OR driver_name LIKE ?",
          search_term,
          search_term,
          search_term
        )
      end

      @buses = @buses.order(bus_number: :asc)
    end

    def new
      @bus = Bus.new
    end

    def create
      @bus = Bus.new(bus_params)

      if @bus.save
        redirect_to transport_buses_path, notice: "Bus was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @bus.update(bus_params)
        redirect_to transport_buses_path, notice: "Bus was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @bus.destroy!
      redirect_to transport_buses_path, notice: "Bus was successfully destroyed."
    end

    private

    def set_bus
      @bus = Bus.find(params[:id])
    end

    def bus_params
      params.require(:bus).permit(
        :bus_number,
        :registration_number,
        :capacity,
        :driver_name,
        :driver_phone,
        :driver_license_number,
        :insurance_expiry,
        :last_maintenance_date,
        :next_maintenance_date,
        :active
      )
    end
  end
end
