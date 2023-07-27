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

      def difficulty_level_queries(uri)
        [
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.educationalLevel, :difficulty_level, optional: true)
          end,
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.educationalLevel, :difficulty_level_terms)
            pattern RDF::Query::Pattern.new(:difficulty_level_terms, RDF.type, RDF::Vocabulary::Term.new('http://schema.org/DefinedTerm', attributes: {}))
            pattern RDF::Query::Pattern.new(:difficulty_level_terms, RDF::Vocab::SCHEMA.name, :difficulty_level, optional: true)
          end
        ]
      end

      def node_query(uri)
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.provider, :providers)
          pattern RDF::Query::Pattern.new(:providers, RDF.type, RDF::Vocab::SCHEMA.Organization)
          pattern RDF::Query::Pattern.new(:providers, RDF::Vocab::SCHEMA.name, :node_names, optional: true)
        end
      end
    end
  end
end
