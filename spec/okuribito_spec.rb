# frozen_string_literal: true
require "spec_helper"
require "support/test_target"

describe Okuribito do
  let(:setting_path) { "spec/support/test_config.yml" }
  let(:dummy_caller) { ["dummy_caller"] }
  let(:output) { StringIO.new }
  let(:option) { {} }

  before do
    allow_any_instance_of(Kernel).to receive(:caller).and_return(dummy_caller)
    okuribito = Okuribito::OkuribitoPatch.new(option) do |method_name, obj_name, caller_info|
      output.puts "#{obj_name} #{method_name} #{caller_info[0]}"
    end
    okuribito.apply(setting_path)
  end

  describe "#define_okuribito_patch" do
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
  end
end
