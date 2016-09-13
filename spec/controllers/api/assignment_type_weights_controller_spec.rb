require "rails_spec_helper"

describe API::AssignmentTypeWeightsController do
  let(:world) { World.create.with(:course, :student, :assignment_type) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "POST create" do
      it "is a protected route" do
        expect(post :create,
               params: { assignment_type_id: world.assignment_type.id, weight: 4 },
               format: :json).to redirect_to(:root)
      end
    end
  end

  context "as student" do
    before(:each) { login_user(world.student) }

    describe "create" do
      it "returns 400 if the assignment type is not weightable" do
        post :create, params: { assignment_type_id: world.assignment_type.id, weight: 4 },
          format: :json
        expect(response.status).to eq(404)
      end

      it "updates the student's weight" do
        world.assignment_type.update(student_weightable: true)
        post :create, params: { assignment_type_id: world.assignment_type.id, weight: 4 },
          format: :json
        expect(world.assignment_type.weight_for_student(world.student)).to eq(4)
      end
    end
  end
end
