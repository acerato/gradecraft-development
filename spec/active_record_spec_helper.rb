RSpec.configure do |config|
  # if we're loading more than one spec file just load the rails spec helper to
  # save us from eternal suffering. However right now we're polluting inclusions
  # with :focus on every call, and need to either remove config.filter_run from
  # /spec/spec_helper or implement config.filter_run_when_matching with rspec
  # v3.5.0.beta2 or greater
  #
  inclusions = config.filter_manager.inclusions.rules.keys - [:focus]
  exclusions = config.filter_manager.exclusions
  if config.files_to_run.size > 1 && inclusions.empty? && exclusions.empty?
    require "rails_spec_helper"
  end
end

require "spec_helper"
require "active_record"
require "active_support/core_ext"
require "acts_as_list"
require "aws-sdk"
require "cancan"
require "carrierwave"
require "carrierwave/orm/activerecord"
require "csv"
require "factory_girl"
require "faker"
require "sanitize"
require "sorcery"
require "yaml"
require "./app/proctors/grade_proctor"
require "./lib/model_addons/advanced_rescue"
require "./lib/model_addons/improved_logging"
require "./lib/s3_manager"
require_relative "support/sorcery_stubbing"
require_relative "support/file_helpers"
require_relative "support/world"

# stub out the process_in_background for carrierwave_backgrounder
module CarrierWave
  module Backgrounder
    module Delay; end
  end
end

class ActiveRecord::Base
  def self.process_in_background(_); end
end

SorceryStubbing.sorcery_reset [:user_activation], user_activation_mailer: SorceryStubbing::TestUserMailer

connection_info = YAML.load_file("config/database.yml")["test"]
ActiveRecord::Base.establish_connection(connection_info)

require "paper_trail"
require "paper_trail/frameworks/rspec"

# stub out Rails.env
unless defined?(Rails)
  module Rails
    def self.env
      ENV["RAILS_ENV"]
    end
  end
end

Dir["./app/uploaders/*.rb"].each { |f| require f }
Dir["./app/validators/*.rb"].each { |f| require f }
Dir["./app/proctors/*.rb"].each { |f| require f }
Dir["./app/models/concerns/*.rb"].each { |f| require f }
Dir["./app/models/*.rb"].each { |f| require f }

CarrierWave.configure do |config|
  config.storage = :file
  config.enable_processing = false
end

# Uploader classes for which #store_dir shouldn't be overwritten
AttachmentUploader

CarrierWave::Uploader::Base.descendants.each do |klass|
  next if klass.anonymous?
  klass.class_eval do
    def cache_dir
      File.join(File.dirname(__FILE__), "support/uploads/tmp")
    end

    # this will be conditionally used in the uploader to sidestep issues with
    # testing the output of SomeUploader#store_dir directly
    def store_dir_prefix
      case Rails.env
      when "development"
        ENV["AWS_S3_DEVELOPER_TAG"]
      when "test"
        "#{File.dirname(__FILE__)}/support"
      end
    end
  end
end

FactoryGirl::SyntaxRunner.send(:include, FileHelpers)

RSpec.configure do |config|

  config.include FileHelpers
  config.include FactoryGirl::Syntax::Methods

  config.before(:suite) do
    FactoryGirl.factories.clear
    FactoryGirl.find_definitions
  end

  config.around do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end
end
