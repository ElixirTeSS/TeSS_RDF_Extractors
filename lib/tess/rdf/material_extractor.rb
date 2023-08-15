module Tess
  module Rdf
    class MaterialExtractor
      include Tess::Rdf::Extraction
      extend Tess::Rdf::SharedQueries

      def transform(params)
        # Rough check to see if the DOI is actually a DOI
        doi = params.delete(:doi)
        params[:doi] = doi if doi && doi =~ /10\.\d{4,}/

        competency_required = params.delete(:competency_required)
        params[:prerequisites] = markdownify_list(competency_required) if competency_required

        teaches = params.delete(:teaches)
        params[:learning_objectives] = markdownify_list(teaches) if teaches

        extract_topics(params)

        super(params)
      end

      private

      def self.singleton_attributes
        [:url, :title, :description, :licence, :remote_created_date, :difficulty_level, :doi, :version,
         :date_created, :date_modified, :date_published, :status]
      end

      def self.array_attributes
        [:scientific_topic_names, :scientific_topic_uris, :keywords, :authors, :target_audience, :resource_type,
         :contributors, :node_names, :competency_required, :teaches]
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
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.identifier, :doi, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.version, :version, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.competencyRequired, :competency_required, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.teaches, :teaches, optional: true)
              pattern RDF::Query::Pattern.new(material_uri, RDF::Vocab::SCHEMA.creativeWorkStatus, :status, optional: true)
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
            *difficulty_level_queries(material_uri),
            *audience_queries(material_uri),
            *topic_queries(material_uri),
            node_query(material_uri)
        ]
      end
    end
  end
end
