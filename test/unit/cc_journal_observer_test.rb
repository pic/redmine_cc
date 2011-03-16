require File.join(File.dirname(__FILE__), '..', 'test_helper')

class CcJournalObserverTest < ActiveSupport::TestCase

  fixtures :issues, :custom_fields, :custom_values, :users

  def setup
    @cccf = CustomField.new :name => 'Cc', :is_for_all => true, :field_format => 'text'
    @cccf.save!
  end

  test 'custom values' do
    is = issues(:issues_001) 
    #puts "--> #{is.custom_values.map(&:value).join(', ')}"
  end

  test 'set and retrieve cc custom value' do
     is = issues(:issues_002)
     cv = CustomValue.create!(:value => 'admin', :customized => is, :custom_field => @cccf)
     ris = Issue.find(is.id)
     rcv = ris.custom_values.select {|cv| 'Cc' == cv.custom_field.name}.first
     assert_equal 'admin', rcv.value 
  end 

  test 'it extracts recipients' do
    o = CcJournalObserver.instance
    users, emails = o.extract_rcpts('rhill p@example.org, doesnotexist admin')
    assert_equal ['rhill@somenet.foo', 'admin@somenet.foo'], users
    assert_equal ['p@example.org'], emails
  end

end
