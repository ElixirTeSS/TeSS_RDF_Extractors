require 'test_helper'

class FieldTest < Test::Unit::TestCase
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

  test 'extract providers with see_also' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "CourseInstance",
  "name": "Dummy Course Instance",
  "url": "https://course.example.org",
  "about": {
    "@type": "DefinedTerm",
    "url": "https://unrelated.example.org/topic"
  },
  "provider": [
    {
      "@type": "Organization",
      "name": "Example Org",
      "url": "https://example.org",
      "sameAs": ["https://example.org/a", "https://example.org/b"],
      "subjectOf": "https://example.org/c"
    },
    {
      "@type": "Organization",
      "name": "Only SubjectOf",
      "url": "https://subject.example.org",
      "subjectOf": "https://subject.example.org/page"
    },
    {
      "@type": "Organization",
      "name": "Wrapped SubjectOf",
      "url": "https://wrapped.example.org",
      "subjectOf": {
        "@type": "CreativeWork",
        "url": "https://wrapped.example.org/page"
      }
    },
    {
      "@id": "https://plain.example.org",
      "@type": "Organization",
      "name": "No SubjectOf",
      "url": "https://plain.example.org"
    },
    {
      "@id": "https://same.example.org/provider",
      "@type": "Organization",
      "name": "Only SameAs",
      "url": "https://same.example.org",
      "sameAs": ["https://same.example.org", "https://same.example.org/page"]
    },
    {
      "@type": "Organization",
      "name": "Empty SubjectOf",
      "url": "https://empty.example.org",
      "subjectOf": {
        "@type": "CreativeWork"
      }
    }
  ]
}])

    providers = course_instance_extractor(json).send(:extract_providers)
    assert_equal 6, providers.length

    example = providers.find { |p| p[:name] == 'Example Org' }
    assert_equal 'https://example.org', example[:url]
    assert_equal ['https://example.org/a', 'https://example.org/b', 'https://example.org/c'].sort, example[:see_also].sort

    subject_only = providers.find { |p| p[:name] == 'Only SubjectOf' }
    assert_equal 'https://subject.example.org', subject_only[:url]
    assert_equal ['https://subject.example.org/page'], subject_only[:see_also]

    wrapped = providers.find { |p| p[:name] == 'Wrapped SubjectOf' }
    assert_equal 'https://wrapped.example.org', wrapped[:url]
    assert_equal ['https://wrapped.example.org/page'], wrapped[:see_also]

    plain = providers.find { |p| p[:name] == 'No SubjectOf' }
    assert_equal 'https://plain.example.org', plain[:url]
    assert_equal ['https://plain.example.org'], plain[:see_also]

    same_as_only = providers.find { |p| p[:name] == 'Only SameAs' }
    assert_equal 'https://same.example.org', same_as_only[:url]
    assert_equal ['https://same.example.org', 'https://same.example.org/provider', 'https://same.example.org/page'].sort, same_as_only[:see_also].sort

    empty_subject = providers.find { |p| p[:name] == 'Empty SubjectOf' }
    assert_equal 'https://empty.example.org', empty_subject[:url]
    assert_equal [], empty_subject[:see_also]
  end

  test 'infer end date from start date and duration' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "CourseInstance",
  "name": "Advanced Statistics: Statistical Modelling",
  "description": "**This course is now full.",
  "url": "https://webapp2.vital-it.ch/courseadmin/website/course/20220822_XXXX3",
  "@id": "https://webapp2.vital-it.ch/courseadmin/website/course/20220822_XXXX3",
  "http://purl.org/dc/terms/conformsTo": {
    "@id": "https://bioschemas.org/profiles/CourseInstance/0.8-DRAFT-2020_10_06",
    "@type": "CreativeWork"
  },
  "keywords": "training,biostatistics,raphael gottardo group",
  "location": "Lausanne",
  "startDate": "2022-08-22",
  "duration": "P1Y1M1W3DT4H"
}])
    assert_equal '2023-10-02', course_instance_extractor(json).extract_params[:end].to_s
  end

  test 'infer end datetime from start datetime and duration' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "CourseInstance",
  "name": "Advanced Statistics: Statistical Modelling",
  "description": "**This course is now full.",
  "url": "https://webapp2.vital-it.ch/courseadmin/website/course/20220822_XXXX3",
  "@id": "https://webapp2.vital-it.ch/courseadmin/website/course/20220822_XXXX3",
  "http://purl.org/dc/terms/conformsTo": {
    "@id": "https://bioschemas.org/profiles/CourseInstance/0.8-DRAFT-2020_10_06",
    "@type": "CreativeWork"
  },
  "keywords": "training,biostatistics,raphael gottardo group",
  "location": "Lausanne",
  "startDate": "2022-08-22T09:00:00",
  "duration": "PT8H"
}])
    assert_equal '2022-08-22T17:00:00+00:00', course_instance_extractor(json).extract_params[:end].to_s
  end

  test 'extract tools from mentions' do
    json = %(
[{
  "@context": "http://schema.org",
  "@type": "LearningResource",
  "http://purl.org/dc/terms/conformsTo": {
    "@id": "https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE",
    "@type": "CreativeWork"
  },
  "mentions": [
    {
      "@type": "SoftwareApplication",
      "name": "Galaxy",
      "url": "https://bio.tools/galaxy",
      "description": "Open, web-based platform for data intensive biomedical research"
    },{
      "@type": "Dataset",
      "name": "European Genome-phenome Archive",
      "url": "https://www.ebi.ac.uk/ega/home",
      "description": "The EGA archives a large number of datasets, the access to which is controlled by a Data Access Committee (DAC)."
    }
  ]
}])
    assert_equal [{ title: 'Galaxy', url: 'https://bio.tools/galaxy' },
                  { title: 'European Genome-phenome Archive', url: 'https://www.ebi.ac.uk/ega/home' }], learning_resource_extractor(json).send(:extract_mentions)
  end

  test 'extract multiple organizers' do
    json = %(
[{
  "@context": "http://schema.org",
  "@type": "CourseInstance",
  "http://purl.org/dc/terms/conformsTo": {
    "@id": "https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE",
    "@type": "CreativeWork"
  },
  "organizer": [
    {
      "@type": "Person",
      "@id": "https://orcid.org/0000-0001-9062-6303",
      "name": "Patricia Palagi"
    },
    {
      "@type": "Person",
      "name": "Someone"
    },
    {
      "@type": "Organization",
      "name": "SIB Swiss Institute of Bioinformatics",
      "url": "https://www.sib.swiss/"
    },
    {
      "@id" : "https://cool.guys"
    }
  ]
}])
    assert_equal 'Patricia Palagi (https://orcid.org/0000-0001-9062-6303), SIB Swiss Institute of Bioinformatics (https://www.sib.swiss/), Someone, https://cool.guys',
                 course_instance_extractor(json).send(:extract_names_or_ids, RDF::Vocab::SCHEMA.organizer).join(', ')
  end

  test 'extract language' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "CourseInstance",
  "name": "Dummy Course",
  "inLanguage": "en-GB"
}])
    assert_equal 'en', course_instance_extractor(json).send(:extract_language)

    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "CourseInstance",
  "name": "Dummy Course",
  "inLanguage": {
    "@type": "Language",
    "name" : "de"
  }
}])
    assert_equal 'de', course_instance_extractor(json).send(:extract_language)
  end

  test 'extract authors' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "LearningResource",
  "http://purl.org/dc/terms/conformsTo": {
    "@id": "https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE",
    "@type": "CreativeWork"
  },
  "name": "Dummy Material",
  "author": {
      "@type": "Person",
      "@id": "https://orcid.org/0000-0001-9062-6303",
      "name": "Patricia Palagi"
  }
}])
    authors = learning_resource_extractor(json).send(:extract_people, RDF::Vocab::SCHEMA.author)
    assert_equal 1, authors.length
    assert_equal '0000-0001-9062-6303', authors.first[:orcid]
    assert_equal 'Patricia Palagi', authors.first[:name]

    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "LearningResource",
  "http://purl.org/dc/terms/conformsTo": {
    "@id": "https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE",
    "@type": "CreativeWork"
  },
  "name": "Dummy Material",
  "author": {
      "@type": "Person",
      "@id": "#aperson",
      "name": "Patricia Palagi",
      "identifier": "https://orcid.org/0000-0001-9062-6303"
  }
}])
    authors = learning_resource_extractor(json).send(:extract_people, RDF::Vocab::SCHEMA.author)
    assert_equal 1, authors.length
    assert_equal '0000-0001-9062-6303', authors.first[:orcid]
    assert_equal 'Patricia Palagi', authors.first[:name]

    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "LearningResource",
  "http://purl.org/dc/terms/conformsTo": {
    "@id": "https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE",
    "@type": "CreativeWork"
  },
  "name": "Dummy Material",
  "author": {
      "@type": "Person",
      "@id": "#aperson",
      "name": "Thomas B. Hickey",
      "identifier": "  0000-0002-1694-233X  "
  }
}])
    authors = learning_resource_extractor(json).send(:extract_people, RDF::Vocab::SCHEMA.author)
    assert_equal 1, authors.length
    assert_equal '0000-0002-1694-233X', authors.first[:orcid]
    assert_equal 'Thomas B. Hickey', authors.first[:name]


    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "LearningResource",
  "http://purl.org/dc/terms/conformsTo": {
    "@id": "https://bioschemas.org/profiles/TrainingMaterial/1.0-RELEASE",
    "@type": "CreativeWork"
  },
  "name": "Dummy Material",
  "author": {
      "@type": "Person",
      "@id": "#aperson",
      "name": "Patricia Palagi",
      "identifier": "https://something.that.isnt.an.orcid"
  }
}])
    authors = learning_resource_extractor(json).send(:extract_people, RDF::Vocab::SCHEMA.author)
    assert_equal 1, authors.length
    assert_nil authors.first[:orcid]
    assert_equal 'Patricia Palagi', authors.first[:name]
  end

  test 'extract instructors' do
    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "CourseInstance",
  "name": "Dummy Course Instance",
  "instructor": {
      "@type": "Person",
      "@id": "https://orcid.org/0000-0001-9062-6303",
      "name": "Patricia Palagi"
  }
}])
    instructors = course_instance_extractor(json).send(:extract_people, RDF::Vocab::SCHEMA.instructor)
    assert_equal 1, instructors.length
    assert_equal '0000-0001-9062-6303', instructors.first[:orcid]
    assert_equal 'Patricia Palagi', instructors.first[:name]

    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "CourseInstance",
  "name": "Dummy Course Instance",
  "instructor": {
      "@type": "Person",
      "@id": "#aperson",
      "name": "Patricia Palagi",
      "identifier": "https://orcid.org/0000-0001-9062-6303"
  }
}])
    instructors = course_instance_extractor(json).send(:extract_people, RDF::Vocab::SCHEMA.instructor)
    assert_equal 1, instructors.length
    assert_equal '0000-0001-9062-6303', instructors.first[:orcid]
    assert_equal 'Patricia Palagi', instructors.first[:name]

    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "CourseInstance",
  "name": "Dummy Course Instance",
  "instructor": {
      "@type": "Person",
      "@id": "#aperson",
      "name": "Thomas B. Hickey",
      "identifier": "  0000-0002-1694-233X  "
  }
}])
    instructors = course_instance_extractor(json).send(:extract_people, RDF::Vocab::SCHEMA.instructor)
    assert_equal 1, instructors.length
    assert_equal '0000-0002-1694-233X', instructors.first[:orcid]
    assert_equal 'Thomas B. Hickey', instructors.first[:name]


    json = %(
[{
  "@context": "https://schema.org/",
  "@type": "CourseInstance",
  "name": "Dummy Course Instance",
  "instructor": {
      "@type": "Person",
      "@id": "#aperson",
      "name": "Patricia Palagi",
      "identifier": "https://something.that.isnt.an.orcid"
  }
}])
    instructors = course_instance_extractor(json).send(:extract_people, RDF::Vocab::SCHEMA.instructor)
    assert_equal 1, instructors.length
    assert_nil instructors.first[:orcid]
    assert_equal 'Patricia Palagi', instructors.first[:name]
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

  def learning_resource_extractor(fixture, format: :jsonld, base_uri: 'https://example.com/my.json')
    ex = Tess::Rdf::LearningResourceExtractor.new(StringIO.new(fixture), format, base_uri: base_uri)
    ex.instance_variable_set(:@_temp_resource, ex.resources.first.individual)
    ex
  end
end