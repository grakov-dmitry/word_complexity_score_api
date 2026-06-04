class ComplexityJob < ApplicationRecord
  self.primary_key = :job_id

  enum status: {
    pending: 'pending',
    in_progress: 'in_progress',
    completed: 'completed',
    failed: 'failed'
  }

  validates :job_id, presence: true, uniqueness: true
  validates :status, presence: true
end
