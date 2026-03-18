module Transport
  class TransportController < ApplicationController
    before_action -> { authorize([ :transport, :assignment ]) }

    def assignments
      @students = Student.all
      @transport_routes = TransportRoute.active

      if params[:transport_route_id].present?
        @transport_route = TransportRoute.find(params[:transport_route_id])
        @students = @students.where(transport_route_id: params[:transport_route_id])
      end

      if params[:query].present?
        search_term = "%#{params[:query]}%"
        @students = @students.joins(:user).where(
          "students.admission_number LIKE ? OR users.first_name LIKE ? OR users.last_name LIKE ?",
          search_term,
          search_term,
          search_term
        )
      end
    end

    def assign_student
      @student = Student.find(params[:student_id])
      @transport_route = TransportRoute.find(params[:transport_route_id])

      if @student.update(transport_route_id: @transport_route.id)
        redirect_to transport_assignments_path(transport_route_id: @transport_route.id),
                    notice: "Student was successfully assigned to the route."
      else
        redirect_to transport_assignments_path(transport_route_id: @transport_route.id),
                    alert: "Failed to assign student to route."
      end
    end

    def unassign_student
      @student = Student.find(params[:student_id])

      if @student.update(transport_route_id: nil)
        redirect_to transport_assignments_path, notice: "Student was successfully unassigned from the route."
      else
        redirect_to transport_assignments_path, alert: "Failed to unassign student from route."
      end
    end
  end
end
