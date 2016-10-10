require "light-service"
require "active_record_spec_helper"
require "./app/services/group_services/iterates_creates_grade_using_rubric"

describe Services::Actions::IteratesCreatesGradeUsingRubric do
  let(:world) { World.create.with(:course, :professor, :student, :assignment, :rubric, :criterion, :criterion_grade, :badge, :group) }
  let(:group_params) {{ "group_id" => world.group.id }}
  let(:graded_by_id) { 1 }
  let(:raw_params) { RubricGradePUT.new(world).params.merge group_params }

  it "expects raw_params" do
    expect { described_class.execute group: world.group, graded_by_id: graded_by_id }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "expects a group" do
    expect { described_class.execute raw_params: raw_params, graded_by_id: graded_by_id }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "expects a graded_by_id" do
    expect { described_class.execute raw_params: raw_params, group: world.group }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "iterates over the students in group" do
    expect(Services::CreatesGradeUsingRubric).to receive(:create).exactly(world.group.students.count).times.and_call_original
    described_class.execute raw_params: raw_params, group: world.group, graded_by_id: graded_by_id
  end

  it "adds the group id to the context" do
    result = described_class.execute raw_params: raw_params, group: world.group, graded_by_id: graded_by_id
    expect(result[:attributes]["group_id"]).to eq(world.group.id)
  end
end
