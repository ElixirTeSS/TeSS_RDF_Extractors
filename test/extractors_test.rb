require 'test_helper'

class ExtractorsTest < Test::Unit::TestCase
  test 'extract location from Place' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "CourseInstance",
  "name": "Dummy Course Instance",
  "location": {
    "@type": "Place",
    "address": {
      "@type": "PostalAddress",
      "addressLocality": "Denver",
      "addressRegion": "CO",
      "postalCode": "80209",
      "streetAddress": "7 S. Broadway"
    },
    "name": "The Hi-Dive",
    "geo": {
        "@type": "GeoCoordinates",
        "latitude": "51.162826",
        "longitude": "4.402365"
    }
  }
}])
    location = course_instance_extractor(json).send(:extract_location)
    assert_equal "The Hi-Dive, 7 S. Broadway", location.delete(:venue)
    assert_equal "80209", location.delete(:postcode)
    assert_equal "Denver", location.delete(:city)
    assert_equal "CO", location.delete(:county)
    assert_equal "51.162826", location.delete(:latitude)
    assert_equal "4.402365", location.delete(:longitude)
    assert_empty location
  end

  test 'extract location from PostalAddress' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "CourseInstance",
  "name": "Dummy Course Instance",
  "location": {
    "@type": "PostalAddress",
    "addressLocality": "Denver",
    "addressRegion": "CO",
    "postalCode": "80209",
    "streetAddress": "7 S. Broadway"
  }
}])
    location = course_instance_extractor(json).send(:extract_location)
    assert_equal "7 S. Broadway", location.delete(:venue)
    assert_equal "80209", location.delete(:postcode)
    assert_equal "Denver", location.delete(:city)
    assert_equal "CO", location.delete(:county)
    assert_empty location
  end

  test 'extract location with VirtualLocation' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "CourseInstance",
  "name": "Dummy Course Instance",
  "location": [{
    "@type": "PostalAddress",
    "addressLocality": "Denver",
    "addressRegion": "CO",
    "postalCode": "80209",
    "streetAddress": "7 S. Broadway"
  },{
    "@type": "VirtualLocation",
    "url": "https://zoom.zoom/myroom",
    "name": "Zoom"
  }]
}])
    location = course_instance_extractor(json).send(:extract_location)
    assert_equal "7 S. Broadway, Zoom - https://zoom.zoom/myroom", location.delete(:venue)
    assert_equal "80209", location.delete(:postcode)
    assert_equal "Denver", location.delete(:city)
    assert_equal "CO", location.delete(:county)
    assert_true location.delete(:online)
    assert_empty location
  end

  test 'extract location from Text' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "CourseInstance",
  "name": "Dummy Course Instance",
  "location": "Somewhere cool"
}])
    location = course_instance_extractor(json).send(:extract_location)
    assert_equal "Somewhere cool", location.delete(:venue)
    assert_empty location
  end

  test 'extract coursePrerequisites' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "Course",
  "name": "Dummy Course",
  "coursePrerequisites": [
    "Something",
    {
      "@type": "AlignmentObject",
      "alignmentType": "educationalLevel",
      "educationalFramework": "WTF",
      "targetName": "Alignment Object",
      "targetUrl": "https://example.com/qualification"
    },
    {
      "@type": "Course",
      "name": "Course Object",
      "url": "https://example.com/course"
    }
  ],
  "hasCourseInstance": [{"@type" : "CourseInstance"}]
}])
    assert_equal " * Something\n" +
                 " * [Alignment Object](https://example.com/qualification)\n" +
                 " * [Course Object](https://example.com/course)", course_extractor(json).send(:extract_course_prerequisites)
  end

  test 'extract keywords from comma-separated string' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "Course",
  "name": "Dummy Course",
  "keywords": "a, b, c",
  "hasCourseInstance": [{"@type" : "CourseInstance"}]
}])
    assert_equal ['a', 'b', 'c'], course_extractor(json).send(:extract_keyword_like, RDF::Vocab::SCHEMA.keywords)
  end

  test 'extract keywords from DefinedTerms and Text' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "Course",
  "name": "Dummy Course",
  "keywords": [{
    "@type": "DefinedTerm",
    "name": "a"
  }, "b", "c"],
  "hasCourseInstance": [{"@type" : "CourseInstance"}]
}])
    assert_equal ['a', 'b', 'c'], course_extractor(json).send(:extract_keyword_like, RDF::Vocab::SCHEMA.keywords)
  end

  test 'extract audience' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "Course",
  "name": "Dummy Course",
  "audience": [
    {
      "@type": "EducationalAudience",
      "educationalRole": "students"
    },
    {
      "@type": "Audience",
      "audienceType": "people"
    },
    {
      "@type": "Audience",
      "name": "researchers"
    }
  ],
  "hasCourseInstance": [{"@type" : "CourseInstance"}]
}])
    assert_equal ['students', 'people', 'researchers'], course_extractor(json).send(:extract_audience)
  end

  private

  def course_extractor(fixture, format: :jsonld, base_uri: 'https://example.com/my.json')
    ex = Tess::Rdf::CourseExtractor.new(StringIO.new(fixture), format, base_uri: base_uri)
    ex.instance_variable_set(:@_temp_resource, ex.resources.first.course)
    ex
  end

  def course_instance_extractor(fixture, format: :jsonld, base_uri: 'https://example.com/my.json')
    ex = Tess::Rdf::CourseInstanceExtractor.new(StringIO.new(fixture), format, base_uri: base_uri)
    ex.instance_variable_set(:@_temp_resource, ex.resources.first.individual)
    ex
  end
end