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
  end

  test 'extract courses from json-ld' do
    file = fixture_file('ebi-training-courses-tess-sample.json')

    extractor = Tess::Rdf::CourseExtractor.new(file.read, :jsonld)
    resources = extractor.extract

    assert_equal 14, resources.count
    rna_seq = resources.detect { |r| r[:url] == 'https://www.ebi.ac.uk/training/events/introduction-rna-seq-and-functional-interpretation-0' }
    assert_equal [], rna_seq[:keywords]
    assert_equal ["RNA-Seq"], rna_seq[:scientific_topic_names]
    assert_equal ["edam:http://edamontology.org/topic_3170"], rna_seq[:scientific_topic_uris]
    assert_equal [], rna_seq[:host_institutions]
    assert_equal [], rna_seq[:sponsors]
    assert_equal "Introduction to RNA-seq and functional interpretation", rna_seq[:title]
    assert rna_seq[:description].include?('This course will provide an introduction to the technology')
    assert_equal "https://www.ebi.ac.uk/training/events/introduction-rna-seq-and-functional-interpretation-0", rna_seq[:url]
    assert_equal "2020-01-21", rna_seq[:start]
    assert_equal "2020-01-24", rna_seq[:end]
    assert_equal "30", rna_seq[:capacity]
    assert_equal "European Bioinformatics Institute", rna_seq[:venue]
    assert_equal "CB10 1SD", rna_seq[:postcode]
    assert_equal "GB", rna_seq[:country]
    assert_equal "Cambridge", rna_seq[:county]

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
    assert_equal [], params[:keywords]
    assert_equal [], params[:scientific_topic_names]
    assert_equal [], params[:scientific_topic_uris]
    assert_equal [], params[:host_institutions]
    assert_equal [], params[:sponsors]
    assert_equal "UAntwerpen Campus Drie Eiken", params[:venue]
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
    assert_equal [], params[:scientific_topic_names]
    assert_equal [], params[:scientific_topic_uris]
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
    assert_equal [], params[:scientific_topic_names]
    assert_equal ["http://edamontology.org/topic_3174"], params[:scientific_topic_uris]
    assert_equal [], params[:keywords]
    assert_equal ["Bérénice Batut", "Saskia Hiltemann"], params[:authors]
    assert_equal ["Students"], params[:target_audience]
    assert_equal ["slides"], params[:resource_type]
    assert_equal ["Bérénice Batut", "Saskia Hiltemann"], params[:contributors]
  end
end
