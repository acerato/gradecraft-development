require "rails_spec_helper"

describe LevelBadgesController do
  before(:all) { @course = create(:course) }
  before(:each) do
    session[:course_id] = @course.id
    allow(Resque).to receive(:enqueue).and_return(true)
  end

  context "as a professor" do
    before(:all) do
      @professor = create(:user)
      CourseMembership.create user: @professor, course: @course, role: "professor"
    end

    before(:each) { login_user(@professor) }

    describe "POST create" do
      it "creates a new level badge" do
        level = create :level
        badge = create :badge
        params = attributes_for(:level_badge).merge(level_id: level.id, badge_id: badge.id)
        expect{ post :create, params: { level_badge: params }}.to change(LevelBadge,:count).by(1)
      end
    end

    describe "GET destroy" do
      it "destroys a level badge" do
        @level_badge = create(:level_badge)
        expect{ get :destroy, params: { id: @level_badge } }.to change(LevelBadge,:count).by(-1)
      end
    end
  end

  context "as a student" do
    before(:all) do
      @student = create(:user)
      @student.courses << @course
    end
    before(:each) { login_user(@student) }

    describe "protected routes" do
      [
        :create
      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route).to redirect_to(:root)
          end
        end
    end

    describe "protected routes requiring id in params" do
      [
        :destroy
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, params: { id: "10" }).to redirect_to(:root)
        end
      end
    end
  end
end
