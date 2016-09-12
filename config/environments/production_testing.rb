GradeCraft::Application.configure do
  config.action_controller.default_url_options = { :host => "localhost:5000" }
  config.action_controller.perform_caching = false
  config.action_dispatch.x_sendfile_header = "X-Accel-Redirect"
  config.action_dispatch.default_headers = { "X-Frame-Options" => "ALLOWALL" }
  config.asset_host = "http://localhost:5000"
  config.action_mailer.default_url_options = { :host => "localhost:5000" }
  config.action_mailer.delivery_method = :smtp
  config.active_support.deprecation = :notify
  config.assets.compile = false
  config.assets.precompile += %w( vendor/modernizr.js )
  config.assets.compress = true
  config.assets.css_compressor = :sass
  config.assets.digest = true
  config.assets.js_compressor = Uglifier.new(mangle: false) if defined? Uglifier
  config.assets.paths << Rails.root.join("app", "assets", "fonts")
  config.assets.precompile += %w( .svg .eot .woff .ttf )
  config.cache_classes = false
  config.consider_all_requests_local = true
  config.eager_load = true
  config.i18n.fallbacks = true
  config.log_formatter = ::Logger::Formatter.new
  config.log_level = :info
  config.public_file_server.enabled = false
  config.session_store :active_record_store, :expire_after => 60.minutes
end

CarrierWave.configure do |config|
  config.storage = :file
end
