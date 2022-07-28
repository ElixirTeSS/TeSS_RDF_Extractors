module Tess
  module Rdf
    class MaterialExtractor

      include Tess::Rdf::Extraction

      private

      def self.singleton_attributes
        [:url, :title, :description, :licence, :remote_created_date, :difficulty_level, :doi]
      end

      def self.array_attributes
        [:scientific_topic_names, :keywords, :authors, :target_audience, :resource_type, :contributors]
      end

      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:individual, RDF.type, RDF::Vocab::SCHEMA.CreativeWork)
        end
      end

      def self.individual_queries(res)
        material_uri = res.individual
        [
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.name, :title, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.description, :description, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::DC.date, :remote_created_date, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.keywords, :keywords, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.url, :url, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.license, :licence, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.learningResourceType, :resource_type, optional: true)
            end,
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.about, :description, optional: true)
            end,
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.genre, :scientific_topics)
              pattern RDF::Query::Pattern.new(:scientific_topics, RDF::RDFS.label, :scientific_topic_names, optional: true)
            end,
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SIOC.has_creator, :author_obs)
              pattern RDF::Query::Pattern.new(:author_obs, RDF::Vocab::SCHEMA.name, :authors, optional: true)
            end,
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.author, :author_obs)
              pattern RDF::Query::Pattern.new(:author_obs, RDF::Vocab::SCHEMA.name, :authors, optional: true)
            end,
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.contributor, :contributor_obs)
              pattern RDF::Query::Pattern.new(:contributor_obs, RDF::Vocab::SCHEMA.name, :contributors, optional: true)
            end,
            #Audience
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.audience, :audience_details)
              pattern RDF::Query::Pattern.new(:audience_details, RDF::Vocab::SCHEMA.educationalRole, :target_audience, optional: true)
            end,
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.audience, :audience_details)
              pattern RDF::Query::Pattern.new(:audience_details, RDF::Vocab::SCHEMA.audienceType, :target_audience, optional: true)
            end,
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.audience, :audience_details)
              pattern RDF::Query::Pattern.new(:audience_details, RDF::Vocab::SCHEMA.name, :target_audience, optional: true)
            end,
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.audience, :audience_details)
              pattern RDF::Query::Pattern.new(:audience_details, RDF::RDFS.label, :target_audience, optional: true)
            end,
            #Scientific topics
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.about, :topics)
              pattern RDF::Query::Pattern.new(:topics, RDF.type, RDF::Vocabulary::Term.new('http://schema.org/DefinedTerm', attributes: {}))
              pattern RDF::Query::Pattern.new(:topics, RDF::Vocab::SCHEMA.name, :scientific_topic_names, optional: true)
            end,
            RDF::Query.new do
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.educationalLevel, :difficulty_level, optional: true)
            end
        ]
      end
    end
  end
end
