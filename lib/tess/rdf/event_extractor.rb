module Tess
  module Rdf
    class EventExtractor

      include Tess::Rdf::Extraction

      def transform(params)
        # Concat Venue + Street Address since we don't have a field for that
        params[:venue] = [params[:venue], params.delete(:street_address)].compact.join(' ')
        params[:city] = params.delete(:locality)
        params[:county] = params.delete(:region)

        duration = params.delete(:duration)
        if !params[:end] && params[:start] && duration
          params[:end] = modify_date(params[:start], duration)
        end

        params[:contact] = [params.delete(:contact_name), params.delete(:contact_email)].compact.join( ' - ')
        params[:online] = true if params.delete(:course_mode) == 'online'
      end

      private

      def self.singleton_attributes
        [:title, :description, :start, :end, :venue, :postcode, :locality, :region, :country,
         :organizer, :duration, :url, :country, :latitude, :longitude, :capacity,
         :contact_name, :contact_email, :contact, :course_mode]
      end

      def self.array_attributes
        [:keywords, :scientific_topic_names, :host_institutions, :sponsors]
      end

      def self.type_query
        RDF::Query.new do
          pattern RDF::Query::Pattern.new(:individual, RDF.type, RDF::Vocab::SCHEMA.Event)
        end
      end

      def self.individual_queries(res)
        event_uri = res.individual
        [
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.name, :title, optional: true)
            pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.alternateName, :subtitle, optional: true)
            pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.description, :description, optional: true)
            pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.startDate, :start, optional: true)
            pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.endDate, :end, optional: true)
            pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.duration, :duration, optional: true)
            pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.url, :url, optional: true)
            pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.maximumAttendeeCapacity, :capacity, optional: true)
          end,
          # Other location info
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.location, :location)
            pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.name, :venue, optional: true)
            pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.streetAddress, :street_address, optional: true)
            pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.addressLocality, :locality, optional: true)
            pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.addressRegion, :region, optional: true)
            pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.addressCountry, :country, optional: true)
            pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.postalCode, :postcode, optional: true)
          end,
          #Location Geoocordinates
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.location, :location)
            pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.geo, :geo)
            pattern RDF::Query::Pattern.new(:geo, RDF::Vocab::SCHEMA.longitude, :longitude, optional: true)
            pattern RDF::Query::Pattern.new(:geo, RDF::Vocab::SCHEMA.latitude, :latitude, optional: true)
          end,
          #Location address
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(event_uri, RDF::Vocab::SCHEMA.location, :location)
            pattern RDF::Query::Pattern.new(:location, RDF::Vocab::SCHEMA.address, :address)
            pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.location, :location, optional: true)
            pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.postalCode, :postcode, optional: true)
            pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.addressCountry, :country, optional: true)
            pattern RDF::Query::Pattern.new(:address, RDF::Vocab::SCHEMA.addressLocality, :locality, optional: true)
          end,
          *shared_queries(event_uri)
        ]
      end

      # Query for attributes that are shared between Course, CourseInstance and Event
      def self.shared_queries(uri)
        [
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.name, :title, optional: true)
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.alternateName, :subtitle, optional: true)
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.description, :description, optional: true)
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.url, :url, optional: true)
            pattern RDF::Query::Pattern.new(uri, RDF::Vocabulary::Term.new('http://schema.org/topic', attributes: {}), :scientific_topic_names, optional: true)
            pattern RDF::Query::Pattern.new(uri, RDF::Vocabulary::Term.new('http://schema.org/keywords', attributes: {}), :keywords, optional: true)
          end,
          #Host institution
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocabulary::Term.new('http://schema.org/hostInstitution', attributes: {}), :host_institution)
            pattern RDF::Query::Pattern.new(:host_institution, RDF::Vocab::SCHEMA.name, :host_institutions, optional: true)
          end,
          #Sponsors
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.funder, :funder)
            pattern RDF::Query::Pattern.new(:funder, RDF::Vocab::SCHEMA.name, :sponsors, optional: true)
          end,
          #Organizer
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.organizer, :organizer_details)
            pattern RDF::Query::Pattern.new(:organizer_details, RDF::Vocab::SCHEMA.name, :organizer, optional: true)
          end,
          #Contact
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocabulary::Term.new('http://schema.org/contact', attributes: {}), :contact_details)
            pattern RDF::Query::Pattern.new(:contact_details, RDF::Vocab::SCHEMA.email, :contact_email, optional: true)
            pattern RDF::Query::Pattern.new(:contact_details, RDF::Vocab::SCHEMA.name, :contact_name, optional: true)
          end,
          #Audience
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.audience, :audience_details)
            pattern RDF::Query::Pattern.new(:audience_details, RDF::Vocab::SCHEMA.audienceType, :target_audience, optional: true)
          end,
          #Scientific topics
          RDF::Query.new do
            pattern RDF::Query::Pattern.new(uri, RDF::Vocab::SCHEMA.about, :topics)
            pattern RDF::Query::Pattern.new(:topics, RDF.type, RDF::Vocabulary::Term.new('http://schema.org/DefinedTerm', attributes: {}))
            pattern RDF::Query::Pattern.new(:topics, RDF::Vocab::SCHEMA.name, :scientific_topic_names, optional: true)
          end
        ]
      end
    end
  end
end
