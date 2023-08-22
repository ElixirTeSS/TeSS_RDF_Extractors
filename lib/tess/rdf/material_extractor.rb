module Tess
  module Rdf
    class MaterialExtractor
      include Tess::Rdf::Extraction

      def extract_params
        params = super

        legacy_topics = query([resource, RDF::Vocab::SCHEMA.genre, :scientific_topics],
              [:scientific_topics, RDF::RDFS.label, :scientific_topic_names]).map { |v| v[:scientific_topic_names] }
        if legacy_topics.any?
          params[:scientific_topic_names] ||= []
          params[:scientific_topic_names] |= legacy_topics
        end

        params[:prerequisites] = markdownify_list extract_names_or_values(RDF::Vocab::SCHEMA.competencyRequired)
        params[:learning_objectives] = markdownify_list extract_names_or_values(RDF::Vocab::SCHEMA.teaches)

        params[:licence] = extract_value(RDF::Vocab::SCHEMA.license)
        params[:remote_created_date] = extract_value(RDF::Vocab::DC.date)
        params[:difficulty_level] = extract_names_or_values(RDF::Vocab::SCHEMA.educationalLevel).first
        identifier = extract_value(RDF::Vocab::SCHEMA.identifier)
        params[:doi] = identifier if identifier && identifier =~ /10\.\d{4,}/
        params[:version] = extract_value(RDF::Vocab::SCHEMA.version)
        params[:date_created] = extract_value(RDF::Vocab::SCHEMA.dateCreated)
        params[:date_modified] = extract_value(RDF::Vocab::SCHEMA.dateModified)
        params[:date_published] = extract_value(RDF::Vocab::SCHEMA.datePublished)
        params[:status] = extract_value(RDF::Vocab::SCHEMA.creativeWorkStatus)

        params[:authors] = (extract_names(RDF::Vocab::SCHEMA.author) | extract_names(RDF::Vocab::SIOC.has_creator)).sort
        params[:contributors] = extract_names(RDF::Vocab::SCHEMA.contributor)
        params[:target_audience] = extract_audience
        params[:resource_type] = extract_values(RDF::Vocab::SCHEMA.learningResourceType)

        remove_blanks(params)
      end

      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:individual, RDF.type, RDF::Vocab::SCHEMA.CreativeWork)
        end
      end
    end
  end
end
