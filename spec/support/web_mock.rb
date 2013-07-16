require 'webmock/rspec'
WebMock.disable_net_connect!

# From: https://gist.github.com/2596158
# Thankyou Bartosz Blimke!
# https://twitter.com/bartoszblimke/status/198391214247124993

module LastRequest
  def clear_requests!
    @requests = nil
  end

  def requests
    @requests ||= []
  end

  def last_request=(request_signature)
    requests << request_signature
    request_signature
  end
end

module WebMockHelpers
  require 'json'
  require 'uri'

  private

  def requests
    requests = WebMock.requests
  end

  def first_request(attribute = nil)
    request(:first, attribute)
  end

  def last_request(attribute = nil)
    request(:last, attribute)
  end

  def request(position, attribute = nil)
    request = position.is_a?(Integer) ? WebMock.requests.send(:[], position) : WebMock.requests.send(position)

    case attribute
    when :body
      JSON.parse(request.body)
    when :url
     URI.parse(request.uri.to_s).to_s
    when :method
      request.method
    else
      request
    end
  end
end

WebMock.extend(LastRequest)
WebMock.after_request do |request_signature, response|
  WebMock.last_request = request_signature
end

RSpec.configure do |config|
  config.before do
    WebMock.clear_requests!
  end
end
