require 'net/http'

module Integrations
  class Dictionary
    BASE_URL = 'https://api.dictionaryapi.dev/api/v2/entries/en/'.freeze
    OPEN_TIMEOUT = 2
    READ_TIMEOUT = 5

    class Error < StandardError; end
    class TransientError < Error; end

    def self.fetch_word_data(word)
      new(word).fetch_word_data
    end

    def initialize(word)
      @word = word
    end

    def fetch_word_data
      response = make_request
      
      case response
      when ::Net::HTTPSuccess
        parse_response(response.body)
      when ::Net::HTTPNotFound
        empty_result
      when ::Net::HTTPTooManyRequests, ::Net::HTTPServerError
        raise TransientError, "Transient error: #{response.code} #{response.message}"
      else
        raise Error, "Unexpected API response: #{response.code} #{response.message}"
      end
    rescue ::Net::OpenTimeout, ::Net::ReadTimeout => e
      raise TransientError, "Timeout error: #{e.message}"
    rescue Error => e
      raise e
    rescue StandardError => e
      Rails.logger.error("Integrations::Dictionary Unexpected Error for word '#{@word}': #{e.message}")
      raise Error, e.message
    end

    private

    def make_request
      uri = URI("#{BASE_URL}#{@word}")
      
      ::Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', 
                      open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
        request = ::Net::HTTP::Get.new(uri)
        http.request(request)
      end
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
