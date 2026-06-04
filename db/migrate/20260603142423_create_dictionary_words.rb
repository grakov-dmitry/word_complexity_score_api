class CreateDictionaryWords < ActiveRecord::Migration[7.1]
  def change
    create_table :dictionary_words do |t|
      t.string :word, null: false
      t.integer :synonyms_count
      t.integer :antonyms_count
      t.integer :definitions_count
      t.float :complexity_score

      t.timestamps
    end
    add_index :dictionary_words, :word, unique: true
  end
end
