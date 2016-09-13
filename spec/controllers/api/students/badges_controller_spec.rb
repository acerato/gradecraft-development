require "rails_spec_helper"

describe API::Students::BadgesController do
  let(:world) { World.create.with(:course, :student, :badge) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "GET index" do
      before do
        allow(controller).to receive(:current_course).and_return(world.course)
        allow(controller).to receive(:current_user).and_return(professor)
      end

      it "assigns the badges with no call to update" do
        get :index, params: { student_id: world.student.id }, format: :json
        expect(assigns(:student)).to eq(world.student)
        predictor_badge_attributes do |attr|
          expect(assigns(:badges)[0][attr]).to eq(world.badge[attr])
        end
        expect(assigns(:update_badges)).to be_falsey
        expect(response).to render_template("api/badges/index")
      end

      it "assigns the student's earned badges" do
        earned_badge = create(
          :earned_badge, badge: world.badge,
          student: world.student, course: world.course, student_visible: true)
        get :index, format: :json, student_id: world.student.id
        expect(assigns(:earned_badges)).to eq([earned_badge])
      end
    end
  end

  # helper methods:
  def predictor_badge_attributes
    [
      :id,
      :name,
      :description,
      :full_points,
      :visible,
      :visible_when_locked,
      :can_earn_multiple_times,
      :position,
      :icon
    ]
  end
end
