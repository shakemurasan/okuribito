require 'spec_helper'

class TargetClass
  def self.self_method
  end

  def self.unused_self_method
  end

  def method
  end

  def unused_method
  end
end

describe Okuribito do
  describe "#apply" do
    before do
      okuribito = Okuribito::OkuribitoPatch.new(
        {
          console: "back_trace",
          logging: "tmp/okuribito_test.log",
          first_prepended: "log/okuribito/first_prepended.log"
        }
      )
      okuribito.apply("spec/support/test_config.yml")
    end

    context "with static used method" do
      it do
        logger = double("Logger", info: nil)
        expect(logger).to have_recieved(:info).with(an_instance_of(String))
      end
    end
  end
end
