require "rails_spec_helper"

describe AuthorizationsController do
  describe "GET #create" do
    context "as a professor" do
      let(:canvas_auth_hash) do
        {
          provider: provider,
          credentials: {
            token: "BLAH",
            refresh_token: "REFRESH",
            expires_at: expires_at.to_i,
            expires: true
          }
        }.deep_stringify_keys
      end
      let(:expires_at) { Time.now + (30 * 24 * 60 * 60) }
      let(:professor) { professor_membership.user }
      let(:professor_membership) { create :professor_course_membership }
      let(:provider) { :canvas }

      before do
        request.env["omniauth.auth"] = canvas_auth_hash
        login_user(professor)
      end

      context "for a new authorization" do
        it "creates the authorization for the user and provider" do
          get :create, params: { provider: provider }

          authorization = UserAuthorization.unscoped.last

          expect(authorization).to_not be_nil
          expect(authorization.user_id).to eq professor.id
        end

        it "redirects back to the referrer" do
          session[:return_to] = courses_path

          get :create, params: { provider: provider }

          expect(response).to redirect_to courses_path
        end
      end
    end
  end
end
