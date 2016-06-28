require "rails_spec_helper"

feature "viewing submission history" do
  let!(:submission) do
    create :submission, course: membership.course, assignment: assignment, student: student
  end
  let(:assignment) do
    create :assignment, accepts_submissions: true, course: membership.course
  end
  let(:membership) { create :student_course_membership, user: student }
  let(:student) { create :user }

  context "as a professor" do
    let(:professor) { create :user }
    let!(:professor_membership) { create :professor_course_membership, user: professor, course: membership.course }

    before { login_as professor }

    scenario "with some history" do
      previous_comment = submission.text_comment
      PaperTrail.whodunnit = student.id
      submission.update_attributes text_comment: "This is an updated comment"
      visit assignment_submission_path assignment, submission
      find("a", text: "Submission History").click do
        expect(page).to have_content "#{student.name} changed the text comment from \"#{previous_comment}\" to \"This is an updated comment\""
      end
    end
  end

  context "as a student" do
    before { login_as student }

    scenario "with some history" do
      PaperTrail.whodunnit = student.id
      submission.update_attributes link: "http://example.org"
      visit assignment_path assignment
      find("a", text: "Submission History").click do
        expect(page).to have_content "You changed the link to \"http://example.org\""
      end
    end
  end
end
