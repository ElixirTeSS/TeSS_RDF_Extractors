module Tess
  module Rdf
    class CourseExtractor < EventExtractor
      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:course, RDF.type, RDF::Vocab::SCHEMA.Course)
          pattern RDF::Query::Pattern.new(:course, RDF::Vocab::SCHEMA.hasCourseInstance, :individual)
        end
      end

      # The CourseInstance is bound to `individual`, which we pass up to the events extractor.
      # We take some basic metadata from the Course, but these will be overwritten if the same properties are defined on
      # the CourseInstance.
      def self.individual_queries(res)
        course_uri = res.course
        [
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(course_uri, RDF::Vocab::SCHEMA.name, :title, optional: true)
              pattern RDF::Query::Pattern.new(course_uri, RDF::Vocab::SCHEMA.description, :description, optional: true)
              pattern RDF::Query::Pattern.new(course_uri, RDF::Vocab::SCHEMA.url, :url, optional: true)
            end
        ] + super
      end
    end
  end
end
