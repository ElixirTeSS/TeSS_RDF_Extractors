require 'test_helper'

class ExtractionTest < Test::Unit::TestCase
  test 'extract events from json-ld' do
    file = fixture_file('ebi-training-courses-tess-sample.json')

    extractor = Tess::Rdf::EventExtractor.new(file.read, :jsonld)

    assert_equal 6, extractor.extract.count
  end

  test 'extract courses from json-ld' do
    file = fixture_file('ebi-training-courses-tess-sample.json')

    extractor = Tess::Rdf::CourseExtractor.new(file.read, :jsonld)

    assert_equal 14, extractor.extract.count
  end

  test 'extract events from HTML' do
    file = fixture_file('career-counseling-antwerp-0-vib.html')
    base_uri = 'https://training.vib.be/all-trainings/career-counseling-antwerp-0'

    extractor = Tess::Rdf::EventExtractor.new(file.read, :rdfa, base_uri: base_uri)

    assert_equal 1, extractor.extract.count
  end

  test 'extract learning resources from HTML' do
    file = fixture_file('galaxy-training-network-tutorial.html')
    base_uri = 'https://training.galaxyproject.org/training-material/topics/assembly/tutorials/debruijn-graph-assembly/tutorial.html'

    extractor = Tess::Rdf::LearningResourceExtractor.new(file.read, :rdfa, base_uri: base_uri)

    x = extractor.extract

    assert_equal 4, x.count
  end
end
