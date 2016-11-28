# frozen_string_literal: true
$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "okuribito"
require "simplecov"
require "codeclimate-test-reporter"

SimpleCov.start do
  add_filter "/vendor/"
  add_filter "/spec/"

  formatter SimpleCov::Formatter::MultiFormatter[
              SimpleCov::Formatter::HTMLFormatter,
              CodeClimate::TestReporter::Formatter
            ]
end
