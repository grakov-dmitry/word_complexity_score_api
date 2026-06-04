class ProcessWordComplexity
  def self.call(words)
    new(words).call
  end

  def initialize(words)
    @words = words.uniq
  end

  def call
    cached_words = DictionaryWord.where(word: @words).index_by(&:word)
    new_word_strings = @words - cached_words.keys

    new_words_data = fetch_and_save_new_words(new_word_strings)
    
    results = {}
    
    @words.each do |word|
      if cached_words.key?(word)
        results[word] = cached_words[word].complexity_score
      elsif new_words_data.key?(word)
        results[word] = new_words_data[word]
      else
        results[word] = nil
      end
    end

    results
  end

  private

  def fetch_and_save_new_words(word_strings)
    return {} if word_strings.empty?

    new_records_attributes = []
    results_map = {}

    word_strings.each do |word_string|
      api_data = Integrations::Dictionary.fetch_word_data(word_string)
      score = calculate_score(api_data)

      new_records_attributes << {
        word: word_string,
        synonyms_count: api_data[:synonyms_count],
        antonyms_count: api_data[:antonyms_count],
        definitions_count: api_data[:definitions_count],
        complexity_score: score,
        created_at: Time.current,
        updated_at: Time.current
      }
      results_map[word_string] = score
    end

    DictionaryWord.insert_all(new_records_attributes) if new_records_attributes.any?

    results_map
  end

  def calculate_score(data)
    return nil if data[:definitions_count].nil?

    denom = data[:definitions_count].to_f
    return 0.0 if denom.zero?

    (data[:synonyms_count].to_i + data[:antonyms_count].to_i) / denom
  end
end
