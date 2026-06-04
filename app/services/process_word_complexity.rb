class ProcessWordComplexity
  def self.call(words)
    new(words).call
  end

  def initialize(words)
    @words = words.uniq
  end

  def call
    cached_words = DictionaryWord.cached_words(@words)
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
    mutex = Mutex.new

    word_strings.each_slice(5) do |slice|
      threads = slice.map do |word_string|
        Thread.new do
          begin
            api_data = Integrations::Dictionary.fetch_word_data(word_string)
            score = calculate_score(api_data)

            mutex.synchronize do
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
          rescue StandardError => e
            Rails.logger.error("Error processing word '#{word_string}' in thread: #{e.message}")
            raise e
          end
        end
      end
      threads.each(&:join)
    end

    DictionaryWord.insert_all(new_records_attributes, unique_by: :word) if new_records_attributes.any?

    results_map
  end

  def calculate_score(data)
    return nil if data[:definitions_count].nil?

    denom = data[:definitions_count].to_f
    return 0.0 if denom.zero?

    (data[:synonyms_count].to_i + data[:antonyms_count].to_i) / denom
  end
end
