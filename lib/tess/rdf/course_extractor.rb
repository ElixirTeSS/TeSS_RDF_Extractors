module Tess
  module Rdf
    class CourseExtractor

      include Tess::Rdf::Extraction

      def extract(&block)
        super do |params|
          if block_given?
            yield params
          else
            params
          end
        end
      end

      private

      def self.singleton_attributes
        [:title, :short_description, :url]
      end

      def self.array_attributes
        []
      end

      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:individual, RDF.type, RDF::Vocab::SCHEMA.Course)
        end
      end

      def self.individual_queries(course_uri)
        [
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(course_uri, RDF::Vocab::SCHEMA.name, :title, optional: true)
              pattern RDF::Query::Pattern.new(course_uri, RDF::Vocab::SCHEMA.description, :short_description, optional: true)
              pattern RDF::Query::Pattern.new(course_uri, RDF::Vocab::SCHEMA.url, :url, optional: true)
            end
        ]
      end
    end
  end
end
