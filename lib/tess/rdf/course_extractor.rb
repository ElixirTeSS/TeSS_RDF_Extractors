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
              pattern RDF::Query::Pattern.new(course_uri, RDF::Vocab::SCHEMA.courseMode, :course_mode, optional: true)
            end,
            *difficulty_level_queries(course_uri),
            *event_queries(course_uri)
        ] + super
      end
    end
  end
end
