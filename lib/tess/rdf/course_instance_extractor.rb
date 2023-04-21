module Tess
  module Rdf
    class CourseInstanceExtractor < EventExtractor
      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:individual, RDF.type, RDF::Vocab::SCHEMA.CourseInstance)
        end
      end

      def self.individual_queries(res)
        course_instance_uri = res.individual
        [
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(course_instance_uri, RDF::Vocab::SCHEMA.courseMode, :course_mode, optional: true)
          end
        ] + super
      end
    end
  end
end
