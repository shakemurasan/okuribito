require 'spec_helper'
require 'pry'

class TestTarget
  def self.unused_self_method
  end

  def unused_method
  end
end

describe Okuribito do
  let(:setting_path) { "spec/support/test_config.yml" }
  let(:dummy_caller) { ["dummy_caller"] }
  let(:okuribito) {
    @o ||= Okuribito::OkuribitoPatch.new(
        setting
    )
    @o.apply(setting_path)
    @o
  }

  before do
    allow_any_instance_of(Kernel).to receive(:caller).and_return(dummy_caller)
    okuribito
  end

  describe "console setting" do
    let(:setting) {
      { console: console_setting }
    }

    before do
      #allow(okuribito).to receive(:puts)
      #allow_any_instance_of(Kernel).to receive(:puts).and_return(nil)
    end

    context "with plain" do
      # TODO: plainでは？
      let (:console_setting) { "plane" }
      context "when target class method called " do
        it do
          expect { TestTarget.unused_self_method }.to output("TestTarget : unused_self_method is called.\n").to_stdout
        end
      end

      context "when target instance method called" do
        let(:target) { TestTarget.new }
        it do
          # TODO:なんか2回呼ばれてない？
          expect { target.unused_method }.to output("#{target.to_s} : unused_method is called.\n" * 2).to_stdout
        end
      end
    end

    # TODO:単体で動かすと動くのだが…
    context "with back_trace" do
      let (:console_setting) { "back_trace" }
      context "when target class method called" do
        it do
          result = <<"EOS"
#############################################################
# TestTarget : unused_self_method is called.
#############################################################
#{dummy_caller[0]}
EOS
          expect { TestTarget.unused_self_method }.to output(result).to_stdout
        end
      end

      context "when target instance method called" do
        let(:target) { TestTarget.new }
        it do
          result = <<"EOS"
#############################################################
# #{target.to_s} : unused_method is called.
#############################################################
#{dummy_caller[0]}
EOS
          # TODO:なんか2回呼ばれてない？
          expect { target.unused_method }.to output(result * 2).to_stdout
        end
      end
    end
  end

  describe "logging setting" do
    before do
      allow(Logger).to receive(:new).and_return(logger)
    end

    let(:setting) {
      { logging: log_path }
    }
    let(:log_path) { "okuribito_test.log" }
    let(:logger) { Logger.new(log_path) }

    context "when target class method called" do
      it do
        expect(logger).to receive(:info).with("TestTarget.unused_self_method : #{dummy_caller[0]}").at_least(1)
        TestTarget.unused_self_method
      end
    end

    context "when target instance method called" do
      it do
        target = TestTarget.new
        expect(logger).to receive(:info).with("#{target.to_s}#unused_method : #{dummy_caller[0]}").at_least(1)
        target.unused_method
      end
    end
  end
end
