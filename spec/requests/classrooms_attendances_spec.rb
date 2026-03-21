# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Classroom attendances", type: :request do
  include RequestHelpers

  let(:teacher) { create(:user, :as_teacher) }
  let(:classroom) do
    Classroom.create!(
      name: "Attendance Spec #{SecureRandom.hex(3)}",
      grade_level: 4,
      section: "B",
      academic_year: Date.current.year,
      capacity: 30,
      room_number: "401",
      class_teacher: teacher
    )
  end
  let(:student) { create(:student, classroom: classroom) }

  before { sign_in_as(teacher) }

  describe "PATCH /classrooms/:id/attendances" do
    it "persists indexed attendances[] form params" do
      patch classroom_attendances_path(classroom), params: {
        date: Date.current,
        attendances: {
          "0" => { student_id: student.id, status: "absent", remarks: "Test" }
        }
      }

      expect(response).to redirect_to(classroom_attendances_path(classroom, date: Date.current))
      att = student.attendances.find_by!(attendance_date: Date.current)
      expect(att.status).to eq("absent")
      expect(att.classroom_id).to eq(classroom.id)
      expect(att.marked_by_id).to eq(teacher.id)
    end
  end
end
