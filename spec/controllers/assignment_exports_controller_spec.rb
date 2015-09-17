require 'spec_helper'

RSpec.describe AssignmentExportsController, type: :controller do

  # include rspec helper methods for assignments
  include AssignmentsToolkit

  context "as a professor" do
    before do
      @course = create(:course_accepting_groups)
      @students = []
      create_professor_for_course
      create_assignment_for_course
      create_students_for_course(2)

      login_user(@professor)
      session[:course_id] = @course.id
      allow(Resque).to receive(:enqueue).and_return(true)
    end

    describe "GET export_submissions" do
      before do
        # create an instance of the controller for testing private methods
        @controller = AssignmentExportsController.new

        @student1 = instance_double("Student", first_name: "Ben", last_name: "Bailey", id: 40).as_null_object
        @student2 = instance_double("Student", first_name: "Mike", last_name: "McCaffrey", id: 55).as_null_object
        @student3 = instance_double("Student", first_name: "Dana", last_name: "Dafferty", id: 92).as_null_object

        # create some mock submissions with students attached
        @submission1 = instance_double("Submission", id: 1, student: @student1).as_null_object
        @submission2 = instance_double("Submission", id: 2, student: @student2).as_null_object
        @submission3 = instance_double("Submission", id: 3, student: @student3).as_null_object
        @submission4 = instance_double("Submission", id: 4, student: @student2).as_null_object

        @submissions = [@submission1, @submission2, @submission3, @submission4]
        pp @submissions

        # expectation for #group_submissions_by_student
        @grouped_submission_expectation = {
          "bailey_ben-40" => [@submission1],
          "mccaffrey_mike-55" => [@submission2, @submission4],
          "dafferty_dana-92" => [@submission3]
        }

        @controller.instance_variable_set("@submissions", @submissions)
      end

      context "grouping students" do
        it "should group students by 'last_name_first_name-id'" do
          # finally expect something to happen
          expect(@controller.instance_eval { group_submissions_by_student }).to eq(@grouped_submission_expectation)
        end
      end
    end

    context "export requests", working: true do
      before(:each) do
      end

      describe "before filter behavior" do
        it "should query for the assignment by :assignment_id" do
          expect(Assignment).to receive(:find).with(@assignment[:id])
        end

        it "should return the assignment" do
          # create an instance of the controller for testing private methods
          @controller = AssignmentExportsController.new
          expect(@controller.instance_eval { fetch_assignment }).to eq(@assignment)
        end
      end

      describe "GET submissions", working: true do
        before(:each) do
          get :submissions, { assignment_id: @assignment[:id] }
        end

        it "gets student_submissions from the fetched assignment" do
        end

        it "should restrict access to professors for that class" do
        end
      end

      describe "GET submissions_by_team", working: true do
        before(:each) do
        end

        it "gets student_submissions from the fetched assignment" do
        end

        it "should restrict access to professors for that class" do
        end
      end
    end
  end

end
