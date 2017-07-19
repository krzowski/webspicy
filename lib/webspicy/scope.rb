module Webspicy
  class Scope

    def initialize(config)
      @config = config
    end
    attr_reader :config

    # Yields each resource in the current scope in turn.
    def each_resource(&bl)
      return enum_for(:each_resource) unless block_given?
      config.folders.each do |folder|
        _each_resource(folder, &bl)
      end
    end

    # Recursive implementation of `each_resource` for each
    # folder in the configuration.
    def _each_resource(folder)
      folder.glob("**/*.yml").select(&file_filter_proc).each do |file|
        yield Webspicy.resource(file.load, file)
      end
    end
    private :_each_resource

    def each_service(resource, &bl)
      resource.services.each(&bl)
    end

    def each_example(service, &bl)
      service.examples.each(&bl)
    end

    def each_counterexamples(service, &bl)
      service.counterexamples.each(&bl) if config.run_counterexamples?
    end

    # Parses a Finitio schema based on the data system.
    def parse_schema(fio)
      data_system.parse(fio)
    end

    # Returns the Data system to use for parsing schemas
    def data_system
      Finitio::DEFAULT_SYSTEM
    end

    # Convert an instantiated URL found in a webservice definition
    # to a real URL, using the configuration host
    def to_real_url(url)

      case config.host
      when Proc
        config.host.call(url)
      when String
        url =~ /^http/ ? url : "#{config.host}#{url}"
      else
        return url if url =~ /^http/
        raise "Unable to resolve `#{url}` : no host resolver provided\nSee `Configuration#host="
      end
    end

    ###

      # Returns a proc that implements file_filter strategy according to the
      # type of filter installed
      def file_filter_proc
        case ff = config.file_filter
        when NilClass then ->(f){ true }
        when Proc     then ff
        when Regexp   then ->(f){ ff =~ f.to_s }
        else
          ->(f){ ff === f }
        end
      end
      private :file_filter_proc

  end
end
