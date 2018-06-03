# frozen_string_literal: true
require "spec_helper"
require "support/test_target"
require "okuribito"

describe Okuribito::Request do
  let(:setting_path) { "spec/support/good_test_config.yml" }
  let(:dummy_caller) { ["dummy_caller"] }
  let(:output) { StringIO.new }
  let(:option) { {} }
  let(:request) { Okuribito::Request.new(option, &callback) }
  let(:callback) { proc { |method_name, obj_name, caller_info, _class_name, _method_symbol| output.puts "#{obj_name} #{method_name} #{caller_info[0]}" } }

  describe "simple version" do
    before do
      allow_any_instance_of(Kernel).to receive(:caller).and_return(dummy_caller)
    end

    describe "#apply" do
      before { request.apply(setting_path) }

      subject { output.string.chomp }

      context "when target class method called" do
        before { TestTarget.deprecated_self_method }

        it { is_expected.to eq "TestTarget deprecated_self_method #{dummy_caller[0]}" }
      end

      context "when target class method called twice" do
        before { 2.times { TestTarget.deprecated_self_method } }

        context "(no option)" do
          it { is_expected.to eq "TestTarget deprecated_self_method #{dummy_caller[0]}\nTestTarget deprecated_self_method #{dummy_caller[0]}" }
        end

        context "(option: once detect)" do
          let(:option) { { once_detect: true } }

          it { is_expected.to eq "TestTarget deprecated_self_method #{dummy_caller[0]}" }
        end
      end

      context "when target instance method called" do
        before { TestTarget.new.deprecated_method }

        it { is_expected.to match "#<TestTarget:0x[0-9a-f]+> deprecated_method #{dummy_caller[0]}" }
      end

      context "when target instance method called (methods ending in ?)" do
        before { TestTarget.new.deprecated_method? }

        it { is_expected.to match "#<TestTarget:0x[0-9a-f]+> deprecated_method\\? #{dummy_caller[0]}" }
      end

      context "when target instance method called (methods ending in !)" do
        before { TestTarget.new.deprecated_method! }

        it { is_expected.to match "#<TestTarget:0x[0-9a-f]+> deprecated_method! #{dummy_caller[0]}" }
      end

      context "when target instance method called twice" do
        let(:test_target) { TestTarget.new }

        before do
          2.times { test_target.deprecated_method }
          TestTarget.new.deprecated_method
        end

        context "(no option)" do
          it { is_expected.to match "#<TestTarget:0x[0-9a-f]+> deprecated_method #{dummy_caller[0]}\n" }
        end

        context "(option: once detect)" do
          let(:option) { { once_detect: true } }

          it { is_expected.to match "#<TestTarget:0x[0-9a-f]+> deprecated_method #{dummy_caller[0]}" }
          it { is_expected.not_to match "#<TestTarget:0x[0-9a-f]+> deprecated_method #{dummy_caller[0]}\n" }
        end
      end

      context "when target instance method called (class under module)" do
        let(:test_target) { TestModule::TestTarget.new }

        before { test_target.deprecated_method }

        it { is_expected.to match "#<TestModule::TestTarget:0x[0-9a-f]+> deprecated_method #{dummy_caller[0]}" }
      end

      context "when target instance method called (class under nested module)" do
        let(:test_target) { TestModule::NestedTestModule::TestTarget.new }

        before { test_target.deprecated_method }

        it { is_expected.to match "#<TestModule::NestedTestModule::TestTarget:0x[0-9a-f]+> deprecated_method #{dummy_caller[0]}" }
      end
    end

    describe "#apply_one" do
      subject { output.string.chomp }

      context "when target class method called" do
        before do
          request.apply_one("TestTarget.deprecated_self_method")
          TestTarget.deprecated_self_method
        end

        it { is_expected.to eq "TestTarget deprecated_self_method #{dummy_caller[0]}" }
      end

      context "when target instance method called" do
        before do
          request.apply_one("TestTarget#deprecated_method")
          TestTarget.new.deprecated_method
        end

        it { is_expected.to match "#<TestTarget:0x[0-9a-f]+> deprecated_method #{dummy_caller[0]}" }
      end
    end
  end

  describe "functional version" do
    let(:callback) { proc { |method_name, _obj_name, _caller_info, class_name, method_symbol| output.puts "#{class_name}#{method_symbol}#{method_name}" } }

    describe "#apply" do
      before { request.apply(setting_path) }

      subject { output.string.chomp }

      context "when target class method called" do
        before { TestTarget.deprecated_self_method }

        it { is_expected.to eq "TestTarget.deprecated_self_method" }
      end

      context "when target instance method called" do
        context "(normal name)" do
          before { TestTarget.new.deprecated_method }

          it { is_expected.to eq "TestTarget#deprecated_method" }
        end

        context "(methods ending in ?)" do
          before { TestTarget.new.deprecated_method? }

          it { is_expected.to eq "TestTarget#deprecated_method?" }
        end

        context "(methods ending in !)" do
          before { TestTarget.new.deprecated_method! }

          it { is_expected.to eq "TestTarget#deprecated_method!" }
        end
      end

      context "when target instance method called (class under module)" do
        before { TestModule::TestTarget.new.deprecated_method }

        it { is_expected.to eq "TestModule::TestTarget#deprecated_method" }
      end

      context "when target instance method called (class under nested module)" do
        before { TestModule::NestedTestModule::TestTarget.new.deprecated_method }

        it { is_expected.to eq "TestModule::NestedTestModule::TestTarget#deprecated_method" }
      end
    end

    describe "#apply_one" do
      subject { output.string.chomp }

      context "when target class method called" do
        before do
          request.apply_one("TestTarget.deprecated_self_method")
          TestTarget.deprecated_self_method
        end

        it { is_expected.to eq "TestTarget.deprecated_self_method" }
      end

      context "when target instance method called" do
        context "(normal name)" do
          before do
            request.apply_one("TestTarget#deprecated_method")
            TestTarget.new.deprecated_method
          end

          it { is_expected.to eq "TestTarget#deprecated_method" }
        end
      end
    end
  end
end
