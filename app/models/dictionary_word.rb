class DictionaryWord < ApplicationRecord
  validates :word, presence: true, uniqueness: true

  def self.cached_words(words)
    where(word: words).index_by(&:word)
  end
end
