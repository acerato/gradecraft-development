require "rails_spec_helper"

describe CoursesController do
  let(:course) { create :course }
  let(:professor) { create(:professor_course_membership, course: course).user }
  let(:admin) { create(:admin_course_membership, course: course).user }
  let(:student) { create(:student_course_membership, course: course).user }

  before(:each) do
    session[:course_id] = course.id
    allow(Resque).to receive(:enqueue).and_return(true)
  end

  context "as admin" do
    it "destroys the course" do
      login_user(admin)
      expect{ get :destroy, params: { id: course }}.to change(Course,:count).by(-1)
    end
  end

  context "as professor" do
    before { login_user(professor) }

    describe "GET index" do
      it "returns all courses the professor has an association with" do
        get :index
        expect(assigns(:courses)).to eq([course])
        expect(response).to render_template(:index)
      end

      # Powers the course search utility
      context "with json format" do
        it "returns all courses in json format" do
          get :index, format: :json
          json = JSON.parse(response.body)
          expect(json.length).to eq 1
          expect(json[0].keys).to eq ["id", "name", "course_number",
                                      "year", "semester"]
        end
      end
    end

    describe "GET show" do
      it "returns the course show page" do
        get :show, params: { id: course.id }
        expect(assigns(:course)).to eq(course)
        expect(response).to render_template(:show)
      end
    end

    describe "GET new" do
      it "assigns title" do
        get :new
        expect(assigns(:course)).to be_a_new(Course)
        expect(response).to render_template(:new)
      end
    end

    describe "GET edit" do
      it "edit title" do
        get :edit, params: { id: course.id }
        expect(assigns(:course)).to eq(course)
        expect(response).to render_template(:edit)
      end
    end

    describe "POST create" do
      it "creates the course with valid attributes"  do
        params = attributes_for(:course)
        params[:id] = course
        expect{ post :create, params: { course: params }}.to change(Course,:count).by(1)
      end

      it "redirects to new from with invalid attributes" do
        expect{ post :create, params: { course: attributes_for(:course, name: nil) }}
          .to_not change(Course,:count)
      end
    end

    describe "GET multiplier_settings" do
      it "gets the form to edit the multiplier settings" do
        get :multiplier_settings, params: { id: course.id }
        expect(assigns(:course)).to eq(course)
        expect(response).to render_template(:multiplier_settings)
      end
    end

    describe "GET custom_terms" do
      it "gets the form to edit custom terms" do
        get :custom_terms, params: { id: course.id }
        expect(assigns(:course)).to eq(course)
        expect(response).to render_template(:custom_terms)
      end
    end

    describe "GET course_details" do
      it "gets the form to edit course details" do
        get :course_details, params: { id: course.id }
        expect(assigns(:course)).to eq(course)
        expect(response).to render_template(:course_details)
      end
    end

    describe "GET player_settings" do
      it "gets the form to edit player settings" do
        get :player_settings, params: { id: course.id }
        expect(assigns(:course)).to eq(course)
        expect(response).to render_template(:player_settings)
      end
    end

    describe "GET student_onboarding_setup" do
      it "gets the form to edit the student onboarding process" do
        get :student_onboarding_setup, params: { id: course.id }
        expect(assigns(:course)).to eq(course)
        expect(response).to render_template(:student_onboarding_setup)
      end
    end

    describe "POST copy" do
      it "creates a duplicate course" do
        expect{ post :copy, params: { id: course.id }}.to change(Course, :count).by(1)
      end

      it "duplicates badges if present" do
        create(:badge, course: course)
        expect{ post :copy, params: { id: course.id }}.to change(Course, :count).by(1)
        course_2 = Course.last
        expect(course_2.badges.present?).to eq(true)
      end

      it "duplicates challenges if present" do
        create(:challenge, course: course)
        expect{ post :copy, params: { id: course.id }}.to change(Course, :count).by(1)
        course_2 = Course.last
        expect(course_2.challenges.present?).to eq(true)
      end

      it "duplicates grade_scheme_elements if present" do
        create(:grade_scheme_element, course: course)
        expect{ post :copy, params: { id: course.id }}.to change(Course, :count).by(1)
        course_2 = Course.last
        expect(course_2.grade_scheme_elements.present?).to eq(true)
      end

      it "duplicates assignment_types and assignments if present" do
        assignment_type = create(:assignment_type, course: course)
        create(:assignment, assignment_type: assignment_type, course: course)
        expect{ post :copy, params: { id: course.id }}.to change(Course, :count).by(1)
        course_2 = Course.last
        expect(course_2.assignment_types.present?).to eq(true)
        expect(course_2.assignments.present?).to eq(true)
      end

      it "duplicates score levels if present" do
        assignment_type = create(:assignment_type, course: course)
        assignment = create(:assignment, assignment_type: assignment_type, course: course)
        score_level = create(:assignment_score_level, assignment: assignment)
        expect{ post :copy, params: { id: course.id }}.to change(Course, :count).by(1)
        course_2 = Course.last
        assignment_2 = course_2.assignments.first
        expect(assignment_2.assignment_score_levels).to be_present
      end

      it "duplicates rubrics if present" do
        assignment_type = create(:assignment_type, course: course)
        badge = create(:badge, course: course, name: "First")
        assignment = create(:assignment, assignment_type: assignment_type, course: course)
        rubric = create(:rubric, assignment: assignment)
        criterion = create(:criterion, rubric: rubric)
        level = create(:level, criterion: criterion)
        level_badge = create(:level_badge, level: level, badge: badge)
        course_2 = Course.last
        assignment_2 = course_2.assignments.first
        rubric_2 = assignment_2.rubric
        criterion_2 = rubric_2.criteria.first
        level_2 = criterion_2.levels.last
        expect{ post :copy, params: { id: course.id }}.to change(Course, :count).by(1)
        expect(assignment_2.rubric.present?).to eq(true)
        expect(rubric_2.criteria.present?).to eq(true)
        expect(criterion_2.levels.present?).to eq(true)
        expect(level_2.level_badges.present?).to eq(true)
      end

      it "assigns the professor to the duplicated course" do
        post :copy, params: { id: course.id }
        duplicated = Course.unscoped.last
        expect(duplicated.course_memberships.count).to eq 1
        expect(duplicated.course_memberships[0].role).to eq "professor"
        expect(duplicated.course_memberships[0].user).to eq professor
      end

      it "redirects to the course edit path if the copy fails" do
        course.update_attribute :full_points, "a"
        post :copy, params: { id: course.id }
        expect(response).to redirect_to edit_course_path(Course.unscoped.last)
      end
    end

    describe "POST copy with students" do
      let(:course_with_students) { create(:student_course_membership, course: course).course }

      it "creates a duplicate course" do
        expect{ post :copy,
                params: { id: course_with_students.id, copy_type: "with_students" }}.to \
        change(Course, :count).by(1)
      end

      it "copies the student" do
        post :copy, params: { id: course_with_students.id, copy_type: "with_students" }
        duplicated = Course.last
        expect(duplicated.students.map(&:id)).to eq course_with_students.students.map(&:id)
      end
    end

    describe "POST update" do
      it "updates the course" do
        params = { name: "new name" }
        post :update, params: { id: course.id, course: params }
        expect(response).to redirect_to(course_path(course))
        expect(course.reload.name).to eq("new name")
      end

      it "redirects to the edit path if the course fails to update" do
        params = { name: "" }
        post :update, params: { id: course.id, course: params }
        expect(response).to render_template(:edit)
      end
    end

    describe "GET destroy" do
      it "raises a not authorized error" do
        expect{ get :destroy, params: { id: course }}.to raise_error CanCan::AccessDenied
      end
    end
  end

  context "as student" do
    before(:each) { login_user(student) }

    describe "GET index" do
      it "returns all courses the student has an association with" do
        get :index
        expect(assigns(:courses)).to eq([course])
        expect(response).to render_template(:index)
      end

      # Powers the course search utility
      context "with json format" do
        it "returns all courses in json format" do
          get :index, format: :json
          json = JSON.parse(response.body)
          expect(json.length).to eq 1
          expect(json[0].keys).to eq ["id", "name", "course_number", "year", "semester"]
        end
      end
    end

    describe "GET change" do

      let(:another_course) { create :course }

      before do
        student.courses << another_course
        login_user(student)
        session[:course_id] = course.id
        allow(Resque).to receive(:enqueue).and_return(true)
      end

      it "switches the course context" do
        get :change, params: { id: another_course.id }
        expect(response).to redirect_to(root_url)
        expect(session[:course_id]).to eq(another_course.id)
      end

      it "records the course login event if the course changed" do
        expect(subject).to receive(:record_course_login_event)
        get :change, params: { id: another_course.id.to_s }
      end

      it "does not record the course login event if the course does not change" do
        expect(subject).to_not receive(:record_course_login_event)
        get :change, params: { id: course.id.to_s }
      end

      it "stores the course to the current course for the user" do
        get :change, params: { id: another_course.id }
        expect(student.reload.current_course_id).to eq another_course.id
      end
    end

    describe "protected routes" do
      [
        :new,
        :create,
        :copy
      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route).to redirect_to(:root)
          end
        end
    end

    describe "protected routes requiring id in params" do
      [
        :edit,
        :show,
        :update,
        :destroy,
        :multiplier_settings,
        :student_onboarding_setup,
        :course_details,
        :custom_terms,
        :player_settings,
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, params: { id: "1" }).to redirect_to(:root)
        end
      end
    end
  end

  context "as a public user" do
    describe "GET badges" do
      it "returns the public badges show page" do
        get :badges, params: { id: course.id }
        expect(assigns(:course)).to eq(course)
        expect(response).to render_template(:badges)
      end

      it "reroutes to the dashboard if course has public badges turned off" do
        course.has_public_badges = false
        course.save
        get :badges, params: { id: course.id }
        expect(response).to redirect_to root_path
      end
    end
  end
end
