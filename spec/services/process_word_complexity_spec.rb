require 'rails_helper'

RSpec.describe ProcessWordComplexity do
  let(:words) { ['apple', 'banana', 'orange'] }
  let(:api_response_apple) do
    { synonyms_count: 2, antonyms_count: 1, definitions_count: 2 } # score: (2+1)/2 = 1.5
  end
  let(:api_response_banana) do
    { synonyms_count: 0, antonyms_count: 0, definitions_count: 1 } # score: 0/1 = 0.0
  end

  describe '.call' do
    before do
      allow(Integrations::Dictionary).to receive(:fetch_word_data).with('apple').and_return(api_response_apple)
      allow(Integrations::Dictionary).to receive(:fetch_word_data).with('banana').and_return(api_response_banana)
    end

    context 'when words are not in cache' do
      it 'calls the API for each new word' do
        expect(Integrations::Dictionary).to receive(:fetch_word_data).with('apple').once
        expect(Integrations::Dictionary).to receive(:fetch_word_data).with('banana').once
        
        ProcessWordComplexity.call(['apple', 'banana'])
      end

      it 'saves new words to the database' do
        expect {
          ProcessWordComplexity.call(['apple', 'banana'])
        }.to change(DictionaryWord, :count).by(2)
      end

      it 'returns the correct scores' do
        results = ProcessWordComplexity.call(['apple', 'banana'])
        expect(results['apple']).to eq(1.5)
        expect(results['banana']).to eq(0.0)
      end
    end

    context 'when words are already in cache' do
      before do
        DictionaryWord.create!(
          word: 'apple',
          synonyms_count: 2,
          antonyms_count: 1,
          definitions_count: 2,
          complexity_score: 1.5
        )
      end

      it 'does not call the API for cached words' do
        expect(Integrations::Dictionary).not_to receive(:fetch_word_data).with('apple')
        expect(Integrations::Dictionary).to receive(:fetch_word_data).with('banana').once
        
        ProcessWordComplexity.call(['apple', 'banana'])
      end

      it 'returns scores from cache' do
        results = ProcessWordComplexity.call(['apple', 'banana'])
        expect(results['apple']).to eq(1.5)
        expect(results['banana']).to eq(0.0)
      end
    end

    context 'with unknown word' do
      it 'returns nil and saves to database' do
        allow(Integrations::Dictionary).to receive(:fetch_word_data).with('unknown').and_return(
          { synonyms_count: nil, antonyms_count: nil, definitions_count: nil }
        )
        
        results = ProcessWordComplexity.call(['unknown'])
        expect(results['unknown']).to be_nil
        expect(DictionaryWord.find_by(word: 'unknown').complexity_score).to be_nil
      end
    end
  end
end
