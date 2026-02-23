ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "json"

module TestViteBuild
  module_function

  REQUIRED_ENTRIES = [
    "entrypoints/application.css",
    "entrypoints/inertia.tsx"
  ].freeze

  def ensure_built!
    return unless defined?(ViteRuby)

    lock_path = Rails.root.join("tmp/vite-test-build.lock")
    lock_path.dirname.mkpath

    File.open(lock_path, File::RDWR | File::CREAT, 0o644) do |lock|
      lock.flock(File::LOCK_EX)
      ViteRuby.commands.build unless manifest_ready?
    end
  end

  def manifest_ready?
    manifest_path = Rails.root.join("public/vite-test/.vite/manifest.json")
    return false unless manifest_path.exist?

    manifest = JSON.parse(manifest_path.read)
    REQUIRED_ENTRIES.all? { |entry| manifest.key?(entry) }
  rescue JSON::ParserError
    false
  end
end

TestViteBuild.ensure_built!

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
