require 'resque_spec'

RSpec.configure do |config|
  config.before do
    ResqueSpec.reset!
  end
end
