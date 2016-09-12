require "rails_spec_helper"

describe CriteriaController do
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
      it "creates a new criterion" do
        assignment = create(:assignment, course: @course)
        rubric = create(:rubric, assignment: assignment)
        post :create, params: { criterion: { max_points: 100, name: "Test", order: 1, rubric_id: rubric.id }}
        criterion = Criterion.unscoped.last
        expect(criterion.name).to eq "Test"
      end
    end

    describe "GET destroy" do
      it "destroys a criterion" do
        @criterion = create(:criterion)
        expect{ get :destroy, params: { id: @criterion }}.to \
          change(Criterion,:count).by(-1)
      end
    end

    describe "POST update" do
      it "updates a criterion" do
        @criterion = create(:criterion)
        params = { name: "new name" }
        post :update, params: { id: @criterion.id, criterion: params }
        expect(@criterion.reload.name).to eq("new name")
      end
    end

    describe "POST update_order" do
      it "changes the order of the criteria for the rubric" do
        @rubric = create(:rubric)
        @criterion = create(:criterion, order: 0, rubric: @rubric)
        @criterion_2 = create(:criterion, order: 1, rubric: @rubric)
        params = {"criterion_order"=>{"#{@criterion.id}"=>{"order"=>1}, "#{@criterion_2.id}"=>{"order"=>0} } }
        post :update_order, params: params
        expect(@criterion.reload.order).to eq(1)
        expect(@criterion_2.reload.order).to eq(0)
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
        :create,
        :update_order
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route).to redirect_to(:root)
        end
      end
    end

    describe "protected routes requiring id parameter" do
      [
        :destroy,
        :update
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, params: { id: 1 }).to redirect_to(:root)
        end
      end
    end
  end
end
