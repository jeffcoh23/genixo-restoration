require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module GenixoRestoration
  class Application < Rails::Application
    config.load_defaults 8.0

    config.autoload_lib(ignore: %w[assets tasks])

    # Use Solid Queue for background jobs
    config.active_job.queue_adapter = :solid_queue

    # deliver_later runs through our MailDeliveryJob (retries transient SMTP
    # failures) instead of the retry-less ActionMailer default.
    config.action_mailer.delivery_job = "MailDeliveryJob"
  end
end
