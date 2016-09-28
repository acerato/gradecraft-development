require "light-service"
require "./app/services/group_services/verifies_group"

describe Services::Actions::VerifiesGroup do
  let(:raw_params) { { "group_id" => 1000 } }

  it "fails if the group is not found" do
    result = described_class.execute attributes: raw_params
    expect(result.message).to eq("Unable to find group")
  end
end
