require './app/models/data_fetcher'

namespace :data do
  desc "Fetches the latest data and saves it to S3"
  task :fetch do
    DataFetcher.new.fetch!
  end
end
