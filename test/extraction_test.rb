require 'test_helper'

class ExtractionTest < Test::Unit::TestCase
  test 'extract events from json-ld' do
    file = fixture_file('ebi-training-courses-tess-sample.json')

    extractor = Tess::Rdf::EventExtractor.new(file.read, :jsonld)
    resources = extractor.extract

    assert_equal 6, resources.count
    interpro = resources.detect { |r| r[:url] == 'https://www.ebi.ac.uk/training/events/interproscan' }
    assert_equal "InterProScan", interpro[:title]
    assert interpro[:description].include?('This webinar is about')
    assert_equal "https://www.ebi.ac.uk/training/events/interproscan", interpro[:url]
    assert_equal ["InterProScan", "Proteins (proteins)"], interpro[:keywords].sort
    assert_equal ["Function analysis", "Gene and protein families", "Protein domain", "Protein sequence", "Protein sequence analysis"].sort, interpro[:scientific_topic_names].sort
    assert_nil interpro[:event_types]
  end

  test 'extract courses from json-ld' do
    file = fixture_file('ebi-training-courses-tess-sample.json')

    extractor = Tess::Rdf::CourseExtractor.new(file.read, :jsonld)
    resources = extractor.extract

    assert_equal 14, resources.count
    rna_seq = resources.detect { |r| r[:url] == 'https://www.ebi.ac.uk/training/events/introduction-rna-seq-and-functional-interpretation-0' }
    refute rna_seq.key?(:keywords)
    assert_equal ["RNA-Seq"], rna_seq[:scientific_topic_names]
    assert_equal ["http://edamontology.org/topic_3170"], rna_seq[:scientific_topic_uris]
    refute rna_seq.key?(:host_institutions)
    refute rna_seq.key?(:sponsors)
    assert_equal "Introduction to RNA-seq and functional interpretation", rna_seq[:title]
    assert rna_seq[:description].include?('This course will provide an introduction to the technology')
    assert_equal "https://www.ebi.ac.uk/training/events/introduction-rna-seq-and-functional-interpretation-0", rna_seq[:url]
    assert_equal "2020-01-21", rna_seq[:start]
    assert_equal "2020-01-24", rna_seq[:end]
    assert_equal "30", rna_seq[:capacity]
    assert_equal "European Bioinformatics Institute, Hinxton", rna_seq[:venue]
    assert_equal "CB10 1SD", rna_seq[:postcode]
    assert_equal "GB", rna_seq[:country]
    assert_equal "Cambridge", rna_seq[:county]
    assert_equal [:workshops_and_courses], rna_seq[:event_types]
  end

  test 'extract events from HTML' do
    file = fixture_file('career-counseling-antwerp-0-vib.html')
    base_uri = 'https://training.vib.be/all-trainings/career-counseling-antwerp-0'

    extractor = Tess::Rdf::EventExtractor.new(file.read, :rdfa, base_uri: base_uri)
    resources = extractor.extract

    assert_equal 1, resources.count
    params = resources.first
    assert_equal "https://training.vib.be/all-trainings/career-counseling-antwerp-0", params[:url]
    assert_equal "Career Counseling (Antwerp)", params[:title]
    assert_equal "2022-12-01", params[:start]
    assert_equal "2022-12-01", params[:end]
    refute params.key?(:keywords)
    refute params.key?(:scientific_topic_names)
    refute params.key?(:scientific_topic_uris)
    refute params.key?(:host_institutions)
    refute params.key?(:sponsors)
    assert_equal "UAntwerpen Campus Drie Eiken, Universiteitsplein 1", params[:venue]
    assert_equal "51.162826", params[:latitude]
    assert_equal "4.402365", params[:longitude]
    assert_equal "2610", params[:postcode]
    assert_equal "Antwerpen", params[:city]
  end

  test 'extract learning resources from GTN tutorial HTML' do
    file = fixture_file('galaxy-training-network-tutorial.html')
    base_uri = 'https://training.galaxyproject.org/training-material/topics/assembly/tutorials/debruijn-graph-assembly/tutorial.html'

    extractor = Tess::Rdf::LearningResourceExtractor.new(file.read, :rdfa, base_uri: base_uri)
    resources = extractor.extract

    assert_equal 4, resources.count
    params = resources.detect { |r| r[:url] == base_uri }
    assert_equal params[:url], "https://training.galaxyproject.org/training-material/topics/assembly/tutorials/debruijn-graph-assembly/tutorial.html"
    assert_equal "Hands-on for 'De Bruijn Graph Assembly' tutorial", params[:title]
    assert params[:description].start_with?('The questions this')
    assert_equal "https://spdx.org/licenses/CC-BY-4.0.html", params[:licence]
    refute params.key?(:scientific_topic_names)
    refute params.key?(:scientific_topic_uris)
    assert_equal ["assembly"], params[:keywords]
    assert_equal ["Helena Rasche", "Saskia Hiltemann", "Simon Gladman"], params[:authors]
    assert_equal ["Students"], params[:target_audience]
    assert_equal ["hands-on tutorial"], params[:resource_type]
    assert_equal ["Helena Rasche", "Saskia Hiltemann", "Simon Gladman"], params[:contributors]
    assert_equal "Beginner", params[:difficulty_level]
  end

  test 'extract learning resources from GTN slide HTML' do
    file = fixture_file('galaxy-training-network-slides.html')
    base_uri = 'https://training.galaxyproject.org/training-material/topics/metagenomics/slides/introduction.html'

    extractor = Tess::Rdf::LearningResourceExtractor.new(file.read, :rdfa, base_uri: base_uri)
    resources = extractor.extract

    assert_equal 2, resources.count
    params = resources.detect { |r| r[:url] == base_uri }
    assert_equal params[:url], "https://training.galaxyproject.org/training-material/topics/metagenomics/slides/introduction.html"
    assert_equal "Introduction to 'Metagenomics'", params[:title]
    assert_equal "Slides for Metagenomics", params[:description]
    assert_equal "https://spdx.org/licenses/CC-BY-4.0.html", params[:licence]
    refute params.key?(:scientific_topic_names)
    assert_equal ["http://edamontology.org/topic_3174"], params[:scientific_topic_uris]
    refute params.key?(:keywords)
    assert_equal ["Bérénice Batut", "Saskia Hiltemann"], params[:authors]
    assert_equal ["Students"], params[:target_audience]
    assert_equal ["slides"], params[:resource_type]
    assert_equal ["Bérénice Batut", "Saskia Hiltemann"], params[:contributors]
    assert params[:node_names].include?('Belgium')
  end

  test 'extract course instance IFB JSON-LD (HTTPS)' do
    file = fixture_file('ifb-event.json')
    base_uri = 'https://catalogue.france-bioinformatique.fr/api/event/489/?format=json-ld'

    extractor = Tess::Rdf::CourseInstanceExtractor.new(file.read, :jsonld, base_uri: base_uri)
    resources = extractor.extract

    assert_equal 1, resources.count
    params = resources.first
    assert_equal params[:url], "https://www.france-bioinformatique.fr/formation/etbii/"
    assert_equal "Ecole Thématique de Bioinformatique Intégrative - session 2023 / Integrative Bioinforformatics training school - 2023 session", params[:title]
    assert params[:description].start_with?("Dans l’objectif de développer et fédérer")
    assert_equal '2023-01-16', params[:start]
    assert_equal '2023-01-20', params[:end]
    assert_equal '30', params[:capacity]
    refute params.key?(:scientific_topic_names)
    refute params.key?(:keywords)
    assert_equal [:workshops_and_courses], params[:event_types]
  end

  test 'extract course instance IFB JSON-LD (HTTP)' do
    file = fixture_file('http-ifb-event.json')
    base_uri = 'https://catalogue.france-bioinformatique.fr/api/event/489/?format=json-ld'

    extractor = Tess::Rdf::CourseInstanceExtractor.new(file.read, :jsonld, base_uri: base_uri)
    resources = extractor.extract

    assert_equal 1, resources.count
    params = resources.first
    assert_equal params[:url], "https://www.france-bioinformatique.fr/formation/etbii/"
    assert_equal "Ecole Thématique de Bioinformatique Intégrative - session 2023 / Integrative Bioinforformatics training school - 2023 session", params[:title]
    assert params[:description].start_with?("Dans l’objectif de développer et fédérer")
    assert_equal '2023-01-16', params[:start]
    assert_equal '2023-01-20', params[:end]
    assert_equal '30', params[:capacity]
    refute params.key?(:scientific_topic_names)
    refute params.key?(:keywords)
  end

  test 'extract SIB courses from JSON' do
    file = fixture_file('sib-upcoming-training-courses.html')
    base_uri = 'https://www.sib.swiss/training/upcoming-training-courses'

    extractor = Tess::Rdf::CourseExtractor.new(file.read, :rdfa, base_uri: base_uri)
    resources = extractor.extract

    assert_equal 29, resources.count
    params = resources.detect { |r| r[:url] == 'https://www.sib.swiss/training2/website/course/20220822_XXXX3' }
    assert_equal 'Advanced Statistics: Statistical Modelling', params[:title]
    assert params[:description].start_with?("**This course is now full with a long waiting list")
    assert_equal '2022-08-22', params[:start]
    assert_equal '2022-08-25', params[:end]
    assert_equal ['training', 'biostatistics', 'raphael gottardo group'].sort, params[:keywords].sort
    assert_equal 'Patricia Palagi', params[:organizer]
    assert params[:node_names].include?('Switzerland')
  end

  test 'handle JSON-LD containing https://schema prefix instead' do
    file = fixture_file('rdfa-with-https')
    base_uri = 'https://www.sib.swiss/training/upcoming-training-courses'

    assert_nothing_raised do
      extractor = Tess::Rdf::EventExtractor.new(file.read, :rdfa, base_uri: base_uri)
      extractor.extract
    end
  end

  test 'extract street address as venue' do
    file = fixture_file('nbis-courses.json')
    base_uri = 'https://nbis.se/assets/training/courses.json'

    extractor = Tess::Rdf::CourseInstanceExtractor.new(file.read, :jsonld, base_uri: base_uri)
    events = extractor.extract
    sample = events.detect { |e| e[:title] = 'Neural Networks and Deep Learning' }
    assert_equal 'SciLifeLab Uppsala - Navet, Husargatan 3', sample[:venue]
  end

  test 'extract courseMode as online' do
    file = fixture_file('sib-online-course.html')
    base_uri = 'https://www.sib.swiss/training/course/20230426_DOCK'

    extractor = Tess::Rdf::CourseExtractor.new(file.read, :rdfa, base_uri: base_uri)
    events = extractor.extract
    sample = events.detect { |e| e[:start] = '2023-04-26' }
    assert sample[:online]
  end

  test 'tolerates analytics script tags' do
    file = fixture_file('proteomicsml.html')
    base_uri = 'https://proteomicsml.org/'

    extractor = Tess::Rdf::LearningResourceExtractor.new(file.read, :rdfa, base_uri: base_uri)
    resources = extractor.extract

    assert_equal 1, resources.count
    params = resources.detect { |r| r[:url] == base_uri }
    assert_equal params[:url], 'https://proteomicsml.org/'
    assert_equal 'ProteomicsML', params[:title]
    assert params[:description].include?('ProteomicsML provides ready-made datasets')
    assert_equal 'https://spdx.org/licenses/CC-BY-4.0.html', params[:licence]
    assert_equal ['http://edamontology.org/0121', 'http://edamontology.org/3474',
                  'http://edamontology.org/data_2536', 'http://edamontology.org/data_3670',
                  'http://edamontology.org/topic_0091'].sort,
                 params[:scientific_topic_uris].sort
    assert_equal ['bioinformatics', 'community platform', 'deep learning', 'detectability', 'educational platform',
                  'fragmentation', 'ion mobility', 'machine learning', 'proteomics', 'retention time'].sort,
                 params[:keywords].sort
    assert_equal ['PhD students', 'Postdoctoral researchers', 'Students'].sort, params[:target_audience].sort
    assert_equal ['tutorials'], params[:resource_type]
  end
end
