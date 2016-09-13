require "rails_spec_helper"

describe Assignments::StudentsController do
  let(:world) { World.create.with(:course, :assignment, :professor, :student) }

  describe "#grade" do

    context "as a professor" do
      before(:each) { login_user(world.professor) }

      it "creates the grade for the assignment and student if it doesn't exist" do
        post :grade, params: { assignment_id: world.assignment.id,
                               student_id: world.student.id }

        grade = Grade.unscoped.last
        expect(grade.assignment_id).to eq world.assignment.id
        expect(grade.student_id).to eq world.student.id
      end

      it "redirects to the edit grade view" do
        post :grade, params: { assignment_id: world.assignment.id,
                               student_id: world.student.id }

        expect(response).to redirect_to edit_grade_path(Grade.unscoped.last)
      end
    end

    context "as a student" do
      before(:each) { login_user(world.student) }

      it "redirects to the root" do
        post :grade, params: { assignment_id: world.assignment.id,
                               student_id: world.student.id }

        expect(response).to redirect_to root_path
      end
    end
  end
end
