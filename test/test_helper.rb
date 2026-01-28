ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in dependency order so foreign keys resolve (users → classrooms → students).
    fixtures :users, :classrooms, :students

    # Add more helper methods to be used by all tests here...
  end
end
