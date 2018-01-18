require "hbw/version"

module HBW
  class ArgumentError < ::ArgumentError; end

  class << self
    # @overload
    #
    # @param [Exception] exception
    # @param [Hash, NilClass] option
    # @example HBW.notify(exception)
    # @example HBW.notify(exception, { error_class: 'InvalidUserError' })
    # def notify(exception, option = nil)
    #
    # @param [Exception] exception
    # @param [String] error_class
    # @param [String] error_message
    # @param [Hash] context
    # @param [Array] backtrace
    # @param [Hash] parameters
    # @param [String] action
    # @param [Boolean] raise_development
    # @param [Boolean] notice_only
    # @example HBW.notify(exception, error_class: 'InvalidUserError')
    # def notify(exception, error_class: nil, error_message: nil, context: nil, backtrace: nil, parameters: nil, action: nil, raise_development: true, notice_only: false)
    #
    # @param [String] error_class
    # @param [String] error_message
    # @param [Hash] context
    # @param [Array] backtrace
    # @param [Hash] parameters
    # @param [String] action
    # @param [Boolean] raise_development
    # @param [Boolean] notice_only
    # @example HBW.notify('InvalidUserError', 'user message must be integer, but got #{user.id}', raise_development: false)
    # def notify(error_class, error_message, context: nil, backtrace: nil, parameters: nil, action: nil, raise_development: true, notice_only: false)
    def notify(exception_or_error_class, option_or_error_message = nil,
               error_class: nil, error_message: nil, context: nil, backtrace: nil, parameters: nil, action: nil,
               raise_development: true, notice_only: false)
      if exception_or_error_class.is_a?(Exception)
        # option_or_error_message must be option (Hash-like object)
        if !(option_or_error_message.nil? || option_or_error_message.respond_to?(:to_hash))
          raise HBW::ArgumentError.new("option_or_error_message must be nil or Hash-like object, but got #{option_or_error_message}")
        end
        if option_or_error_message.nil?
          opts = {}
        else
          opts = option_or_error_message.to_hash
        end
        merge_opts!(opts,
                    error_class: error_class, error_message: error_message,
                    context: context, backtrace: backtrace, parameters: parameters, action: action, raise_development: raise_development, notice_only: notice_only)
        notify_raw(exception_or_error_class, opts)
      elsif exception_or_error_class.is_a?(String)
        # option_or_error_message must be error_message (String)
        if option_or_error_message.nil? || !option_or_error_message.respond_to?(:to_s)
          raise HBW::ArgumentError.new("option_or_error_message must be String-like object, but got #{option_or_error_message}")
        end
        # error_class and error_message must be nil
        if (!error_class.nil? || !error_message.nil?)
          raise HBW::ArgumentError.new("error_class must be nil but got #{error_class}, error_message must be nil but got #{error_message}")
        end
        opts = {}
        merge_opts!(opts,
                    error_class: exception_or_error_class, error_message: option_or_error_message,
                    context: context, backtrace: backtrace, parameters: parameters, action: action, raise_development: raise_development, notice_only: notice_only)
        notify_raw(opts)
      else
        raise HBW::ArgumentError.new("Invalid argument")
      end

    rescue => e
      if should_use_honeybadger?
        # Note: Something wrong. exception must not occur when
        # should_use_honeybadger? is true.
        honeybadger_notify(e)
        return nil
      else
        raise e
      end
    end

    # raise_development is supported. By default, raise_development is true.
    # notice_only is supported. By default, notice_only is false.
    # @param [Exception, Hash] exception_or_opts
    # @param [Hash] opts
    # @return [NilClass]
    # @raise [RuntimeError]
    def notify_raw(exception_or_opts, opts = {})
      opts.merge!(exception_or_opts.to_hash) if exception_or_opts.respond_to?(:to_hash)
      raise_development = opts.has_key?(:raise_development) ? opts.delete(:raise_development) : true
      notice_only       = opts.has_key?(:notice_only)       ? opts.delete(:notice_only)       : false

      if notice_only
        opts[:error_message] = "[Notice Only] #{error_class(exception_or_opts, opts)}: #{error_message(exception_or_opts, opts)}"
      end

      # QA, Production
      if should_use_honeybadger?
        if exception_or_opts.respond_to?(:to_hash)  # Already merged to opts
          honeybadger_notify(opts)
        else
          honeybadger_notify(exception_or_opts, opts)
        end
        return nil
      end

      # Development
      return nil if !raise_development

      if notice_only
        raise opts[:error_message]
      else
        raise exception_or_error_message(exception_or_opts, opts)
      end

      nil
    end

  private

    def merge_opts!(opts, error_class:, error_message:, context:, backtrace:, parameters:, action:, raise_development:, notice_only:)
      opts.merge!(error_class:   error_class)   if !error_class.nil?
      opts.merge!(error_message: error_message) if !error_message.nil?
      opts.merge!(context:       context)       if !context.nil?
      opts.merge!(backtrace:     backtrace)     if !backtrace.nil?
      opts.merge!(parameters:    parameters)    if !parameters.nil?
      opts.merge!(action:        action)        if !action.nil?
      opts.merge!(
        raise_development: raise_development,
        notice_only:       notice_only,
      )
    end

    # @return [Boolean]
    def should_use_honeybadger?
      defined?(Honeybadger)
    end

    # @param [Exception, Hash] exception_or_opts
    # @param [Hash] opts
    def honeybadger_notify(exception_or_opts, opts = {})
      ::Honeybadger.notify(exception_or_opts, opts)
    end

    # @param [Exception, Hash] exception_or_opts
    # @param [Hash] opts
    # @return [String] error class
    def error_class(exception_or_opts, opts)
      if exception_or_opts.is_a?(Exception)
        exception_or_opts.class.name
      else
        'Notice'
      end
    end

    # @param [Exception, Hash] exception_or_opts
    # @param [Hash] opts
    # @return [String] error message
    def error_message(exception_or_opts, opts)
      e = exception_or_error_message(exception_or_opts, opts)
      if e.is_a?(Exception)
        e.message
      else
        e
      end
    end

    # @param [Exception, Hash] exception_or_opts
    # @param [Hash] opts
    # @return [Exception, String] exception or error message
    def exception_or_error_message(exception_or_opts, opts)
      if exception_or_opts.is_a?(Exception)
        exception_or_opts
      elsif exception_or_opts.respond_to?(:to_hash) && (opts[:exception] || opts[:error_message])
        opts[:exception] || opts[:error_message]
      else
        exception_or_opts.to_s
      end
    end
  end
end
