require "okuribito/version"
require "yaml"
require "active_support"
require "active_support/core_ext"
require "net/http"
require "uri"
require "json"
require "logger"

module Okuribito
  class OkuribitoPatch
    CLASS_METHOD_SYMBOL = "."
    INSTANCE_METHOD_SYMBOL = "#"
    PATTERN = /\A(?<symbol>[#{CLASS_METHOD_SYMBOL}#{INSTANCE_METHOD_SYMBOL}])(?<method_name>.+)\z/

    def initialize(options = {})
      @options = options
    end

    module PatchModule
      def disp_console_by_okuribito(method_name, obj_name, caller_info, type)
        case type
        when "plane"
          puts "#{obj_name} : #{method_name} is called."
        when "back_trace"
          puts "#############################################################"
          puts "# #{obj_name} : #{method_name} is called."
          puts "#############################################################"
          puts caller_info
        end
      end

      def notificate_slack_by_okuribito(method_name, obj_name, caller_info, url)
        uri  = URI.parse(url)
        params = {
          text: "OKURIBITO detected a method call.",
          username: "OKURIBITO",
          icon_emoji: ":innocent:",
          attachments: [{
            fields: [{
               title: "#{obj_name}::#{method_name}",
               value: "#{caller_info[0]}",
               short: false
             }]
          }]
        }
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.start do
          request = Net::HTTP::Post.new(uri.path)
          request.set_form_data(payload: params.to_json)
          http.request(request)
        end
      end

      def logging_by_okuribito(symbol, method_name, obj_name, caller_info, log_path)
        logger = Logger.new(log_path)
        logger.formatter = proc{|severity, datetime, progname, message|
          "#{datetime}, #{message}\n"
        }

        logger.info("#{obj_name}#{symbol}#{method_name} : #{caller_info[0]}")
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
        logging_prepended(class_name, observe_methods, @options[:first_prepended]) unless @options[:first_prepended].nil?
      end
    end

    def patch_okuribito(class_name, observe_methods)
      options = @options # スコープを乗り越えるために使用.
      klass = class_name.constantize

      klass.class_eval do
        instance_method_patch = Module.new.extend(PatchModule)
        class_method_patch    = Module.new.extend(PatchModule)
        instance_method_patched = 0
        class_method_patched    = 0

        observe_methods.each do |observe_method|
          next unless md = PATTERN.match(observe_method)
          symbol, method_name = md[:symbol], md[:method_name].to_sym

          case symbol
            when INSTANCE_METHOD_SYMBOL
              next unless klass.instance_methods.include?(method_name)
              instance_method_patch.module_eval do
                define_okuribito_patch(method_name) do |obj_name, caller_info|
                  disp_console_by_okuribito(method_name, obj_name, caller_info, options[:console]) unless options[:console].nil?
                  notificate_slack_by_okuribito(method_name, obj_name, caller_info, options[:slack]) unless options[:slack].nil?
                  logging_by_okuribito(symbol, method_name, obj_name, caller_info, options[:logging]) unless options[:logging].nil?
                end
              end
              instance_method_patched += 1
            when CLASS_METHOD_SYMBOL
              next unless klass.respond_to?(method_name)
              class_method_patch.module_eval do
                define_okuribito_patch(method_name) do |obj_name, caller_info|
                  disp_console_by_okuribito(method_name, obj_name, caller_info, options[:console]) unless options[:console].nil?
                  notificate_slack_by_okuribito(method_name, obj_name, caller_info, options[:slack]) unless options[:slack].nil?
                  logging_by_okuribito(symbol, method_name, obj_name, caller_info, options[:logging]) unless options[:logging].nil?
                end
              end
              class_method_patched += 1
          end
        end
        prepend instance_method_patch if instance_method_patched > 0
        singleton_class.send(:prepend, class_method_patch) if class_method_patched > 0
      end
    end

    def logging_prepended(class_name, observe_methods, log_path)
      # ファイル読み出して、クラス名+メソッド名だけを配列に保持する.
      methods = []
      if File.exist?(log_path)
        File.open(log_path) { |f| methods = f.read.split("\n") }
        methods.slice!(0)
        methods.map! { |m| m.split(",")[1] }
      end

      logger = Logger.new(log_path)
      logger.formatter = proc{|severity, datetime, progname, message|
        "#{datetime},#{message}\n"
      }

      observe_methods.each do |observe_method|
        method_full_name = "#{class_name}#{observe_method}"
        logger.info(method_full_name) unless methods.include?(method_full_name)
      end

    end
  end
end