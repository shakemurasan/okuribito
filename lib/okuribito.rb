require "okuribito/version"
require "yaml"
require "active_support"
require "active_support/core_ext"

module Okuribito
  class OkuribitoPatch
    CLASS_METHOD_SYMBOL = ".".freeze
    INSTANCE_METHOD_SYMBOL = "#".freeze
    PATTERN = /\A(?<symbol>[#{CLASS_METHOD_SYMBOL}#{INSTANCE_METHOD_SYMBOL}])(?<method_name>.+)\z/

    def initialize(opt = {}, &callback)
      @callback = callback
      @opt ||= opt
    end

    module SimplePatchModule
      def define_okuribito_patch(_klass, _id, method_name, _opt = {})
        define_method(method_name) do |*args|
          yield(to_s, caller) if block_given?
          super(*args)
        end
      end
    end

    module FunctionalPatchModule
      def define_okuribito_patch(klass, id, method_name, opt = {})
        klass.instance_variable_set("@#{method_name}_#{id}_called", false)
        define_method(method_name) do |*args|
          if block_given? && !klass.instance_variable_get("@#{method_name}_#{id}_called")
            yield(to_s, caller)
            klass.instance_variable_set("@#{method_name}_#{id}_called", true) if opt[:once_detect]
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
      opt ||= @opt
      klass = class_name.constantize

      klass.class_eval do
        if opt.present?
          instance_method_patch = Module.new.extend(FunctionalPatchModule)
          class_method_patch    = Module.new.extend(FunctionalPatchModule)
        else
          instance_method_patch = Module.new.extend(SimplePatchModule)
          class_method_patch    = Module.new.extend(SimplePatchModule)
        end
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
              define_okuribito_patch(klass, "i", method_name, opt) do |obj_name, caller_info|
                callback.call(method_name, obj_name, caller_info)
              end
            end
            instance_method_patched += 1
          when CLASS_METHOD_SYMBOL
            next unless klass.respond_to?(method_name)
            class_method_patch.module_eval do
              define_okuribito_patch(klass, "c", method_name, opt) do |obj_name, caller_info|
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
