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

    extractor = Tess::Rdf::EventExtractor.new(file.read, :rdfa, base_uri: 'https://training.vib.be/all-trainings/career-counseling-antwerp-0')

    assert_equal 1, extractor.extract.count
  end
end
