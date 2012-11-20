
require 'name_logic'
require File.expand_path('./inflection_helper', File.dirname(__FILE__))

class CardMock < String
  def name() to_name end
end

NameLogic.name_attribute= :name
NameLogic.codes= { :content => 1 }
NameLogic.lookup= { 1 => CardMock.new('*content'), }

RSpec.configure do |config|

  #config.include CustomMatchers
  #config.include ControllerMacros, :type=>:controllers
  #config.include AuthenticatedTestHelper, :type=>:controllers
  #config.include(EmailSpec::Helpers)
  #config.include(EmailSpec::Matchers)

  # == Mock Framework
  # If you prefer to mock with mocha, flexmock or RR, uncomment the appropriate symbol:
  # :mocha, :flexmock, :rr

end

