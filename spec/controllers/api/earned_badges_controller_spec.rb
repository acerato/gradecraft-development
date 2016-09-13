require "rails_spec_helper"

describe API::EarnedBadgesController do
  let(:world) { World.create.with(:course, :student, :grade, :badge) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "POST create" do
      it "creates a new student badge from params" do
          params = { earned_badge:
                     { badge_id: world.badge.id, student_id: world.student.id }}
          expect{ post :create, params: params.merge(format: :json) }.to \
            change {EarnedBadge.count}.by(1)
        end
    end

    describe "DELETE destroy" do
      it "deletes a badge" do
        earned_badge = create(:earned_badge, grade: world.grade, student: world.student)
        params = { id: earned_badge.id }
        expect { delete :destroy, params: params }.to \
          change { EarnedBadge.count }.by(-1)
        expect(JSON.parse(response.body)).to \
          eq({"message"=>"Earned badge successfully deleted", "success"=>true})
      end

      it "renders error if no badge found to delete" do
        params = { id: 1234 }
        delete :destroy, params: params
        expect(JSON.parse(response.body)).to \
          eq({"message" => "Earned badge failed to delete", "success" => false})
      end
    end
  end
end
