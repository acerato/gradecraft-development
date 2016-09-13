require "rails_spec_helper"

describe API::CriterionGradesController do
  let(:world) { World.create.with(:course, :student, :assignment, :rubric, :criterion, :level, :criterion_grade, :badge) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "GET index" do
      it "returns a student's criterion grades for the current assignment" do
        get :index,
          params: { assignment_id: world.assignment.id, student_id: world.student.id },
          format: :json
        expect(assigns(:criterion_grades)).to eq([world.criterion_grade])
        expect(response).to render_template(:index)
      end
    end

    describe "GET group_index" do
      before(:each) do
        world.create_group
        world.group.students.each do |student|
          world.create_criterion_grade(assignment_id: world.assignment.id, student_id: student.id)
        end
      end

      it "returns 400 error code with individual assignment" do
        world.assignment.update_attributes grade_scope: "Individual"
        get :group_index,
          params: { assignment_id: world.assignment.id, group_id: world.group.id },
          format: :json
        expect(response.status).to be(400)
      end

      it "returns criterion_grades and student ids for a group" do
        world.assignment.update_attributes grade_scope: "Group"
        get :group_index,
          params: { assignment_id: world.assignment.id, group_id: world.group.id },
          format: :json
        expect(assigns(:student_ids)).to eq(world.group.students.pluck(:id))
        expect(assigns(:criterion_grades).length).to eq(world.group.students.length)
        expect(response).to render_template(:group_index)
      end
    end

    describe "PUT update" do
      let(:params) do
        RubricGradePUT.new(world).params.merge(assignment_id: world.assignment.id, student_id: world.student.id)
      end

      describe "finds or creates the grade for the assignment and student" do
        it "finds and updates existing grades" do
          create(:grade, assignment: world.assignment, student: world.student)
          expect { put :update, params: params }.to change { Grade.count }.by(0)
        end

        it "assigns the grade to the submission" do
          submission = create :submission, assignment: world.assignment, student: world.student
          put :update, params: params
          grade = Grade.unscoped.last
          expect(grade.submission).to eq submission
        end

        it "timestamps the grade" do
          current_time = DateTime.now
          put :update, params: params
          grade = Grade.unscoped.last
          expect(grade.graded_at).to be > current_time
        end
      end

      describe "when an additional `criterion_ids` parameter is supplied" do
        before do
          params[:criterion_ids] = world.rubric.criteria.collect(&:id)
        end

        it "does not create new when criterion grades exist" do
          expect { put :update, params: params }.to change { CriterionGrade.count }.by(0)
        end
      end

      it "adds earned level badges" do
        world.badge.update(can_earn_multiple_times: false)
        expect { put :update, params: params }.to change { EarnedBadge.count }.by(1)
      end

      it "doesn't re-award existing level badges" do
        expect { put :update, params: params }.to change { EarnedBadge.count }.by(1)
        expect { put :update, params: params }.to change { EarnedBadge.count }.by(0)
      end

      it "renders success message when request format is JSON" do
        put :update, params: params
        expect(JSON.parse(response.body)).to eq("message" => "Grade successfully saved", "success" => true)
      end

      describe "on error" do
        it "describes unfound student or assignment" do
          params["student_id"] = 0
          put :update, params: params
          expect(JSON.parse(response.body)).to eq("errors"=>[{"detail"=>"Unable to verify both student and assignment"}], "success"=>false)
          expect(response.status).to eq(404)
        end
      end
    end

    describe "PUT group_update" do
      let(:world) { World.create.with(:course, :student, :assignment, :rubric, :criterion, :criterion_grade, :badge, :group) }
      let(:params) do
        RubricGradePUT.new(world).params.merge(assignment_id: world.assignment.id, group_id: world.group.id)
      end

      it "updates the grade for all students in group" do
        target = params["grade"]["raw_points"]
        put :group_update, params: params
        expect(Grade.where(
          student_id: world.group.students.pluck(:id), assignment_id: world.assignment.id
        ).pluck(:raw_points)).to eq([target, target, target, target])
      end

      it "adds the group id to all grades" do
        target = world.group.id
        put :group_update, params: params
        expect(Grade.where(
          student_id: world.group.students.pluck(:id), assignment_id: world.assignment.id
        ).pluck(:group_id)).to eq([target, target, target, target])
      end
    end
  end

  context "as student" do
    before(:each) { login_user(world.student) }

    it "redirects protected routes to root" do
      [
        -> { get :index,
             params: { assignment_id: world.assignment.id, student_id: world.student.id },
             format: :json },
        -> { get :group_index, params: { assignment_id: world.assignment.id, group_id: 1 },
             format: :json },
        -> { put :update,
             params: RubricGradePUT.new(world).params
              .merge(assignment_id: world.assignment.id, student_id: world.student.id) }
      ].each do |protected_route|
        expect(protected_route.call).to redirect_to(:root)
      end
    end
  end
end
