class CalculateComplexityWorker
  include Sidekiq::Job

  sidekiq_options retry: 5

  sidekiq_retries_exhausted do |msg, e|
    job_id = msg['args'].first
    job = ComplexityJob.find_by(job_id: job_id)
    job&.update(
      status: :failed,
      results: { error: "Retries exhausted: #{e.message}", failed_at: Time.current }
    )
    Rails.logger.error("CalculateComplexityWorker EXHAUSTED for job #{job_id}: #{e.message}")
  end

  def perform(job_id, words)
    job = ComplexityJob.find_by(job_id: job_id)
    
    if job.nil?
      raise ActiveRecord::RecordNotFound, "ComplexityJob with job_id=#{job_id} not found yet"
    end

    job.update!(status: :in_progress)

    results = ProcessWordComplexity.call(words)

    job.update!(
      status: :completed,
      results: results
    )
  end
end
