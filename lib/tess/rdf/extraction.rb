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

      def query(*patterns)
        results = []
        query = RDF::Query.new(patterns.map { |p| RDF::Query::Pattern.new(*p) })
        query.execute(@_graph).each do |solution|
          results << solution.bindings.transform_values { |v| parse_value(v) }
        end
        results
      end

      def graph
        return @_graph if @_graph
        g = RDF::Graph.new
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
        g.insert_statements(statements)
        @_graph = g
      end

      def resources
        graph.query(self.class.type_query)
      end

      def extract(&block)
        resources.map do |res|
          @_resource = res
          params = extract_params
          @_resource = nil

          if block_given?
            yield params
          else
            params
          end
        end
      end

      private

      def resource
        @_temp_resource || @_resource.individual
      end

      def with_resource(temp_resource)
        @_temp_resource = temp_resource
        yield
        @_temp_resource = nil
      end

      def extract_params
        params = {}

        params[:title] = extract_value(RDF::Vocab::SCHEMA.name)
        params[:description] = extract_value(RDF::Vocab::SCHEMA.description)
        params[:url] = extract_value(RDF::Vocab::SCHEMA.url)
        params[:keywords] = extract_keyword_like(RDF::Vocab::SCHEMA.keywords)
        params[:node_names] = extract_nodes
        params.merge!(extract_topics)

        remove_blanks(params)
      end

      def extract_value(predicate, subject: resource)
        extract_values(predicate, subject: subject).first
      end

      def extract_values(predicate, subject: resource)
        query([subject, predicate, :value]).map { |r| r[:value] }.compact.uniq.sort
      end

      def extract_names(predicate, subject: resource)
        query([subject, predicate, :thing],
              [:thing, RDF::Vocab::SCHEMA.name, :name]).map { |r| r[:name] }.compact.uniq.sort
      end

      def extract_person(predicate, subject: resource)
        query([subject, predicate, :person],
              [:person, RDF::Vocab::SCHEMA.name, :name, { optional: true }],
              [:person, RDF::Vocab::SCHEMA.email, :email, { optional: true }]).first
      end

      def extract_names_or_values(predicate, subject: resource)
        (extract_names(predicate, subject: subject) | extract_values(predicate, subject: subject)).sort
      end

      def extract_keyword_like(predicate, subject: resource)
        # DefinedTerm
        values = extract_names(predicate, subject: subject)

        # Text/URL
        text_values = extract_values(predicate, subject: subject)

        values |= if text_values.length == 1 # Split comma separated string
                    text_values.first.split(',').map(&:strip)
                  else
                    text_values
                  end

        values
      end

      def extract_nodes(subject: resource)
        query([subject, RDF::Vocab::SCHEMA.provider, :provider],
              [:provider, RDF.type, RDF::Vocab::SCHEMA.Organization],
              [:provider, RDF::Vocab::SCHEMA.name, :node_name]).map { |n| n[:node_name].sub(/ELIXIR\s?/i, '') }
      end

      def extract_topics(subject: resource)
        results = {}

        query(
          [subject, RDF::Vocab::SCHEMA.about, :uri],
          [:uri, RDF.type, RDF::Vocabulary::Term.new('http://schema.org/DefinedTerm', attributes: {})],
          [:uri, RDF::Vocab::SCHEMA.name, :name, optional: true]).each do |result|
          if result[:name]
            results[:scientific_topic_names] ||= []
            results[:scientific_topic_names] << result[:name]
          end

          if result[:uri]
            edam_term = result[:uri].match(/http:\/\/edamontology\.org\/.+/)&.to_s
            if edam_term
              results[:scientific_topic_uris] ||= []
              results[:scientific_topic_uris] << edam_term
            end
          end
        end

        remove_blanks(results)
      end

      def extract_location(subject: resource)
        postal_address_query = [
          [:postal_address, RDF.type, RDF::Vocab::SCHEMA.PostalAddress],
          [:postal_address, RDF::Vocab::SCHEMA.name, :venue, { optional: true }],
          [:postal_address, RDF::Vocab::SCHEMA.streetAddress, :street_address, { optional: true }],
          [:postal_address, RDF::Vocab::SCHEMA.addressLocality, :locality, { optional: true }],
          [:postal_address, RDF::Vocab::SCHEMA.addressRegion, :region, { optional: true }],
          [:postal_address, RDF::Vocab::SCHEMA.addressCountry, :country, { optional: true }],
          [:postal_address, RDF::Vocab::SCHEMA.postalCode, :postcode, { optional: true }]
        ]

        # Place
        location = query(
          [subject, RDF::Vocab::SCHEMA.location, :place],
          [:place, RDF::Vocab::SCHEMA.name, :venue, { optional: true }],
          [:place, RDF::Vocab::SCHEMA.geo, :geo, { optional: true }],
          [:geo, RDF::Vocab::SCHEMA.longitude, :longitude, { optional: true }],
          [:geo, RDF::Vocab::SCHEMA.latitude, :latitude, { optional: true }],
          [:place, RDF::Vocab::SCHEMA.address, :postal_address],
          *postal_address_query).first

        # PostalAddress
        location ||= query(
          [subject, RDF::Vocab::SCHEMA.location, :postal_address],
          *postal_address_query).first

        # Text
        location ||= { venue: extract_value(RDF::Vocab::SCHEMA.location) }

        # VirtualLocation
        virtual = query(
          [subject, RDF::Vocab::SCHEMA.location, :location],
          [:location, RDF.type, RDF::Vocab::SCHEMA.VirtualLocation],
          [:location, RDF::Vocab::SCHEMA.name, :name],
          [:location, RDF::Vocab::SCHEMA.url, :url, { optional: true }]).first

        # Concat Venue + Street Address since we don't have a field for that
        venue = [location[:venue], location.delete(:street_address)].compact
        location[:venue] = venue.join(', ') unless venue.empty?
        location[:city] = location.delete(:locality) if location.key?(:locality)
        location[:county] = location.delete(:region) if location.key?(:region)

        if virtual
          virtual_location = [virtual[:name], virtual[:url]].compact.join(' - ')
          location[:venue] = [location[:venue], virtual_location].compact
          location[:venue] = location[:venue].join(', ') unless location[:venue].empty?
          location[:online] ||= true
        end

        remove_blanks(location)
      end

      def extract_online(subject: resource)
        course_modes = extract_values(RDF::Vocab::SCHEMA.courseMode, subject: subject)
        return nil if course_modes.empty?

        course_modes.any? { |c| c =~ /\s*online\s*/i }
      end

      def extract_course_prerequisites(subject: resource)
        prereqs = []
        # AlignmentObject, Course, Text
        query(
          [subject, RDF::Vocab::SCHEMA.coursePrerequisites, :prereq],
          [:prereq, RDF::Vocab::SCHEMA.targetName, :name, { optional: true }], # AlignmentObject
          [:prereq, RDF::Vocab::SCHEMA.targetUrl, :url, { optional: true }], # AlignmentObject
          [:prereq, RDF::Vocab::SCHEMA.name, :name, { optional: true }],
          [:prereq, RDF::Vocab::SCHEMA.url, :url, { optional: true }]).each do |prereq|
          if prereq[:name]
            prereqs << markdownify_link(prereq[:name], prereq[:url])
          elsif prereq[:prereq].is_a?(String) # Text
            prereqs << prereq[:prereq]
          end
        end

        markdownify_list(prereqs)
      end

      def extract_audience(subject: resource)
        query(
          [subject, RDF::Vocab::SCHEMA.audience, :audience],
          [:audience, RDF::Vocab::SCHEMA.educationalRole, :target_audience, { optional: true }], # EducationalAudience
          [:audience, RDF::Vocab::SCHEMA.audienceType, :target_audience, { optional: true }],
          [:audience, RDF::Vocab::SCHEMA.name, :target_audience, { optional: true }],
          [:audience, RDF::RDFS.label, :target_audience, { optional: true }]).map { |a| a[:target_audience] }.compact
      end

      def parse_value(value)
        # Using 'value.class.name' instead of just 'value' here or things like RDF::Literal::DateTime fall into the RDF::Literal block
        # Not using 'value.class' because 'case' uses '===' for comparison and RDF::URI === RDF::URI is false!
        case value.class.name
        when 'RDF::Literal::HTML'
          value.object.text.strip
        when 'RDF::URI'
          value.value
        when 'RDF::Literal'
          value.object.strip
        when 'RDF::Node'
          nil
        else
          value.object
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

      def markdownify_link(name, url = nil)
        return name if url.nil?
        "[#{name}](#{url})"
      end

      def markdownify_list(array)
        if array.length > 1
          array.map { |c| " * #{c}" }.join("\n")
        else
          array.first
        end
      end

      def remove_blanks(hash)
        hash.each do |key, value|
          hash.delete(key) if value == nil || value == '' || value == []
        end
        hash
      end
    end
  end
end
