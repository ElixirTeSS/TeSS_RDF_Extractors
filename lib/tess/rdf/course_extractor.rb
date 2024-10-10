module Tess
  module Rdf
    class CourseExtractor < CourseInstanceExtractor
      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:course, RDF.type, RDF::Vocab::SCHEMA.Course)
          pattern RDF::Query::Pattern.new(:course, RDF::Vocab::SCHEMA.hasCourseInstance, :individual)
        end
      end

      def extract_params
        # Take some metadata from Course
        course_params = {}
        with_resource(course) do
          course_params = super
        end
        # course_params[:difficulty_level] ||=
        #          extract_names_or_values(RDF::Vocab::SCHEMA.educationalLevel, subject: course).first
        course_params[:external_resources] = extract_mentions
        # ...and override with more specific metadata from CourseInstance
        course_instance_params = super
        course_params.merge(course_instance_params)
      end

      def course
        @_resource&.course
      end
    end
  end
end
