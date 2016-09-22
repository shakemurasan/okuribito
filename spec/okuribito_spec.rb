require "spec_helper"
require "pry"
require "support/test_target"

describe Okuribito do
  let(:setting_path) { "spec/support/test_config.yml" }
  let(:dummy_caller) { ["dummy_caller"] }
  let(:okuribito) do
    Okuribito::OkuribitoPatch.new(
      setting
    )
  end

  before do
    allow_any_instance_of(Kernel).to receive(:caller).and_return(dummy_caller)
  end

  describe "console setting" do
    let(:setting) do
      { console: console_setting }
    end

    context "with plain" do
      # TODO: plainでは？
      let (:console_setting) { "plane" }

      before do
        okuribito.apply(setting_path)
      end

      context "when target class method called" do
        it do
          # TODO: stdoutのテストがうまくできない。streamを受け取るインタフェースに変更したい。
          # expect { TestTarget.deprecated_self_method }.to output("TestTarget : deprecated_self_method is called.\n").to_stdout
        end
      end

      context "when target instance method called" do
        let(:target) { TestTarget.new }
        it do
          # TODO: stdoutのテストがうまくできない。streamを受け取るインタフェースに変更したい。
          # expect { target.deprecated_method }.to output("#{target} : deprecated_method is called.\n").to_stdout
        end
      end
    end

    context "with back_trace" do
      let (:console_setting) { "back_trace" }

      before do
        okuribito.apply(setting_path)
      end

      context "when target class method called" do
        it do
          result = <<"EOS"
#############################################################
# TestTarget : deprecated_self_method is called.
#############################################################
#{dummy_caller[0]}
EOS
          # TODO: stdoutのテストがうまくできない。streamを受け取るインタフェースに変更したい。
          # expect { TestTarget.deprecated_self_method }.to output(result).to_stdout
        end
      end

      context "when target instance method called" do
        let(:target) { TestTarget.new }
        it do
          result = <<"EOS"
#############################################################
# #{target} : deprecated_method is called.
#############################################################
#{dummy_caller[0]}
EOS
          # TODO: stdoutのテストがうまくできない。streamを受け取るインタフェースに変更したい。
          # expect { target.deprecated_method }.to output(result).to_stdout
        end
      end
    end
  end

  describe "logging setting" do
    before do
      allow(Logger).to receive(:new).and_return(logger)
      okuribito.apply(setting_path)
    end

    after do
      File.delete(log_path)
    end

    let(:setting) do
      { logging: log_path }
    end
    let(:log_path) { "okuribito_test.log" }
    let(:logger) { Logger.new(log_path) }

    context "when target class method called" do
      it do
        expect(logger).to receive(:info).with("TestTarget.deprecated_self_method : #{dummy_caller[0]}").at_least(1)
        TestTarget.deprecated_self_method
      end
    end

    context "when target instance method called" do
      it do
        target = TestTarget.new
        expect(logger).to receive(:info).with("#{target}#deprecated_method : #{dummy_caller[0]}").at_least(1)
        target.deprecated_method
      end
    end
  end

  describe "first_prepended setting" do
    before do
      allow(Logger).to receive(:new).and_return(logger)
    end

    after do
      File.delete(log_path)
    end

    let(:setting) do
      { first_prepended: log_path }
    end
    let(:log_path) { "okuribito_first_prepend_test.log" }
    let(:logger) { Logger.new(log_path) }

    context "when it was called at first" do
      it do
        expect(logger).to receive(:info).with("TestTarget.deprecated_self_method").once
        expect(logger).to receive(:info).with("TestTarget#deprecated_method").once
        okuribito.apply(setting_path)
        # TODO: 2回目はログが出力されないというテストがうまく書けない。ログ出力がされないからだ。
      end
    end
  end
end
