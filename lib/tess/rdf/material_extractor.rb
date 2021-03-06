module Tess
  module Rdf
    class MaterialExtractor

      include Tess::Rdf::Extraction

      def extract(&block)
        super do |params|
          if block_given?
            yield params
          else
            params
          end
        end
      end

      private

      def self.singleton_attributes
        [:url, :title, :short_description, :licence, :remote_created_date]
      end

      def self.array_attributes
        [:scientific_topic_names, :keywords, :authors, :target_audience]
      end

      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:individual, RDF.type, RDF::Vocab::SCHEMA.CreativeWork)
        end
      end

      def self.individual_queries(material_uri)
        [
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.name, :title, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.about, :short_description, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.description, :short_description, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.url, :url, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::DC.date, :remote_created_date, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.keywords, :keywords, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.url, :url, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.license, :licence, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.learningResourceType, :resource_type, optional: true)
            end,
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.genre, :scientific_topics)
              pattern RDF::Query::Pattern.new(:scientific_topics, RDF::RDFS.label, :scientific_topic_names, optional: true)
            end,
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.audience, :target_audience_obs)
              pattern RDF::Query::Pattern.new(:target_audience_obs, RDF::RDFS.label, :target_audience, optional: true)
              pattern RDF::Query::Pattern.new(:target_audience_obs, RDF::Vocab::SCHEMA.name, :target_audience, optional: true)
            end,
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SIOC.has_creator, :author_obs)
              pattern RDF::Query::Pattern.new(:author_obs, RDF::Vocab::SCHEMA.name, :authors, optional: true)
            end,
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.author, :author_obs)
              pattern RDF::Query::Pattern.new(:author_obs, RDF::Vocab::SCHEMA.name, :authors, optional: true)
            end
        ]
      end
    end
  end
end
