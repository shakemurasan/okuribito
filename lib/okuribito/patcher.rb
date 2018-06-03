require "okuribito/patch_module"

module Okuribito
  class Patcher
    CLASS_METHOD_SYMBOL = ".".freeze
    INSTANCE_METHOD_SYMBOL = "#".freeze
    PATTERN = /\A(?<symbol>[#{CLASS_METHOD_SYMBOL}#{INSTANCE_METHOD_SYMBOL}])(?<method_name>.+)\z/

    def initialize(opt, callback)
      @opt = opt
      @callback = callback
    end

    def patch_okuribito(full_class_name, observe_methods)
      opt = @opt
      callback = @callback
      klass = full_class_name.safe_constantize
      unless klass
        process_undefined_class(full_class_name)
        return
      end
      uniq_constant = full_class_name.gsub(/::/, "Sp")
      i_method_patch = patch_module("#{uniq_constant}InstancePatch")
      c_method_patch = patch_module("#{uniq_constant}ClassPatch")
      i_method_patched = 0
      c_method_patched = 0

      klass.class_eval do
        observe_methods.each do |observe_method|
          next unless (md = PATTERN.match(observe_method))
          symbol = md[:symbol]
          method_name = md[:method_name].to_sym

          case symbol
          when INSTANCE_METHOD_SYMBOL
            next unless klass.instance_methods.include?(method_name)
            i_method_patch.module_eval do
              define_patch(method_name, i_method_patch, "i", opt) do |obj_name, caller_info|
                callback.call(method_name, obj_name, caller_info, full_class_name, symbol)
              end
            end
            i_method_patched += 1
          when CLASS_METHOD_SYMBOL
            next unless klass.respond_to?(method_name)
            c_method_patch.module_eval do
              define_patch(method_name, c_method_patch, "c", opt) do |obj_name, caller_info|
                callback.call(method_name, obj_name, caller_info, full_class_name, symbol)
              end
            end
            c_method_patched += 1
          end
        end
        prepend i_method_patch if i_method_patched > 0
        singleton_class.send(:prepend, c_method_patch) if c_method_patched > 0
      end
    end

    def patch_module(patch_name)
      if @opt.present?
        if FunctionalPatchModule.const_defined?(patch_name)
          Module.new.extend(FunctionalPatchModule)
        else
          FunctionalPatchModule.const_set(patch_name, Module.new.extend(FunctionalPatchModule))
        end
      else
        Module.new.extend(SimplePatchModule)
      end
    end

    def process_undefined_class(_full_class_name)
      # do nothing....
    end
  end
end
