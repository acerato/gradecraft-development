require "rails_spec_helper"

describe API::Grades::GradeFilesController do
  let(:world) { World.create.with(:course, :student, :assignment, :grade) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "POST create" do
      it "adds upload file to grade" do
        grade_file = fixture_file("Too long, strange characters, and Spaces (In) Name.jpg", "img/jpg")
        post :create, params: { grade_id: world.grade.id, grade_files: [grade_file] },
          format: :json
        expect(world.grade.grade_files.count).to eq(1)
      end
    end
  end

  context "as student" do
    before(:each) { login_user(world.student) }

    describe "POST create" do
      it "is a protected route" do
        expect(post :create, params: { grade_id: world.grade.id }, format: :json).to \
          redirect_to(:root)
      end
    end
  end
end
