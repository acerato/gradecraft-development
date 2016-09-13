require "rails_spec_helper"

describe AssignmentsController do
  before(:all) do
    @course = create(:course)
    @student = create(:user)
    @student.courses << @course
  end
  before(:each) do
    session[:course_id] = @course.id
    allow(Resque).to receive(:enqueue).and_return(true)
  end

  context "as a professor" do
    before(:all) do
      @professor = create(:user)
      CourseMembership.create user: @professor, course: @course, role: "professor"
      @assignment_type = create(:assignment_type, course: @course)
    end

    before(:each) do
      @assignment = create(:assignment, assignment_type: @assignment_type, course: @course)
      login_user(@professor)
    end

    describe "GET index" do
      it "returns assignments for the current course" do
        get :index
        expect(assigns(:assignment_types)).to eq([@assignment_type])
        expect(response).to render_template(:index)
      end
    end

    describe "GET settings" do
      it "returns title and assignments" do
        get :settings
        # TODO: confirm multiple assignments are chronological and alphabetical
        expect(assigns(:assignment_types)).to eq([@assignment_type])
        expect(response).to render_template(:settings)
      end
    end

    describe "GET show" do
      it "returns the assignment show page" do
        get :show, params: { id: @assignment.id }
        expect(response).to render_template(:show)
      end
    end

    describe "POST copy" do
      before(:each) do
        Assignment.delete_all
        @assignment =
          create(:assignment, assignment_type: @assignment_type, course: @course)
      end

      it "duplicates an assignment" do
        post :copy, params: { id: @assignment.id }
        expect expect(@course.assignments.count).to eq(2)
      end

      it "duplicates score levels" do
        @assignment.assignment_score_levels.create(name: "Level 1", points: 10_000)
        post :copy, params: { id: @assignment.id }
        duplicated = Assignment.last
        expect(duplicated.id).to_not eq @assignment.id
        expect(duplicated.assignment_score_levels.first.name).to eq "Level 1"
        expect(duplicated.assignment_score_levels.first.points).to eq 10_000
      end

      it "duplicates rubrics" do
        @assignment.create_rubric
        @assignment.rubric.criteria.create name: "Rubric 1", max_points: 10_000, order: 1
        @assignment.rubric.criteria.first.levels.first.badges.create! name: "Blah", course: @course
        post :copy, params: { id: @assignment.id }
        duplicated = Assignment.last
        expect(duplicated.rubric).to_not be_nil
        expect(duplicated.rubric.criteria.first.name).to eq "Rubric 1"
        expect(duplicated.rubric.criteria.first.levels.first.name).to eq "Full Credit"
        expect(duplicated.rubric.criteria.first.levels.first.level_badges.count).to \
          eq 1
      end

      it "redirects to the edit page for the duplicated assignment" do
        post :copy, params: { id: @assignment.id }
        duplicated = Assignment.last
        expect(response).to redirect_to(edit_assignment_path(duplicated))
      end
    end

    describe "POST create" do
      it "creates the assignment with valid attributes" do
        params = attributes_for(:assignment)
        params[:assignment_type_id] = @assignment_type.id
        expect{ post :create, params: { assignment: params }}.to \
          change(Assignment,:count).by(1)
      end

      it "manages file uploads" do
        Assignment.delete_all
        params = attributes_for(:assignment)
        params[:assignment_type_id] = @assignment_type
        params.merge! assignment_files_attributes: {"0" => {
          "file" => [fixture_file("test_file.txt", "txt")] }}
        post :create, params: { assignment: params }
        assignment = Assignment.where(name: params[:name]).last
        expect expect(assignment.assignment_files.count).to eq(1)
        expect expect(assignment.assignment_files[0].filename).to eq("test_file.txt")
      end

      it "redirects to new from with invalid attributes" do
        expect{ post :create,
                params: { assignment: attributes_for(:assignment, name: nil) }}.to_not \
        change(Assignment,:count)
      end
    end

    describe "POST update" do
      it "updates the assignment" do
        params = { name: "new name" }
        post :update, params: { id: @assignment.id, assignment: params }
        expect(response).to redirect_to(assignments_path)
        expect(@assignment.reload.name).to eq("new name")
      end

      it "updates the usage of rubrics" do
        @assignment.update(use_rubric: false)
        post :update, params: { id: @assignment.id, assignment: { use_rubric: true }},
          format: :json
        expect(@assignment.reload.use_rubric).to eq true
      end

      it "renders the template again if there are validation errors" do
        post :update, params: { id: @assignment.id, assignment: { name: "" }}
        expect(response).to render_template(:edit)
      end

      it "manages file uploads" do
        params = {assignment_files_attributes: {"0" => {"file" => [fixture_file("test_file.txt", "txt")]}}}
        post :update, params: { id: @assignment.id, assignment: params }
        expect expect(@assignment.assignment_files.count).to eq(1)
      end
    end

    describe "POST sort" do
      it "sorts the assignments by params" do
        second_assignment = create(:assignment, assignment_type: @assignment_type)
        @course.assignments << second_assignment

        post :sort, params: { assignment: [second_assignment.id, @assignment.id] }

        expect(@assignment.reload.position).to eq(2)
        expect(second_assignment.reload.position).to eq(1)
      end
    end

    describe "GET export_structure" do
      it "retrieves the export_structure download" do
        get :export_structure, params: { id: @course.id }, format: :csv
        expect(response.body).to include("Assignment ID,Name,Point Total,Description,Open At,Due At,Accept Until")
      end
    end

    describe "GET destroy" do
      it "destroys the assignment" do
        expect{ get :destroy, params: { id: @assignment }}.to \
          change(Assignment,:count).by(-1)
      end
    end
  end

  context "as a student" do
    before(:each) { login_user(@student) }

    describe "GET index" do
      it "returns assignments for the current course" do
        get :index
        expect(response).to render_template(:index)
      end
    end

    describe "GET show" do
      before do
        assignment_type = create(:assignment_type, course: @course)
        @assignment = create(:assignment)
        @course.assignments << @assignment
      end

      it "marks the grade as reviewed" do
        grade = create :grade, assignment: @assignment, student: @student, status: "Graded"
        get :show, params: { id: @assignment.id }
        expect(grade.reload).to be_feedback_reviewed
      end

      it "redirects to the assignments path of the assignment does not exist for the current course" do
        another_assignment = create(:assignment)
        get :show, params: { id: another_assignment.id }
        expect(response).to redirect_to assignments_path
      end
    end

    describe "protected routes" do
      [
        :new,
        :copy,
        :create,
        :sort

      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route).to redirect_to(:root)
        end
      end
    end

    describe "protected routes requiring id in params" do
      [
        :edit,
        :update,
        :destroy
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, params: { id: "1" }).to redirect_to(:root)
        end
      end
    end
  end
end

def predictor_assignment_attributes
  [
    :accepts_submissions,
    :accepts_submissions_until,
    :assignment_type_id,
    :description,
    :due_at,
    :grade_scope,
    :id,
    :include_in_predictor,
    :name,
    :pass_fail,
    :full_points,
    :position,
    :required,
    :use_rubric,
    :visible,
    :visible_when_locked
  ]
end
