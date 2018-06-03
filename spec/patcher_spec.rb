# frozen_string_literal: true
require "spec_helper"
require "okuribito"

describe Okuribito::Patcher do
  let(:option) { {} }
  let(:callback) { proc { |method_name, _obj_name, _caller_info, class_name, method_symbol| output.puts "#{class_name}#{method_symbol}#{method_name}" } }
  let(:patcher) { Okuribito::Patcher.new(option, callback) }

  describe "#patch_okuribito" do
    context "when target undefined class" do
      subject { patcher.patch_okuribito("UndefinedTestClass", ["#deprecated_method"]) }

      it do
        expect(patcher).to receive(:process_undefined_class)
        expect { subject }.not_to raise_error
      end
    end

    context "when target undefined class method" do
      subject { patcher.patch_okuribito("TestTarget", [".undefined_method"]) }

      it { expect { subject }.not_to raise_error }
    end

    context "when target undefined instance method" do
      subject { patcher.patch_okuribito("TestTarget", ["#undefined_method"]) }

      it { expect { subject }.not_to raise_error }
    end
  end
end
