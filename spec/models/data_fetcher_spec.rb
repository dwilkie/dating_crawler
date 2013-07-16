require 'spec_helper'
require 'timecop'
require './app/models/data_fetcher'

describe DataFetcher do

  describe "#fetch!" do
    include WebMockHelpers

    let(:sample) {
      {
        :angkor_thom => {
          :original_page_indexes => { "angkor_thom" => 300, "dara" => 200 },
          :new_page_indexes => { "angkor_thom" => 327, "dara" => 206 },
          :data => {
            "85512345678" => {
              "gender" => "m",
              "name" => "dave",
              "age" => "21",
              "location" => "Siem Reap"
            },
            "85512876543" => {
              "gender" => "f",
              "name" => "mara",
              "age" => "20",
              "location" => "Phnom Penh"
            }
          }
        }
      }
    }

    let(:assertions) {
      {
        :angkor_thom => {
          :default_page_indexes_path => "dating_crawler/angkor_thom_page_indexes.json"
        },
        :default_data_path => "dating_crawler/data"
      }
    }

    let(:angkor_thom) { double(PhoneNumberMiner::AngkorThom) }

    def with_vcr(options = {}, &block)
      aws_s3_cassette = options.delete(:aws_s3_cassette) || "aws_s3"
      options[:angkor_thom] ||= {}

      options[:angkor_thom][:original_page_indexes] = options[:angkor_thom][:original_page_indexes] || sample[:angkor_thom][:original_page_indexes]
      options[:angkor_thom][:new_page_indexes] = options[:angkor_thom][:new_page_indexes] || sample[:angkor_thom][:new_page_indexes]

      options[:angkor_thom][:page_indexes_url] ||= asserted_url(assertions[:angkor_thom][:default_page_indexes_path], options)
      options[:angkor_thom][:data_url] ||= asserted_url(asserted_angkor_thom_data_path(options), options)

      options[:angkor_thom][:original_page_indexes] = options[:angkor_thom][:original_page_indexes].to_json
      options[:angkor_thom][:new_page_indexes] = options[:angkor_thom][:new_page_indexes].to_json
      options[:angkor_thom][:data] = (options[:angkor_thom][:data] || sample[:angkor_thom][:data]).to_json

      VCR.use_cassette(aws_s3_cassette, :erb => options) do
        yield
      end
    end

    def asserted_url(path, options = {})
      options = options.dup
      aws_s3_bucket = options.delete(:aws_s3_bucket) || ENV["AWS_S3_BUCKET"]
      "https://#{aws_s3_bucket}.s3.amazonaws.com/#{path}"
    end

    def asserted_angkor_thom_data_path(options = {})
      options[:angkor_thom] ||= {}
      new_page_indexes = options[:angkor_thom][:new_page_indexes] || sample[:angkor_thom][:new_page_indexes]
      latest_angkor_thom_page = new_page_indexes["angkor_thom"]
      latest_dara_page = new_page_indexes["dara"]
      timestamp = Time.now.strftime("%Y-%m-%d-%H-%M")
      "#{assertions[:default_data_path]}/#{timestamp}_angkor_thom_#{latest_angkor_thom_page}-dara_#{latest_dara_page}.json"
    end

    before do
      Timecop.freeze(Time.now)
      PhoneNumberMiner::AngkorThom.stub(:new).and_return(angkor_thom)
      angkor_thom.stub(:mine!).and_return(sample[:angkor_thom][:data])
      angkor_thom.stub(:latest_angkor_thom_page).and_return(sample[:angkor_thom][:new_page_indexes]["angkor_thom"])
      angkor_thom.stub(:latest_dara_page).and_return(sample[:angkor_thom][:new_page_indexes]["dara"])
    end

    after do
      Timecop.return
    end

    it "should upload the results and angkor thom page indexes to the configured S3 bucket" do
      with_vcr { subject.fetch! }

      request(2, :body).should == sample[:angkor_thom][:new_page_indexes]
      request(2, :url).should == asserted_url(assertions[:angkor_thom][:default_page_indexes_path])
      request(2, :method).should == :put

      request(3, :body).should == sample[:angkor_thom][:data]
      request(3, :url).should == asserted_url(asserted_angkor_thom_data_path)
      request(3, :method).should == :put
    end

    context "given there is a file containing angkor thom page indexes on the configured S3 bucket" do
      it "should try to fetch data from phone_number_miner/angkor_thom using the stored page indexes" do
        angkor_thom.should_receive(:mine!).with(
          sample[:angkor_thom][:original_page_indexes]["angkor_thom"], sample[:angkor_thom][:original_page_indexes]["dara"]
        )
        with_vcr { subject.fetch! }
      end
    end

    context "given there is no file containing angkor thom page indexes on the configured S3 bucket" do
      it "should try to fetch data from phone_number_miner/angkor_thom without using page indexes" do
        angkor_thom.should_receive(:mine!).with(nil, nil)
        with_vcr(:aws_s3_cassette => "aws_s3_no_object") { subject.fetch! }
      end
    end
  end
end
