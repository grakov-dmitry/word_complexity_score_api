require 'rails_helper'

RSpec.describe "ComplexityScores", type: :request do
  describe "POST /complexity-score" do
    let(:valid_words) { ["apple", "banana"] }
    let(:invalid_words) { ["apple", "123!"] }
    let(:too_many_words) { Array.new(31, "word") }

    it "returns 202 Accepted for valid input" do
      post "/complexity-score", params: { _json: valid_words }, as: :json
      expect(response).to have_http_status(:accepted)
      expect(JSON.parse(response.body)).to have_key("job_id")
    end

    it "normalizes words to lowercase" do
      expect(CalculateComplexityWorker).to receive(:perform_async).with(anything, ["happy"])
      post "/complexity-score", params: { _json: ["Happy", "HAPPY"] }, as: :json
    end

    it "returns 422 for invalid characters" do
      post "/complexity-score", params: { _json: invalid_words }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to include("Invalid input")
    end

    it "returns 422 for too many words" do
      post "/complexity-score", params: { _json: too_many_words }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["error"]).to include("Expected an array of up to 30")
    end
  end

  describe "GET /complexity-score/:job_id" do
    let(:job) { ComplexityJob.create!(job_id: "test12", status: :completed, results: { "apple" => 1.5 }) }

    it "returns 200 for existing job" do
      get "/complexity-score/#{job.job_id}"
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["status"]).to eq("completed")
      expect(data["result"]["apple"]).to eq(1.5)
    end

    it "returns 404 for non-existent job" do
      get "/complexity-score/nonexistent"
      expect(response).to have_http_status(:not_found)
    end
  end
end
