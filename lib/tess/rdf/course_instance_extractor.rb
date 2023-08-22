module Tess
  module Rdf
    class CourseInstanceExtractor < EventExtractor
      def extract_params
        params = super
        params[:event_types] = [:workshops_and_courses]
        remove_blanks(params)
      end

      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:individual, RDF.type, RDF::Vocab::SCHEMA.CourseInstance)
        end
      end
    end
  end
end
