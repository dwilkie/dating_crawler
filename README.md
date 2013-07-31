# Dating Crawler

[![Build Status](https://travis-ci.org/dwilkie/dating_crawler.png)](https://travis-ci.org/dwilkie/dating_crawler) [![Dependency Status](https://gemnasium.com/dwilkie/dating_crawler.png)](https://gemnasium.com/dwilkie/dating_crawler) [![Code Climate](https://codeclimate.com/github/dwilkie/dating_crawler.png)](https://codeclimate.com/github/dwilkie/dating_crawler)


Crawls the web, mining for phone numbers and metadata of people who are interested in Mobile Dating, then saves the results to your configured S3 Bucket.

Optionally you can have it send an email summarizing the results or queue a Resque job to process the results.

## Installation

Clone the app

    $ git clone https://github.com/dwilkie/dating_crawler.git

And then execute:

    $ bundle

## Configuration

### Environment Variables

Configuration can be specified thorugh environment variables. The following environment variables can be used:

    AWS_ACCESS_KEY_ID       # required - your aws access key id
    AWS_SECRET_ACCESS_KEY   # required - your aws secret access key
    AWS_S3_BUCKET           # required - the bucket in which to upload the results
    RACK_ENV=production     # required - specifies your environment

    GMAIL_ACCOUNT           # optional - the Gmail account to use when sending the results email
    GMAIL_PASSWORD          # optional - the Gmail password for the account above
    RECIPIENT_EMAIL         # optional - the recipient of the results email

    REDIS_URL               # optional - the redis URL to connect to for queuing the Resque job
    RESQUE_QUEUE            # optional - the resque queue in which to queue the job
    RESQUE_WORKER           # optional - the resque worker which will run the job

### Passing directly

You can also configure the app by passing the configuration directly. E.g.

    require './app/models/data_fetcher'

    DataFetcher.new.fetch!(configuration)

    See: [the source](https://github.com/dwilkie/dating_crawler/blob/master/app/models/data_fetcher.rb) for all available configuration options.


## Usage

### Rake Task

    $ bundle exec rake data:fetch

### Use it directly

    require './app/models/data_fetcher'

    DataFetcher.new.fetch!(configuration)

## Deployment

### Heroku

#### Create a Heroku app

    $ heroku create
    $ git push heroku master

#### Configure the required environment variables

    $ heroku config:add AWS_ACCESS_KEY_ID=aws_access_key_id AWS_SECRET_ACCESS_KEY=aws_secret_access_key AWS_S3_BUCKET=aws_s3_bucket RACK_ENV=production

#### Configure Gmail (optional)

    $ heroku config:add GMAIL_ACCOUNT=someone@gmail.com GMAIL_PASSWORD=secret RECIPIENT_EMAIL=someone@example.com

#### Configure Redis (optional)

    $ heroku config:add REDIS_URL=redis_url RESQUE_QUEUE=some_worker_queue RESQUE_WORKER=SomeWorker

#### Run the rake task on Heroku

    $ heroku run rake data:fetch

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
