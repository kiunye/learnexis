# frozen_string_literal: true

require "flipper"

Flipper.configure do |config|
  config.adapter do
    if Rails.env.test?
      Flipper::Adapters::Memory.new
    else
      require "flipper/adapters/active_record"
      Flipper::Adapters::ActiveRecord.new
    end
  end
end
