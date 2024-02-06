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
    assert_equal "https://training.galaxyproject.org/training-material/topics/assembly/tutorials/debruijn-graph-assembly/tutorial.html", params[:url]
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
    assert_equal "https://training.galaxyproject.org/training-material/topics/metagenomics/slides/introduction.html", params[:url]
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
    assert_equal "https://www.france-bioinformatique.fr/formation/etbii/", params[:url]
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
    assert_equal "https://www.france-bioinformatique.fr/formation/etbii/",  params[:url]
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
    assert_equal 'Patricia Palagi (https://orcid.org/0000-0001-9062-6303), SIB Swiss Institute of Bioinformatics (https://ror.org/002n09z45)', params[:organizer]
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
    assert_equal 'https://proteomicsml.org/', params[:url]
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

  test 'online flag' do
    base_uri = 'https://www.ebi.ac.uk/api/v1/ebi-training-courses-tess?source=trainingcontenthub'

    # online courseMode
    extractor = Tess::Rdf::CourseInstanceExtractor.new(fixture_file('ebi-course-online.json'), :jsonld, base_uri: base_uri)
    resources = extractor.extract
    assert_equal 1, resources.count
    params = resources.first
    assert_equal 'https://www.ebi.ac.uk/training/events/plant-genomes-data-discovery', params[:url]
    assert_true params[:online], 'online flag should be present and set to true'

    # Non-online courseMode
    extractor = Tess::Rdf::CourseInstanceExtractor.new(fixture_file('ebi-course-face-to-face.json'), :jsonld, base_uri: base_uri)
    resources = extractor.extract
    assert_equal 1, resources.count
    params = resources.first
    assert_equal 'https://www.ebi.ac.uk/training/events/ccpbiosim-workshop-structural-bioinformatics-resources-and-tools-molecular-dynamics-simulations', params[:url]
    assert_false params[:online], 'online flag should be present and set to false'

    # No courseMode provided
    e = JSON.parse(fixture_file('ebi-course-face-to-face.json').read)
    e['hasCourseInstance'].each { |ci| ci.delete('courseMode') }
    extractor = Tess::Rdf::CourseInstanceExtractor.new(JSON.generate(e), :jsonld, base_uri: base_uri)
    resources = extractor.extract
    assert_equal 1, resources.count
    params = resources.first
    assert_equal 'https://www.ebi.ac.uk/training/events/ccpbiosim-workshop-structural-bioinformatics-resources-and-tools-molecular-dynamics-simulations', params[:url]
    refute params.key?(:online), 'online flag should not be present'
  end

  test 'uses @id as url in json-ld' do
    file = fixture_file('no-url.json')

    extractor = Tess::Rdf::LearningResourceExtractor.new(file.read, :jsonld)
    resources = extractor.extract

    assert_equal 1, resources.count
    rnacentral = resources.detect { |r| r[:url] == 'https://www.ebi.ac.uk/training/online/courses/rnacentral' }
    assert_equal 'RNAcentral: Exploring non-coding RNAs', rnacentral[:title]
    assert rnacentral[:description].include?('Non-coding RNAs (ncRNAs) are essential for all life')
    assert_equal ['ncRNA', 'lncRNA', 'microRNA', 'Non-coding RNA'].sort, rnacentral[:keywords].sort
    assert_equal ['Functional, regulatory and non-coding RNA', 'rna'].sort, rnacentral[:scientific_topic_names].sort
    assert_equal ['PhD students', 'Clinicians'].sort, rnacentral[:target_audience].sort
    assert_equal ['e-learning'], rnacentral[:resource_type].sort
  end

  test 'extract material from legacy Bioconductor CreativeWork markup' do
    file = fixture_file('bridgedbr-tutorial.html')
    base_uri = 'https://bioconductor.org/packages/release/bioc/vignettes/BridgeDbR/inst/doc/tutorial.html'

    extractor = Tess::Rdf::MaterialExtractor.new(file.read, :rdfa, base_uri: base_uri)
    resources = extractor.extract

    assert_equal 1, resources.count
    params = resources.first
    assert_equal 'BridgeDbR Tutorial', params[:title]
    assert_equal 'https://bioconductor.org/packages/devel/bioc/vignettes/BridgeDbR/inst/doc/tutorial.html', params[:url]
    assert_equal ['ELIXIR RIR', 'BridgeDb'], params[:keywords]
    assert_equal 'https://bioconductor.org/packages/release/bioc/vignettes/BridgeDbR/inst/doc/AGPL-3', params[:licence]
    assert_equal '1.17.5', params[:version]
    assert_equal ['Egon Willighagen'], params[:authors]
  end

  test 'extract event from legacy Edinburgh Genomics Event markup' do
    file = fixture_file('metagenomics-metabarcoding.html')
    base_uri = 'https://genomics.ed.ac.uk/services/metagenomics-metabarcoding'

    extractor = Tess::Rdf::EventExtractor.new(file.read, :rdfa, base_uri: base_uri)
    resources = extractor.extract

    assert_equal 1, resources.count
    params = resources.first

    assert_equal 'Metagenomics and Metabarcoding', params[:title]
    assert_equal 'This course focuses on the computational methods used to analyse the wealth of data produced by shotgun metagenomics and metabarcoding (Amplicon targeted metagenomics) studies. This course will provide you the insights to the DNA metabarcoding analyses from preprocessing and quality control of the raw data to the construction of OTU/ASV tables, taxon assignment, diversity analysis and differential abundance analysis using QIIME2. Further, you will also learn about methods to generate the reference-based profile to generate microbial community features like taxonomic abundances or functional profile and how to identify the ones characterizing differences between two biological conditions. You will then be introduced to methods used for assembly from metagenomics samples. Attendees will use tools to assemble metagenome assembled genomes (MAGs) from short read and long read data. We will discuss the different approaches and tools available for these assemblies and the benefits and limitations of each options.', params[:description]
    assert_equal 'http://genomics.ed.ac.uk/services/metagenomics-metabarcoding', params[:url]
    assert_equal '2019-08-28T09:00', params[:start]
    assert_equal '2019-08-30T17:00', params[:end]
    assert_equal "The King's Buildings, The University of Edinburgh, West Mains Road", params[:venue]
    assert_equal 'UK', params[:country]
    assert_equal 'EH9 3JN', params[:postcode]
    assert_equal 'Edinburgh', params[:city]
    assert_equal 'Edinburgh Genomics Training Team - edge-training@ed.ac.uk', params[:contact]
    assert_equal ['Bioinformatics', 'Genomics', 'Long-read', 'Metabarcoding', 'Metagenomics'], params[:scientific_topic_names]
    assert_equal ['Edinburgh Genomics'], params[:host_institutions]
  end

  test 'extract multiple organizers as comma-separated string' do
    file = fixture_file('ifb-multi-organizers.json')
    base_uri = 'https://catalogue.france-bioinformatique.fr/api/event/591/?format=json-ld'

    extractor = Tess::Rdf::CourseInstanceExtractor.new(file.read, :jsonld, base_uri: base_uri)
    resources = extractor.extract

    assert_equal 1, resources.count
    params = resources.first

    assert_equal "https://catalogue.france-bioinformatique.fr/api/organisation/CIRAD/?format=json-ld, https://catalogue.france-bioinformatique.fr/api/organisation/INRAE/?format=json-ld, https://catalogue.france-bioinformatique.fr/api/organisation/IRD/?format=json-ld, https://catalogue.france-bioinformatique.fr/api/team/South%20Green/?format=json-ld",
                 params[:organizer]
  end
end
