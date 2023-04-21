module Tess
  module Rdf
    require 'linkeddata'

    require_relative 'tess/rdf/shared_queries'
    require_relative 'tess/rdf/extraction'
    require_relative 'tess/rdf/event_extractor'
    require_relative 'tess/rdf/material_extractor'
    require_relative 'tess/rdf/course_instance_extractor'
    require_relative 'tess/rdf/course_extractor'
    require_relative 'tess/rdf/learning_resource_extractor'
  end
end

# Tell Ruby RDF to not use RestClient to parse remote files
# https://github.com/ruby-rdf/rdf/issues/331
RDF::Util::File.http_adapter = RDF::Util::File::NetHttpAdapter
