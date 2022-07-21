require 'simplecov'
SimpleCov.start

require 'test/unit'
require 'tess_rdf_extractors'

def fixture_file(name, *args)
  ::File.open(::File.join(fixture_dir, name), *args)
end

def fixture_dir
  ::File.join(::File.dirname(__FILE__), 'fixtures')
end
