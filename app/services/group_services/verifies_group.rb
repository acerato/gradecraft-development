module Services
  module Actions
    class VerifiesGroup
      extend LightService::Action

      expects :attributes
      promises :group

      executed do |context|
        begin
          context.group = Group.find(context[:attributes]["group_id"])
        rescue ActiveRecord::RecordNotFound
          context.fail!("Unable to find group", error_code: 404)
          next context
        end
      end
    end
  end
end
