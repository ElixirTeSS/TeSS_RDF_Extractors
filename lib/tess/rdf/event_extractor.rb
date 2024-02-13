module Tess
  module Rdf
    class EventExtractor
      include Tess::Rdf::Extraction

      def extract_params
        params = super

        params[:subtitle] = extract_value(RDF::Vocab::SCHEMA.alternateName)

        params[:start] = extract_value(RDF::Vocab::SCHEMA.startDate)
        params[:end] = extract_value(RDF::Vocab::SCHEMA.endDate)
        params[:duration] = extract_value(RDF::Vocab::SCHEMA.duration)
        if !params[:end] && params[:start] && params[:duration]
          params[:end] = modify_date(params[:start], params[:duration])
        end

        params[:online] = extract_online
        params.merge!(extract_location)

        params[:organizer] = extract_names_or_ids(RDF::Vocab::SCHEMA.organizer).join(', ')

        params[:capacity] = extract_value(RDF::Vocab::SCHEMA.maximumAttendeeCapacity)

        contact = extract_person(RDF::Vocabulary::Term.new('http://schema.org/contact', attributes: {}))
        params[:contact] = [contact[:name], contact[:email]].compact.join(' - ') if contact

        legacy_topics = extract_values(RDF::Vocabulary::Term.new('http://schema.org/topic', attributes: {}))
        if legacy_topics.any?
          params[:scientific_topic_names] ||= []
          params[:scientific_topic_names] |= legacy_topics
        end

        params[:host_institutions] = extract_names(RDF::Vocabulary::Term.new('http://schema.org/hostInstitution', attributes: {}))
        params[:sponsors] = extract_names(RDF::Vocab::SCHEMA.sponsor) | extract_names(RDF::Vocab::SCHEMA.funder)
        params[:prerequisites] = extract_course_prerequisites
        params[:learning_objectives] = markdownify_list extract_names_or_values(RDF::Vocab::SCHEMA.teaches)
        params[:target_audience] = extract_audience

        remove_blanks(params)
      end

      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:individual, RDF.type, RDF::Vocab::SCHEMA.Event)
        end
      end
    end
  end
end
