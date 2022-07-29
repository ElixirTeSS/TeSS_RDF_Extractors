module Tess
  module Rdf
    module SharedQueries
      def audience_queries(uri)
        [
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.audience, :audience_details)
            pattern RDF::Query::Pattern.new(:audience_details, RDF::Vocab::SCHEMA.educationalRole, :target_audience, optional: true)
          end,
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.audience, :audience_details)
            pattern RDF::Query::Pattern.new(:audience_details, RDF::Vocab::SCHEMA.audienceType, :target_audience, optional: true)
          end,
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.audience, :audience_details)
            pattern RDF::Query::Pattern.new(:audience_details, RDF::Vocab::SCHEMA.name, :target_audience, optional: true)
          end,
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.audience, :audience_details)
            pattern RDF::Query::Pattern.new(:audience_details, RDF::RDFS.label, :target_audience, optional: true)
          end
        ]
      end

      def topic_queries(uri)
        [
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.about, :scientific_topic_uris)
            pattern RDF::Query::Pattern.new(:scientific_topic_uris, RDF.type, RDF::Vocabulary::Term.new('http://schema.org/DefinedTerm', attributes: {}))
            pattern RDF::Query::Pattern.new(:scientific_topic_uris, RDF::Vocab::SCHEMA.name, :scientific_topic_names, optional: true)
          end
        ]
      end
    end
  end
end