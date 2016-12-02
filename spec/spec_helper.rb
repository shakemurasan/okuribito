require "simplecov"

SimpleCov.start do
  add_filter "/vendor/"
  add_filter "/spec/"
end
