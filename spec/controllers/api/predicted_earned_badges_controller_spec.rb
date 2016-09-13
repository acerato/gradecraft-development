require "rails_spec_helper"
include SessionHelper

describe API::PredictedEarnedBadgesController do
  let(:world) { World.create.with(:course, :student, :badge) }

  context "as student" do
    before(:each) { login_user(world.student) }

    describe "PUT update" do
      it "updates the predicted times earned for a badge" do
        peb = create(:predicted_earned_badge, badge: world.badge, student: world.student)
        predicted_times_earned = 4
        put :update,
          params: { id: peb.id, predicted_times_earned: predicted_times_earned },
          format: :json
        expect(PredictedEarnedBadge.where(student: world.student, badge: world.badge).first.predicted_times_earned).to eq(4)
        expect(JSON.parse(response.body)).to eq({"id" => peb.id, "predicted_times_earned" => predicted_times_earned})
      end
    end
  end
end
