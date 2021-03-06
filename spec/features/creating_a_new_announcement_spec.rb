require "rails_spec_helper"

feature "creating a new announcement" do
  context "as a professor" do
    let(:course) { create :course }
    let!(:course_membership) { create :professor_course_membership, user: professor, course: course }
    let(:professor) { create :user }

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "unsuccessfully with just a title" do
      within(".sidebar-container") do
        click_link "Announcements"
      end

      within(".context_menu") do
        click_link "New Announcement"
      end

      expect(current_path).to eq new_announcement_path

      within(".pageContent") do
        fill_in "announcement_title", with: "No Exam on Thursday"
        click_button "Send Announcement"
      end

      expect(current_path).to eq announcements_path
      expect(page).to have_content("Body")
    end
  end
end
