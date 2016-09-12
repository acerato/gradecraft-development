require "rails_spec_helper"

describe RubricsController do

  let(:course) { create :course }
  let(:professor) { create(:professor_course_membership, course: course).user }
  let(:student) { create(:student_course_membership, course: course).user }
  let(:assignment) { create(:assignment, course: course) }
  let!(:rubric) { create(:rubric_with_criteria, assignment: assignment) }

  context "as a professor" do
    before do
      session[:course_id] = course.id
      allow(Resque).to receive(:enqueue).and_return(true)
      login_user(professor)
    end

    describe "GET design" do
      it "shows the design form" do
        get :design, params: { assignment_id: @assignment.id, rubric: @rubric}
        expect(response).to render_template(:design)
      end
    end

    describe "GET export" do
      it "retrieves the export download" do
        get :export, params: { assignment_id: assignment.id }, format: :csv
        expect(response.body).to include("Criteria ID,Criteria Description")
      end
    end

    describe "GET index_for_copy" do
      let(:new_assignment) { create(:assignment, course: course) }

      it "retrieves the list of rubric for course to add" do
        get :index_for_copy, assignment_id: new_assignment.id
        expect(assigns(:assignment)).to eq(new_assignment)
        expect(assigns(:rubrics)).to eq([rubric])
      end
    end

    describe "GET copy" do
      let(:new_assignment) { create(:assignment, course: course) }
      let(:full_rubric) { create(:rubric_with_criteria) }

      it "copies the full rubric and adds it to the assignment" do
        post :copy, assignment_id: new_assignment.id, rubric_id: full_rubric.id
        expect(new_assignment.rubric.criteria.pluck(:max_points)).to \
          eq(full_rubric.criteria.pluck(:max_points))
      end
    end
  end

  context "as a student" do
    before { login_user(student) }

    describe "protected routes" do
      [
        :design,
        :create,
        :index_for_copy,
        :copy,
        :destroy,
        :update
      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route, params: { assignment_id: 1, id: "1" }).to redirect_to(:root)
          end
        end
    end
  end
end
