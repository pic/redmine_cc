require File.join(File.dirname(__FILE__), '..', 'test_helper')
require 'mocha'

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
    set_custom_value
    ris = Issue.find(@is.id)
    rcv = ris.custom_values.select {|cv| 'Cc' == cv.custom_field.name}.first
    assert_equal 'rhill', rcv.value
  end 

  test 'it extracts recipients' do
    o = CcJournalObserver.instance
    users, emails = o.extract_rcpts('rhill p@example.org, doesnotexist admin')
    assert_equal ['rhill@somenet.foo', 'admin@somenet.foo'], users
    assert_equal ['p@example.org'], emails
  end

  test 'it delivers emails' do
    set_custom_value
    CcMailer.expects(:deliver_cc_issue_edit)

    # without notes, journal skips saving
    @is.init_journal(User.find_by_login('admin'), 'notes')
    @is.subject = 'changed'
    assert @is.save
  end

  test 'it does not deliver email if already sent by standard notification' do
    set_custom_value
    Watcher.create(:watchable => @is, :user => User.find_by_login('rhill'))
    CcMailer.expects(:deliver_cc_issue_edit).never

    # without notes, journal skips saving
    @is.init_journal(User.find_by_login('admin'), 'notes')
    @is.subject = 'changed'
    assert @is.save
  end
  
  def set_custom_value
    @is = issues(:issues_002)
    @cv = CustomValue.create(:value => 'rhill', :customized => @is, :custom_field => @cccf)
  end

end
