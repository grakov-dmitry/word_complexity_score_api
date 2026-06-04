class ComplexityScoresController < ApplicationController
  def create
    words = params[:_json] || params[:words]

    unless valid_input?(words)
      return render json: { error: 'Invalid input. Expected an array of English words.' }, status: :unprocessable_entity
    end

    job_id = SecureRandom.alphanumeric(6)
    ComplexityJob.create!(job_id: job_id, status: :pending)
    CalculateComplexityWorker.perform_async(job_id, words)

    render json: { job_id: job_id }, status: :accepted
  end

  def show
    job = ComplexityJob.find_by(job_id: params[:job_id])

    if job
      render json: { status: job.status, result: job.results }
    else
      render json: { error: 'Job not found' }, status: :not_found
    end
  end

  private

  def valid_input?(words)
    return false unless words.is_a?(Array) && words.any?

    word_regex = /\A[a-zA-Z-]+\z/
    words.all? { |word| word.is_a?(String) && word.match?(word_regex) }
  end
end
