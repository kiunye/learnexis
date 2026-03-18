module Transport
  class RoutesController < ApplicationController
    before_action -> { authorize([ :transport, :route ]) }
    before_action :set_transport_route, only: %i[edit update destroy]

    def index
      @transport_routes = TransportRoute.all

      @transport_routes = @transport_routes.where(area: params[:area]) if params[:area].present?
      @transport_routes = @transport_routes.where(active: params[:active]) if params[:active].present?

      if params[:query].present?
        search_term = "%#{params[:query]}%"
        @transport_routes = @transport_routes.where(
          "name LIKE ? OR route_code LIKE ? OR area LIKE ?",
          search_term,
          search_term,
          search_term
        )
      end

      @transport_routes = @transport_routes.order(name: :asc)
    end

    def new
      @transport_route = TransportRoute.new
    end

    def create
      @transport_route = TransportRoute.new(transport_route_params)

      if @transport_route.save
        redirect_to transport_routes_path, notice: "Transport route was successfully created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @transport_route.update(transport_route_params)
        redirect_to transport_routes_path, notice: "Transport route was successfully updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @transport_route.destroy!
      redirect_to transport_routes_path, notice: "Transport route was successfully destroyed."
    end

    private

    def set_transport_route
      @transport_route = TransportRoute.find(params[:id])
    end

    def transport_route_params
      params.require(:transport_route).permit(
        :name,
        :route_code,
        :area,
        :stops,
        :distance_km,
        :monthly_fee,
        :pickup_time,
        :dropoff_time,
        :active
      )
    end
  end
end
