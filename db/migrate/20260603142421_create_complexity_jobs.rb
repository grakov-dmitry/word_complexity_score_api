class CreateComplexityJobs < ActiveRecord::Migration[7.1]
  def change
    create_table :complexity_jobs, id: false do |t|
      t.string :job_id, primary_key: true
      t.string :status, null: false, default: 'pending'
      t.jsonb :results, default: {}

      t.timestamps
    end
    add_index :complexity_jobs, :job_id, unique: true
  end
end
