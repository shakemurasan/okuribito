require "okuribito/patcher"
require "yaml"

module Okuribito
  class Request
    def initialize(opt = {}, &callback)
      @patcher = Patcher.new(opt, callback)
    end

    def apply(yaml_path)
      yaml = YAML.load_file(yaml_path)
      yaml.each do |class_name, observe_methods|
        @patcher.patch_okuribito(class_name, observe_methods)
      end
    end

    def apply_one(full_method_name)
      class_name, symbol, method_name = full_method_name.split(/(\.|#)/)
      @patcher.patch_okuribito(class_name, [symbol + method_name])
    end
  end
end
