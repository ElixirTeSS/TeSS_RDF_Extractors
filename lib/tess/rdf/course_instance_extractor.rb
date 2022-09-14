module Tess
  module Rdf
    class CourseInstanceExtractor < EventExtractor
      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:individual, RDF.type, RDF::Vocab::SCHEMA.CourseInstance)
        end
      end
    end
  end
end
