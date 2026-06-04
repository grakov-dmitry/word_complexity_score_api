class ComplexityScoresController < ApplicationController
  MAX_WORDS = 30

  def create
    words = params[:_json]

    unless valid_input?(words)
      return render json: { error: "Invalid input. Expected an array of up to #{MAX_WORDS} English words." }, status: :unprocessable_entity
    end

    normalized_words = words.map(&:downcase).uniq
    job_id = SecureRandom.alphanumeric(6)
    ComplexityJob.create!(job_id: job_id, status: :pending)
    CalculateComplexityWorker.perform_async(job_id, normalized_words)

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
    return false if words.size > MAX_WORDS

    word_regex = /\A[a-zA-Z-]+\z/
    words.all? { |word| word.is_a?(String) && word.match?(word_regex) }
  end
end
