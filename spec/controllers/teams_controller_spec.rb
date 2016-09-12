require "rails_spec_helper"

describe TeamsController do
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
    before(:each) do
      @team = create(:team, course: @course)
      login_user(@professor)
    end

    describe "GET index" do
      it "returns all teams for the current course" do
        get :index
        expect(assigns(:teams)).to eq(@course.reload.teams)
        expect(response).to render_template(:index)
      end
    end

    describe "GET show" do
      it "returns the team show page" do
        get :show, params: { id: @team.id }
        expect(assigns(:team)).to eq(@team)
        expect(response).to render_template(:show)
      end
    end

    describe "GET new" do
      it "assigns a name" do
        get :new
        expect(assigns(:team)).to be_a_new(Team)
        expect(response).to render_template(:new)
      end
    end

    describe "GET edit" do
      it "assigns name " do
        get :edit, params: { id: @team.id }
        expect(assigns(:team)).to eq(@team)
        expect(response).to render_template(:edit)
      end
    end

    describe "POST create" do
      it "creates the team with valid attributes"  do
        params = attributes_for(:team)
        params[:id] = @team
        expect{ post :create, params: { team: params }}.to change(Team,:count).by(1)
      end

      it "redirects to new from with invalid attributes" do
        expect{ post :create, params: { team: attributes_for(:team, name: nil) }}.to_not change(Team,:count)
      end
    end

    describe "POST update" do
      it "updates the team" do
        params = { name: "new name" }
        post :update, params: { id: @team.id, team: params }
        expect(response).to redirect_to(team_path(@team))
        expect(@team.reload.name).to eq("new name")
      end
    end

    describe "GET destroy" do
      it "destroys the team" do
        expect{ get :destroy, params: { id: @team }}.to change(Team,:count).by(-1)
      end
    end
  end

  context "as a student" do
    before(:all) do
      @student = create(:user)
      @student.courses << @course
    end

    before(:each) { login_user(@student) }

    describe "GET index" do
      it "assigns the student's team and renders the index" do
        @team = create(:team, course: @course)
        @student.teams << @team
        get :index
        expect(assigns(:team)).to eq(@team)
        expect(response).to render_template(:index)
      end
    end

    describe "protected routes" do
      [
        :new,
        :create
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
        :destroy
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, params: { id: "10" }).to redirect_to(:root)
        end
      end
    end
  end
end
