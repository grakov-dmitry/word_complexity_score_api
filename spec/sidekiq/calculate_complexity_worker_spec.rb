require 'rails_helper'

RSpec.describe CalculateComplexityWorker, type: :job do
  let(:job_id) { 'test_job' }
  let(:words) { ['apple'] }
  let!(:job) { ComplexityJob.create!(job_id: job_id, status: :pending) }

  describe '#perform' do
    it 'updates job status to completed and saves results' do
      allow(ProcessWordComplexity).to receive(:call).with(words).and_return({ 'apple' => 1.5 })
      
      described_class.new.perform(job.job_id, words)
      
      job.reload
      expect(job.status).to eq('completed')
      expect(job.results).to eq({ 'apple' => 1.5 })
    end

    it 'bubbles up errors for Sidekiq retry' do
      allow(ProcessWordComplexity).to receive(:call).and_raise(StandardError, "DB Error")
      
      expect {
        described_class.new.perform(job.job_id, words)
      }.to raise_error(StandardError, "DB Error")
    end
  end

  describe '.sidekiq_retries_exhausted' do
    it 'marks job as failed and records error message' do
      msg = { 'args' => [job.job_id] }
      exception = StandardError.new("Persistent Error")
      
      described_class.sidekiq_retries_exhausted_block.call(msg, exception)
      
      job.reload
      expect(job.status).to eq('failed')
      expect(job.results['error']).to include("Retries exhausted: Persistent Error")
      expect(job.results).to have_key('failed_at')
    end
  end
end
