RSpec.configure do |config|
  config.before do
    ENV["AWS_ACCESS_KEY_ID"] = "aws_access_key_id"
    ENV["AWS_SECRET_ACCESS_KEY"] = "aws_secret_access_key"
    ENV["AWS_S3_BUCKET"] = "awss3bucket"
    ENV["RESQUE_QUEUE"] = nil
    ENV["RESQUE_WORKER"] = nil
    ENV["REDIS_URL"] = nil
    ENV["GMAIL_ACCOUNT"] = nil
    ENV["GMAIL_PASSWORD"] = nil
    ENV["RECIPIENT_EMAIL"] = nil
  end
end
