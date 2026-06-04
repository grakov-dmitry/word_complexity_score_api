require 'rails_helper'
require 'net/http'

RSpec.describe Integrations::Dictionary do
  let(:word) { 'apple' }
  let(:dictionary) { described_class.new(word) }

  describe '#fetch_word_data' do
    it 'returns parsed data on success (200)' do
      body = [{ 'meanings' => [{ 'definitions' => [{}], 'synonyms' => ['fruit'], 'antonyms' => [] }] }].to_json
      response = Net::HTTPSuccess.new('1.1', '200', 'OK')
      allow(response).to receive(:body).and_return(body)
      allow(Net::HTTP).to receive(:start).and_return(response)

      result = dictionary.fetch_word_data
      expect(result[:definitions_count]).to eq(1)
      expect(result[:synonyms_count]).to eq(1)
    end

    it 'returns empty_result on 404' do
      response = Net::HTTPNotFound.new('1.1', '404', 'Not Found')
      allow(Net::HTTP).to receive(:start).and_return(response)

      result = dictionary.fetch_word_data
      expect(result[:definitions_count]).to be_nil
    end

    it 'raises TransientError on 500' do
      response = Net::HTTPInternalServerError.new('1.1', '500', 'Internal Server Error')
      allow(Net::HTTP).to receive(:start).and_return(response)

      expect { dictionary.fetch_word_data }.to raise_error(Integrations::Dictionary::TransientError)
    end

    it 'raises TransientError on 429' do
      response = Net::HTTPTooManyRequests.new('1.1', '429', 'Too Many Requests')
      allow(Net::HTTP).to receive(:start).and_return(response)

      expect { dictionary.fetch_word_data }.to raise_error(Integrations::Dictionary::TransientError)
    end

    it 'raises TransientError on timeout' do
      allow(Net::HTTP).to receive(:start).and_raise(Net::OpenTimeout)

      expect { dictionary.fetch_word_data }.to raise_error(Integrations::Dictionary::TransientError)
    end

    it 'sets correct timeouts' do
      mock_http = instance_double(Net::HTTP)
      expect(Net::HTTP).to receive(:start).with(
        anything, anything,
        any_args
      ).and_yield(mock_http)

      mock_response = Net::HTTPNotFound.new('1.1', '404', 'Not Found')
      expect(mock_http).to receive(:request).and_return(mock_response)

      dictionary.fetch_word_data
    end
  end

  describe '#parse_response' do
    it 'correctly aggregates synonyms, antonyms and definitions count' do
      body = [
        {
          'meanings' => [
            {
              'definitions' => [
                { 'synonyms' => ['joyful'], 'antonyms' => ['sad'] },
                { 'synonyms' => ['content'], 'antonyms' => [] }
              ],
              'synonyms' => ['cheerful'],
              'antonyms' => []
            }
          ]
        },
        {
          'meanings' => [
            {
              'definitions' => [
                { 'synonyms' => [], 'antonyms' => ['unhappy'] }
              ],
              'synonyms' => ['joyful'],
              'antonyms' => ['miserable']
            }
          ]
        }
      ].to_json

      result = dictionary.send(:parse_response, body)
      expect(result[:synonyms_count]).to eq(3)
      expect(result[:antonyms_count]).to eq(3)
      expect(result[:definitions_count]).to eq(3)
    end
  end
end
