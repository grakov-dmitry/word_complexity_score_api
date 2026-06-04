module Integrations
  class Dictionary
    BASE_URL = 'https://api.dictionaryapi.dev/api/v2/entries/en/'.freeze

    def self.fetch_word_data(word)
      new(word).fetch_word_data
    end

    def initialize(word)
      @word = word
    end

    def fetch_word_data
      response = make_request
      return empty_result unless response.is_a?(Net::HTTPSuccess)

      parse_response(response.body)
    rescue StandardError => e
      Rails.logger.error("Integrations::Dictionary Error for word '#{@word}': #{e.message}")
      empty_result
    end

    private

    def make_request
      uri = URI("#{BASE_URL}#{@word}")
      Net::HTTP.get_response(uri)
    end

    def parse_response(body)
      data = JSON.parse(body)

      all_synonyms = []
      all_antonyms = []
      definitions_count = 0

      data.each do |entry|
        entry['meanings']&.each do |meaning|
          definitions_count += meaning['definitions']&.size || 0

          all_synonyms += meaning['synonyms'] if meaning['synonyms']
          all_antonyms += meaning['antonyms'] if meaning['antonyms']

          meaning['definitions']&.each do |definition|
            all_synonyms += definition['synonyms'] if definition['synonyms']
            all_antonyms += definition['antonyms'] if definition['antonyms']
          end
        end
      end

      {
        synonyms_count: all_synonyms.uniq.size,
        antonyms_count: all_antonyms.uniq.size,
        definitions_count: definitions_count
      }
    end

    def empty_result
      {
        synonyms_count: nil,
        antonyms_count: nil,
        definitions_count: nil
      }
    end
  end
end
