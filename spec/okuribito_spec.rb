# frozen_string_literal: true
require "spec_helper"
require "support/test_target"
require "okuribito"

describe Okuribito do
  let(:setting_path) { "spec/support/good_test_config.yml" }
  let(:dummy_caller) { ["dummy_caller"] }
  let(:output) { StringIO.new }
  let(:option) { {} }

  describe "simple version" do
    before do
      allow_any_instance_of(Kernel).to receive(:caller).and_return(dummy_caller)
      @okuribito = Okuribito::OkuribitoPatch.new(option) do |method_name, obj_name, caller_info, _class_name, _method_symbol|
        output.puts "#{obj_name} #{method_name} #{caller_info[0]}"
      end
    end

    describe "#apply" do
      before do
        @okuribito.apply(setting_path)
      end

      subject { output.string.chomp }

      context "when target class method called" do
        before do
          TestTarget.deprecated_self_method
        end

        it { is_expected.to eq "TestTarget deprecated_self_method #{dummy_caller[0]}" }
      end

      context "when target class method called twice" do
        before do
          TestTarget.deprecated_self_method
          TestTarget.deprecated_self_method
        end

        context "(no option)" do
          it { is_expected.to eq "TestTarget deprecated_self_method #{dummy_caller[0]}\nTestTarget deprecated_self_method #{dummy_caller[0]}" }
        end

        context "(option: once detect)" do
          let(:option) { { once_detect: true } }
          it { is_expected.to eq "TestTarget deprecated_self_method #{dummy_caller[0]}" }
        end
      end

      context "when target instance method called" do
        before do
          TestTarget.new.deprecated_method
        end

        it { is_expected.to match "#<TestTarget:0x[0-9a-f]+> deprecated_method #{dummy_caller[0]}" }
      end

      context "when target instance method called (methods ending in ?)" do
        before do
          TestTarget.new.deprecated_method?
        end

        it { is_expected.to match "#<TestTarget:0x[0-9a-f]+> deprecated_method\\? #{dummy_caller[0]}" }
      end

      context "when target instance method called (methods ending in !)" do
        before do
          TestTarget.new.deprecated_method!
        end

        it { is_expected.to match "#<TestTarget:0x[0-9a-f]+> deprecated_method! #{dummy_caller[0]}" }
      end

      context "when target instance method called twice" do
        let(:test_target) { TestTarget.new }

        before do
          test_target.deprecated_method
          test_target.deprecated_method
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

        before do
          test_target.deprecated_method
        end

        it { is_expected.to match "#<TestModule::TestTarget:0x[0-9a-f]+> deprecated_method #{dummy_caller[0]}" }
      end

      context "when target instance method called (class under nested module)" do
        let(:test_target) { TestModule::NestedTestModule::TestTarget.new }

        before do
          test_target.deprecated_method
        end

        it { is_expected.to match "#<TestModule::NestedTestModule::TestTarget:0x[0-9a-f]+> deprecated_method #{dummy_caller[0]}" }
      end
    end

    describe "#apply_one" do
      subject { output.string.chomp }

      context "when target class method called" do
        before do
          @okuribito.apply_one("TestTarget.deprecated_self_method")
          TestTarget.deprecated_self_method
        end

        it { is_expected.to eq "TestTarget deprecated_self_method #{dummy_caller[0]}" }
      end

      context "when target instance method called" do
        before do
          @okuribito.apply_one("TestTarget#deprecated_method")
          TestTarget.new.deprecated_method
        end

        it { is_expected.to match "#<TestTarget:0x[0-9a-f]+> deprecated_method #{dummy_caller[0]}" }
      end
    end
  end

  describe "functional version" do
    before do
      @okuribito = Okuribito::OkuribitoPatch.new(option) do |method_name, _obj_name, _caller_info, class_name, method_symbol|
        output.puts "#{class_name}#{method_symbol}#{method_name}"
      end
    end

    describe "#apply" do
      before do
        @okuribito.apply(setting_path)
      end

      subject { output.string.chomp }

      context "when target class method called" do
        before do
          TestTarget.deprecated_self_method
        end

        it { is_expected.to eq "TestTarget.deprecated_self_method" }
      end

      context "when target instance method called" do
        context "(normal name)" do
          before do
            TestTarget.new.deprecated_method
          end

          it { is_expected.to eq "TestTarget#deprecated_method" }
        end

        context "(methods ending in ?)" do
          before do
            TestTarget.new.deprecated_method?
          end

          it { is_expected.to eq "TestTarget#deprecated_method?" }
        end

        context "(methods ending in !)" do
          before do
            TestTarget.new.deprecated_method!
          end

          it { is_expected.to eq "TestTarget#deprecated_method!" }
        end
      end

      context "when target instance method called (class under module)" do
        before do
          TestModule::TestTarget.new.deprecated_method
        end

        it { is_expected.to eq "TestModule::TestTarget#deprecated_method" }
      end

      context "when target instance method called (class under nested module)" do
        before do
          TestModule::NestedTestModule::TestTarget.new.deprecated_method
        end

        it { is_expected.to eq "TestModule::NestedTestModule::TestTarget#deprecated_method" }
      end
    end

    describe "#apply_one" do
      subject { output.string.chomp }

      context "when target class method called" do
        before do
          @okuribito.apply_one("TestTarget.deprecated_self_method")
          TestTarget.deprecated_self_method
        end

        it { is_expected.to eq "TestTarget.deprecated_self_method" }
      end

      context "when target instance method called" do
        context "(normal name)" do
          before do
            @okuribito.apply_one("TestTarget#deprecated_method")
            TestTarget.new.deprecated_method
          end

          it { is_expected.to eq "TestTarget#deprecated_method" }
        end
      end

    end

    describe "#patch_okuribito" do
      before do
        @okuribito = Okuribito::OkuribitoPatch.new(option) do |method_name, obj_name, caller_info, _class_name, _method_symbol|
          output.puts "#{obj_name} #{method_name} #{caller_info[0]}"
        end
      end

      context "when target undefined class" do
        subject { @okuribito.send(:patch_okuribito, "UndefinedTestClass", ["#deprecated_method"]) }

        it do
          expect(@okuribito).to receive(:print_undefined_class)
          subject
        end

        it { expect { subject }.not_to raise_error }
      end

      context "when target undefined class method" do
        subject { @okuribito.send(:patch_okuribito, "TestTarget", [".undefined_method"]) }

        it { expect { subject }.not_to raise_error }
      end

      context "when target undefined instance method" do
        subject { @okuribito.send(:patch_okuribito, "TestTarget", ["#undefined_method"]) }

        it { expect { subject }.not_to raise_error }
      end
    end
  end
end
