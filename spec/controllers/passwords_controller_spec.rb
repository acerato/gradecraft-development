require "rails_spec_helper"

describe PasswordsController do
  describe "GET new" do
    it "exists" do
      get :new
      expect(response).to be_success
    end
  end

  describe "POST create" do
    let(:user) { create :user }

    it "creates a password reset token for the user" do
      post :create, params: { email: user.email }
      expect(user.reload.reset_password_token).to_not be_nil
    end

    it "sends the user an email with password reset instructions" do
      expect { post :create, params: { email: user.email.upcase }}.to \
        change { ActionMailer::Base.deliveries.count }.by 1
      expect(response).to redirect_to root_path
    end
  end

  describe "GET edit" do
    let(:user) { create :user, reset_password_token: "blah" }

    it "exists" do
      get :edit, params: { id: user.reset_password_token }
      expect(response).to be_success
    end

    it "redirects to the password reset url if the token is not correct" do
      get :edit, params: { id: "blech" }
      expect(response).to redirect_to new_password_path
    end

    it "redirects to the password reset url if the token has expired" do
      user.update_attribute :reset_password_token_expires_at, 1.hour.ago
      get :edit, params: { id: user.reset_password_token }
      expect(response).to redirect_to new_password_path
    end
  end

  describe "PUT update" do
    let(:user) { create :user, reset_password_token: "blah" }

    context "with matching passwords" do
      it "changes the user's password" do
        put :update, params: { id: user.reset_password_token,
          token: user.reset_password_token,
          user: { password: "blah", password_confirmation: "blah" }}
        expect(User.authenticate(user.email, "blah")).to eq user
      end

      it "activates the user if they are not activated" do
        user.update_attribute(:activation_state, "pending")
        put :update, params: { id: user.reset_password_token,
          token: user.reset_password_token,
          user: { password: "blah", password_confirmation: "blah" }}
        expect(user.reload).to be_activated
      end

      it "logs the user in" do
        put :update, params: { id: user.reset_password_token,
          token: user.reset_password_token,
          user: { password: "blah", password_confirmation: "blah" }}
        expect(response).to redirect_to dashboard_path
      end
    end

    context "with a tampered password reset token" do
      before do
        put :update, params: { id: user.reset_password_token,
          token: "tampered",
          user: { password: "blah", password_confirmation: "blah" }}
      end

      it "does not change the user's password" do
        expect(User.authenticate(user.email, "blah")).to be_nil
      end

      it "redirects to the password reset url" do
        expect(response).to redirect_to new_password_path
      end
    end

    context "with non-matching password" do
      before do
        put :update, params: { id: user.reset_password_token,
          token: user.reset_password_token,
          user: { password: "blah", password_confirmation: "blech" }}
      end

      it "does not change the user's password" do
        expect(User.authenticate(user.email, "blah")).to be_nil
      end

      it "renders the edit template with the error" do
        expect(response).to render_template :edit
      end
    end

    context "with a blank password" do
      before do
        put :update, params: { id: user.reset_password_token,
          token: user.reset_password_token,
          user: { password: "", password_confirmation: "" }}
      end

      it "does not change the user's password" do
        expect(User.authenticate(user.email, "")).to be_nil
      end

      it "renders the edit template with the error" do
        expect(response).to render_template :edit
      end
    end
  end
end
