module Tess
  module Rdf
    module Extraction
      RDF::Reader
      # Workaround for https://github.com/ruby-rdf/rdf-rdfa/issues/32
      class DummyReader
        def initialize(*args); end
        def to_sym; :dummy_reader; end
        def new(*args); []; end
      end

      attr_reader :_graph

      def initialize(source, format, base_uri: nil)
        @reader = RDF::Reader.for(format).new(source, base_uri: base_uri)
        if format == :jsonld && !JSON::LD::Context::PRELOADED['http://schema.org/']
          puts 'Pre-loading schema.org context...'
          begin
            ctx = JSON::LD::Context.new.parse('http://schema.org/docs/jsonldcontext.jsonld')
          rescue JSON::LD::JsonLdError::LoadingRemoteContextFailed
            ctx = JSON::LD::Context.new.parse(File.join(File.dirname(__FILE__), 'schemaorgcontext.jsonld'))
          end

          JSON::LD::Context.add_preloaded('http://schema.org/', ctx)
        end
        # Workaround for https://github.com/ruby-rdf/rdf-rdfa/issues/32
        if @reader.is_a?(RDF::RDFa::Reader)
          readers = @reader.instance_variable_get(:@readers) || {}
          readers['text/plain'] = DummyReader.new
          @reader.instance_variable_set(:@readers, readers)
        end
      end

      def transform(params)
        if params[:keywords].is_a?(Array) && params[:keywords].length == 1
          params[:keywords] = params[:keywords].first.split(',').map(&:strip)
        end

        if params[:node_names]&.any?
          params[:node_names].map! { |n| n.sub(/ELIXIR\s?/i, '') }
        end

        params
      end

      def extract(&block)
        graph = RDF::Graph.new
        statements = []
        @reader.each_statement do |statement|
          [:subject, :object, :predicate].each do |part|
            uri = statement.send(part)
            if uri.is_a?(RDF::URI) && uri.host == 'schema.org' && uri.scheme == 'https'
              statement.send("#{part}=", RDF::URI(uri.to_s.sub(/\A(https)/, 'http')))
            end
          end
          statements << statement
        end
        graph.insert_statements(statements)
        @_graph = graph # To help with debugging

        graph.query(self.class.type_query).map do |res|
          params = {}

          params[:url] = res.individual.value if res.individual.is_a?(RDF::URI)

          self.class.individual_queries(res).each do |query|
            bindings = graph.query(query).bindings

            self.class.singleton_attributes.each do |attr|
              begin
                value = parse_values(bindings[attr], attr)&.first
                params[attr] = value unless (value.nil? || value == '')
              rescue StandardError
                raise "Error whilst trying to extract '#{attr}'"
              end
            end

            self.class.array_attributes.each do |attr|
              begin
                values = parse_values(bindings[attr], attr)
                if values
                  params[attr] ||= []
                  params[attr] |= values
                end
              rescue StandardError
                raise "Error whilst trying to extract '#{attr}'"
              end
            end
          end

          params = transform(params)

          if block_given?
            yield params
          else
            params
          end
        end
      end

      def parse_values(values, attr)
        if values
          values.map do |v|
            # Using 'v.class.name' instead of just 'v' here or things like RDF::Literal::DateTime fall into the RDF::Literal block
            # Not using 'v.class' because 'case' uses '===' for comparison and RDF::URI === RDF::URI is false!
            case v.class.name
              when 'RDF::Literal::HTML'
                v.object.text.strip
              when 'RDF::URI'
                v.value
              when 'RDF::Literal'
                v.object.strip
              when 'RDF::Node'
                warn "WARNING: Unexpected value when trying to extract #{attr}"
              else
                v.object
            end
          end.compact.uniq.sort
        else
          nil
        end
      end

      def modify_date(date, duration)
        if date.is_a?(String)
          date = Date.parse(date)
        end
        matches = duration.match(/P([^T]+)T?(.*)/)
        date_period = matches[1]

        date_period.scan(/(\d+)([YMWD])/).each do |match|
          value = match[0].to_i
          case match[1]
            when 'Y'
              date = date >> (12 * value)
            when 'M'
              date = date >> value
            when 'W'
              date = date + (7 * value)
            when 'D'
              date = date + value
          end
        end
        # time_period = matches[2]
        #
        # time_period.scan(/(\d+)([HMS])/).each do |match|
        #   case match[1]
        #     when 'H'
        #     when 'M'
        #     when 'S'
        #   end
        # end
        date
      end

      def extract_topics(params)
        topic_uris = params.delete(:scientific_topic_uris) || []
        topic_uris = topic_uris.map { |u| u.match(/http:\/\/edamontology\.org\/.+/)&.to_s }.compact
        params[:scientific_topic_uris] = topic_uris if topic_uris.any?
        params
      end

      def markdownify_list(array)
        if array.length > 1
          array.map { |c| " * #{c}" }.join("\n")
        else
          array.first
        end
      end
    end
  end
end
