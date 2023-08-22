module Tess
  module Rdf
    class LearningResourceExtractor < MaterialExtractor
      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:individual, RDF.type, RDF::Vocab::SCHEMA.LearningResource)
        end
      end
    end
  end
end
