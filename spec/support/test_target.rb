# frozen_string_literal: true
class TestTarget
  def self.deprecated_self_method; end

  def deprecated_method; end

  def deprecated_method?; end

  def deprecated_method!; end
end

module TestModule
  module NestedTestModule
    class TestTarget
      def deprecated_method; end
    end
  end

  class TestTarget
    def deprecated_method; end
  end
end
