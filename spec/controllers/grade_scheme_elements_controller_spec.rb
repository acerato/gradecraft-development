require "rails_spec_helper"

describe GradeSchemeElementsController do
  before(:all) { @course = create(:course) }
  before(:each) do
    session[:course_id] = @course.id
    allow(Resque).to receive(:enqueue).and_return(true)
  end

  context "as professor" do
    before(:all) do
      @professor = create(:user)
      CourseMembership.create user: @professor, course: @course, role: "professor"
    end

    before(:each) do
      @grade_scheme_element = create(:grade_scheme_element, letter: "A", course: @course)
      login_user(@professor)
    end

    describe "GET index" do
      it "assigns all grade scheme elements" do
        get :index
        expect(assigns(:grade_scheme_elements)).to eq([@grade_scheme_element])
      end
    end

    describe "GET edit" do
      it "renders the edit grade scheme form" do
        get :edit, params: { id: @grade_scheme_element.id }
        expect(assigns(:grade_scheme_element)).to eq(@grade_scheme_element)
        expect(response).to render_template(:edit)
      end
    end

    describe "PUT update" do
      it "updates the grade scheme element" do
        grade_scheme_element_params = { letter: "B" }
        put :update, params: { id: @grade_scheme_element.id, grade_scheme_element: grade_scheme_element_params }
        expect(@grade_scheme_element.reload.letter).to eq("B")
      end
    end

    describe "GET mass_edit" do
      it "shows the mass edit form" do
        get :mass_edit
        expect(assigns(:grade_scheme_elements)).to eq(@course.grade_scheme_elements)
      end
    end

    describe "PUT mass_update" do
      it "updates the grade scheme elements all at once" do
        params = { "grade_scheme_elements_attributes" => [{
          id: @grade_scheme_element.id, letter: "C", level: "Sea Slug", lowest_points: 0,
          highest_points: 100000, course_id: @course.id }, { id: GradeSchemeElement.new.id,
          letter: "B", level: "Snail", lowest_points: 100001, highest_points: 200000,
          course_id: @course.id }], "deleted_ids"=>nil, "grade_scheme_element"=>{} }
        put :mass_update, params: params.merge(format: :json)
        expect(@course.reload.grade_scheme_elements.count).to eq(2)
        expect(@grade_scheme_element.reload.level).to eq("Sea Slug")
      end

      it "does not save the changes if invalid" do
        @grade_scheme_element_2 = create(:grade_scheme_element, course: @course)
        params = { "grade_scheme_elements_attributes" => [{
          id: @grade_scheme_element.id, letter: "C", level: "Sea Slugs Galore", lowest_points: 0,
          highest_points: 100010, course_id: @course.id }, { id: GradeSchemeElement.new.id,
          letter: "B", level: "Snail", lowest_points: 100011, highest_points: nil,
          course_id: @course.id}], "deleted_ids"=>nil, "grade_scheme_element"=>{} }
        put :mass_update, params: params.merge(format: :json)
        expect(@grade_scheme_element.reload.highest_points).to eq(100000)
        expect(response.status).to eq(500)
      end
    end

    describe "GET export_structure" do
      it "retrieves the export_structure download" do
        get :export_structure, params: { id: @course.id }, format: :csv
        expect(response.body).to include("Level ID,Letter Grade,Level Name,Lowest Points,Highest Points")
      end
    end
  end

  context "as student" do
    before(:all) do
      @student = create(:user)
      @student.courses << @course
    end
    before(:each) do
      login_user(@student)
    end

    describe "GET index" do
      it "assigns all grade scheme elements" do
        @grade_scheme_element = create(:grade_scheme_element, letter: "A", course: @course)
        get :index
        expect(assigns(:grade_scheme_elements)).to eq([@grade_scheme_element])
      end
    end

    describe "protected routes" do
      [
        :mass_edit,
        :mass_update
      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route).to redirect_to(:root)
          end
        end
    end
  end
end
