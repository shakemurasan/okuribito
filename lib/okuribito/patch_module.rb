module Okuribito
  module SimplePatchModule
    private

    def define_patch(method_name, _patch, _id, _opt = {})
      define_method(method_name) do |*args|
        yield(to_s, caller) if block_given?
        super(*args)
      end
    end
  end

  module FunctionalPatchModule
    private

    def define_patch(method_name, patch, id, opt = {})
      sn = method_name.to_s.gsub(/\?/, "__q").gsub(/!/, "__e").gsub(/=/, "__eq")
      patch.instance_variable_set("@#{sn}_#{id}_called", false)
      define_method(method_name) do |*args|
        if block_given? && !patch.instance_variable_get("@#{sn}_#{id}_called")
          yield(to_s, caller)
          patch.instance_variable_set("@#{sn}_#{id}_called", true) if opt[:once_detect]
        end
        super(*args)
      end
    end
  end
end
