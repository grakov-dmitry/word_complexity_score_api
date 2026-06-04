# Word Complexity Score API

A Ruby on Rails API application that calculates the "complexity score" of English words based on data retrieved from an external dictionary API (`api.dictionaryapi.dev`).

## 🧠 How it Works

The complexity score is calculated using the following formula:
`score = (synonyms + antonyms) / definitions`

**Key Features:**
- **Background Processing:** The actual fetching and calculation are handled asynchronously using Sidekiq, preventing the API from blocking.
- **Fail Fast:** Immediate input validation ensures only valid English words are processed.
- **Caching:** Calculated scores are stored in a PostgreSQL database (using `jsonb`). If a word is requested again, the application retrieves it from the local cache instead of making another external API call.
- **Smart Handling:** If a word doesn't exist in the external dictionary, it returns `null`.

## 🛠 Tech Stack

- **Language:** Ruby 3.3.0
- **Framework:** Ruby on Rails 7.1.6
- **Database:** PostgreSQL
- **Background Jobs:** Sidekiq + Redis
- **Testing:** RSpec

---

## 🚀 Setup & Installation (Local Development)

### 1. Project Initialization
Clone the repository, install dependencies, and set up the database. 

**Note:** Ensure you have **Redis** installed and running. By default, the application connects to `redis://localhost:6379/1`. You can override this by setting the `REDIS_URL` environment variable.

```bash
# Install gems
bundle install

# Create database and run migrations
rails db:create
rails db:migrate
```

### 2. Running the Application
You don't need to start the web server and worker in separate tabs. The project includes a convenient script that uses `foreman` to run both Rails and Sidekiq concurrently:

```bash
./bin/dev
```
*The API will be available at `http://localhost:3000`.*

---

## 📡 API Endpoints

### 1. Request Complexity Calculation
**POST** `/complexity-score`

Submits an array of English words for calculation. The process runs in the background.

**Request Body:**
```json
[
  "happy",
  "joyful",
  "unknown-word"
]
```

**Response (`202 Accepted`):**
```json
{
  "job_id": "aB3dE5"
}
```

**Response (`422 Unprocessable Entity`):**
Returned if the input is not an array or contains invalid characters (only letters and hyphens allowed).
```json
{
  "error": "Invalid input. Expected an array of English words."
}
```

---

### 2. Retrieve Results
**GET** `/complexity-score/:job_id`

Fetches the current status and results of a job.

**Response (`200 OK`):**
```json
{
  "status": "completed",
  "result": {
    "happy": 3.0,
    "joyful": 0.0,
    "unknown-word": null
  }
}
```
*Note: Result values can be `float` (score), `0.0` (word found but no synonyms/antonyms), or `null` (word not found in dictionary).*

**Response (`404 Not Found`):**
Returned if the `job_id` does not exist.
```json
{
  "error": "Job not found"
}
```

---

## 🧪 Testing

The project uses RSpec for testing, particularly focusing on the core business logic (Service Objects) to ensure accurate calculations and caching behavior.

To run the test suite:
```bash
bundle exec rspec
```
