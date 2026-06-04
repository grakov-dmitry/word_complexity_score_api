class CalculateComplexityWorker
  include Sidekiq::Job

  def perform(job_id, words)
    job = ComplexityJob.find(job_id)
    job.update!(status: :in_progress)

    results = ProcessWordComplexity.call(words)

    job.update!(
      status: :completed,
      results: results
    )
  rescue StandardError => e
    Rails.logger.error("CalculateComplexityWorker failed for job #{job_id}: #{e.message}")
    
    job ||= ComplexityJob.find_by(job_id: job_id)
    job&.update(status: :failed)
  end
end
