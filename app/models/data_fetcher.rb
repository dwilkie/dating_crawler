class DataFetcher
  require 'phone_number_miner/angkor_thom'
  require 'aws-sdk'

  DEFAULT_ANGKOR_THOM_PAGE_INDEX_PATH = "dating_crawler/angkor_thom_page_indexes.json"
  DEFAULT_DATA_DIRECTORY = "dating_crawler/data"

  attr_accessor :aws_access_key_id, :aws_secret_access_key,
                :aws_s3_bucket, :angkor_thom_page_index_path,
                :data_directory, :resque_queue, :resque_worker,
                :redis_url

  def initialize(options = {})
    self.aws_access_key_id = options[:aws_access_key_id] || ENV["AWS_ACCESS_KEY_ID"]
    self.aws_secret_access_key = options[:aws_secret_access_key] || ENV["AWS_SECRET_ACCESS_KEY"]
    self.aws_s3_bucket = options[:aws_s3_bucket] || ENV["AWS_S3_BUCKET"]
    self.data_directory = options[:data_directory] ||= DEFAULT_DATA_DIRECTORY
    self.angkor_thom_page_index_path = options[:angkor_thom_page_index_path] || DEFAULT_ANGKOR_THOM_PAGE_INDEX_PATH
    self.resque_queue = options[:resque_queue] || ENV["RESQUE_QUEUE"]
    self.resque_worker = options[:resque_worker] || ENV["RESQUE_WORKER"]
    self.redis_url = options[:redis_url] || ENV["REDIS_URL"]
    Resque.redis = Redis.new(:url => redis_url) if resque_configured?
  end

  def fetch!
    suggested_filename, results = fetch_angkor_thom!
    results_file(suggested_filename).write(results.to_json)
    Resque::Job.create(resque_queue, resque_worker, results) if resque_configured?
  end

  private

  def fetch_angkor_thom!
    results = angkor_thom.mine!(angkor_thom_page_indexes["angkor_thom"], angkor_thom_page_indexes["dara"])
    latest_angkor_thom_page = angkor_thom.latest_angkor_thom_page
    latest_dara_page = angkor_thom.latest_dara_page
    new_page_indexes = {
      "angkor_thom" => latest_angkor_thom_page,
      "dara" => latest_dara_page
    }.to_json
    angkor_thom_page_index_file.write(new_page_indexes)
    ["angkor_thom_#{latest_angkor_thom_page}-dara_#{latest_dara_page}", results]
  end

  def timestamp
    Time.now.strftime("%Y-%m-%d-%H-%M")
  end

  def angkor_thom_page_indexes
    @angkor_thom_page_indexes ||= angkor_thom_page_index_file.exists? ? JSON.parse(angkor_thom_page_index_file.read) : {}
  end

  def angkor_thom
    @angkor_thom ||= PhoneNumberMiner::AngkorThom.new
  end

  def resque_configured?
    resque_queue && resque_worker && redis_url
  end

  def s3
    @s3 ||= AWS::S3.new(
      :access_key_id => aws_access_key_id,
      :secret_access_key => aws_secret_access_key
    )
  end

  def bucket
    @bucket ||= s3.buckets[aws_s3_bucket]
  end

  def results_file(filename)
    bucket.objects["#{data_directory}/#{timestamp}_#{filename}.json"]
  end

  def angkor_thom_page_index_file
    @angkor_thom_page_index_file ||= bucket.objects[angkor_thom_page_index_path]
  end
end
