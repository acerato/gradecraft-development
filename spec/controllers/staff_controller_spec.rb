require "rails_spec_helper"

describe StaffController do
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
    before { login_user(@professor) }

    describe "GET index" do
      it "returns all staff for the current course" do
        get :index
        expect(assigns(:staff)).to eq([@professor])
        expect(response).to render_template(:index)
      end
    end

    describe "GET show" do
      it "displays a single staff member's page" do
        get :show, params: { id: @professor.id }
        expect(assigns(:staff_member)).to eq(@professor)
        expect(response).to render_template(:show)
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
        :index
      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route).to redirect_to(:root)
          end
        end
    end

    describe "protected routes requiring id in params" do
      [
        :show
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, params: { id: "1" }).to redirect_to(:root)
        end
      end
    end
  end
end
