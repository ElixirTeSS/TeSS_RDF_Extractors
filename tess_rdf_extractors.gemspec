Gem::Specification.new do |s|
  s.name        = 'tess_rdf_extractors'
  s.version     = '0.0.1'
  s.date        = '2017-08-17'
  s.summary     = 'Tools for parsing TeSS event & training material details from RDF.'
  s.authors     = ['Finn Bacall']
  s.email       = 'tess@elixir-uk.info'
  s.files       = ['lib/tess_rdf_extractors.rb',
                   'lib/tess/rdf/extraction.rb',
                   'lib/tess/rdf/material_extractor.rb',
                   'lib/tess/rdf/event_extractor.rb'
  ]
  s.homepage    = 'https://github.com/ElixirTess/TeSS_RDF_Extractors'
  s.license     = 'BSD'
  s.add_runtime_dependency 'linkeddata', '~> 2.0'
end
