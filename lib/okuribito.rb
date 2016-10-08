require "okuribito/version"
require "yaml"
require "active_support"
require "active_support/core_ext"

module Okuribito
  class OkuribitoPatch
    CLASS_METHOD_SYMBOL = ".".freeze
    INSTANCE_METHOD_SYMBOL = "#".freeze
    PATTERN = /\A(?<symbol>[#{CLASS_METHOD_SYMBOL}#{INSTANCE_METHOD_SYMBOL}])(?<method_name>.+)\z/

    def initialize(&callback)
      @callback = callback
    end

    module PatchModule
      def define_okuribito_patch(method_name)
        instance_variable_set("@#{method_name}_called", false)
        define_method(method_name) do |*args|
          if block_given? && !instance_variable_get("@#{method_name}_called")
            yield(to_s, caller)
            instance_variable_set("@#{method_name}_called", true)
          end
          super(*args)
        end
      end
    end

    def apply(yaml_path)
      yaml = YAML.load_file(yaml_path)
      yaml.each do |class_name, observe_methods|
        patch_okuribito(class_name, observe_methods)
      end
    end

    def patch_okuribito(class_name, observe_methods)
      callback = @callback
      klass = class_name.constantize

      klass.class_eval do
        instance_method_patch = Module.new.extend(PatchModule)
        class_method_patch    = Module.new.extend(PatchModule)
        instance_method_patched = 0
        class_method_patched    = 0

        observe_methods.each do |observe_method|
          next unless md = PATTERN.match(observe_method)
          symbol = md[:symbol]
          method_name = md[:method_name].to_sym

          case symbol
          when INSTANCE_METHOD_SYMBOL
            next unless klass.instance_methods.include?(method_name)
            instance_method_patch.module_eval do
              define_okuribito_patch(method_name) do |obj_name, caller_info|
                callback.call(method_name, obj_name, caller_info)
              end
            end
            instance_method_patched += 1
          when CLASS_METHOD_SYMBOL
            next unless klass.respond_to?(method_name)
            class_method_patch.module_eval do
              define_okuribito_patch(method_name) do |obj_name, caller_info|
                callback.call(method_name, obj_name, caller_info)
              end
            end
            class_method_patched += 1
          end
        end
        prepend instance_method_patch if instance_method_patched > 0
        singleton_class.send(:prepend, class_method_patch) if class_method_patched > 0
      end
    end
  end
end
