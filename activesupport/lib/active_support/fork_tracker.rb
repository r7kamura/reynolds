# frozen_string_literal: true

module ActiveSupport
  module ForkTracker # :nodoc:
    module CoreExt
      def fork(*)
        if block_given?
          super do
            ForkTracker.check!
            yield
          end
        else
          unless pid = super
            ForkTracker.check!
          end
          pid
        end
      end
    end

    module CoreExtPrivate
      include CoreExt
      private :fork
    end

    @pid = Process.pid
    @callbacks = []

    class << self
      def check!
        if @pid != Process.pid
          @callbacks.each(&:call)
          @pid = Process.pid
        end
      end

      def hook!
        ::Object.prepend(CoreExtPrivate)
        ::Kernel.singleton_class.prepend(CoreExt)
        ::Process.singleton_class.prepend(CoreExt)
      end

      def after_fork(&block)
        @callbacks << block
        block
      end

      def unregister(callback)
        @callbacks.delete(callback)
      end
    end
  end
end

ActiveSupport::ForkTracker.hook!
