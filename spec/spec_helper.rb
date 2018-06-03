# frozen_string_literal: true
require "simplecov"

SimpleCov.start do
  add_filter "/vendor/"
  add_filter "/spec/"
end
