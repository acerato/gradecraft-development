require "rails_spec_helper"
include SessionHelper

describe API::AssignmentsController do
  let(:course) { create :course}
  let(:student)  { create(:student_course_membership, course: course).user }
  let(:professor) { create(:professor_course_membership, course: course).user }
  let(:assignment) { create(:assignment) }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "GET index" do
      before do
        allow(controller).to receive(:current_course).and_return(course)
        allow(controller).to receive(:current_user).and_return(professor)
      end

      context "with no student" do
        it "assigns student as null student and no call to update" do
          get :index, format: :json
          expect(assigns(:assignments).student.class).to eq(NullStudent)
        end
      end
    end
  end

  context "as student" do
    before do
      login_user(student)
      allow(controller).to receive(:current_course).and_return(course)
    end

    describe "GET index" do
      it "assigns the attributes with call to update" do
        get :index, format: :json, id: student.id
        expect(assigns(:assignments).class).to eq(PredictedAssignmentCollectionSerializer)
        expect(response).to render_template(:index)
      end
    end

    describe "PUT update" do
      it "updates the predicted points for a grade" do
        predicted_earned_grade = create(:predicted_earned_grade, assignment: assignment, student: student)
        predicted_points = (assignment.full_points * 0.75).to_i
        put :update, id: predicted_earned_grade.id, predicted_points: predicted_points, format: :json
        expect(PredictedEarnedGrade.where(student: student, assignment: assignment).first.predicted_points).to eq(predicted_points)
        expect(JSON.parse(response.body)).to eq({"id" => predicted_earned_grade.id, "predicted_points" => predicted_points})
      end

      it "renders a 404 if prediction not found" do
        put :update, id: 0, predicted_points: 0, format: :json
        expect(response.status).to eq(404)
      end
    end
  end

  context "as faculty previewing as student" do
    before do
      login_as_impersonating_agent(professor, student)
      allow(controller).to receive(:current_course).and_return(course)
    end

    describe "GET index" do
      it "assigns the professor and not student as user" do
        get :index, format: :json
        expect(assigns(:assignments).current_user).to eq(professor)
      end
    end
  end

  # helper methods:
  def predictor_challenge_attributes
    [
      :id,
      :name,
      :description,
      :full_points,
      :visible
    ]
  end
end
