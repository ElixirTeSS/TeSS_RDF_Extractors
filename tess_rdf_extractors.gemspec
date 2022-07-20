Gem::Specification.new do |s|
  s.name        = 'tess_rdf_extractors'
  s.version     = '0.1.0'
  s.date        = '2022-07-20'
  s.summary     = 'Tools for parsing TeSS event & training material details from RDF'
  s.authors     = ['Finn Bacall']
  s.email       = 'tess@elixir-uk.info'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/ElixirTeSS/TeSS_RDF_Extractors'
  s.license     = 'BSD'
  s.add_runtime_dependency 'linkeddata', '~> 2.0'
end
