require "okuribito/version"
require "yaml"
require "active_support"
require "active_support/core_ext"
require "net/http"
require "uri"
require "json"

module Okuribito
  class OkuribitoPatch
    CLASS_METHOD_SYMBOL = "."
    INSTANCE_METHOD_SYMBOL = "#"
    PATTERN = /\A(?<symbol>[#{CLASS_METHOD_SYMBOL}#{INSTANCE_METHOD_SYMBOL}])(?<method_name>.+)\z/
    WEB_HOOK_URL = "https://hooks.slack.com/services/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"
    CONSOLE   = true
    END_POINT = false
    LOGGING   = false

    module PatchModule
      def disp_console_by_okuribito(method_name, obj_name, caller_info)
        return unless CONSOLE
        puts "#############################################################"
        puts "# #{obj_name} : #{method_name} is called."
        puts "#############################################################"
        puts caller_info
      end

      def notificate_end_point_by_okuribito(method_name, obj_name, caller_info)
        return unless END_POINT
        uri  = URI.parse(WEB_HOOK_URL)
        params = { text: "#{obj_name}, #{method_name} : #{caller_info[0]}" }
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.start do
          request = Net::HTTP::Post.new(uri.path)
          request.set_form_data(payload: params.to_json)
          http.request(request)
        end
      end

      def define_okuribito_patch(method_name)
        define_method(method_name) do |*args|
          yield(self.to_s, caller) if block_given?
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
      class_name.constantize.class_eval do
        instance_method_patch = Module.new.extend(PatchModule)
        class_method_patch    = Module.new.extend(PatchModule)
        instance_method_patched = 0
        class_method_patched    = 0

        observe_methods.each do |observe_method|
          next unless md = PATTERN.match(observe_method)
          symbol, method_name = md[:symbol], md[:method_name].to_sym

          case symbol
            when INSTANCE_METHOD_SYMBOL
              instance_method_patch.module_eval do
                define_okuribito_patch(method_name) do |obj_name, caller_info|
                  disp_console_by_okuribito(method_name, obj_name, caller_info)
                  notificate_end_point_by_okuribito(method_name, obj_name, caller_info)
                end
              end
              instance_method_patched += 1
            when CLASS_METHOD_SYMBOL
              class_method_patch.module_eval do
                define_okuribito_patch(method_name) do |obj_name, caller_info|
                  disp_console_by_okuribito(method_name, obj_name, caller_info)
                  notificate_end_point_by_okuribito(method_name, obj_name, caller_info)
                end
              end
              class_method_patched += 1
          end
        end
        prepend instance_method_patch if instance_method_patched > 0
        singleton_class.prepend class_method_patch if class_method_patched > 0
      end
    end
  end
end