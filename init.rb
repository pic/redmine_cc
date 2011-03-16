require 'redmine'

require 'cc_journal_observer'

ActiveRecord::Base.observers << CcJournalObserver
config.to_prepare do
  unless config.action_controller.perform_caching
    CcJournalObserver.instance.reload_observer
  end
end

Redmine::Plugin.register :redmine_status_notifications do
  name 'Redmine Carbon Copy'
  description 'This plugin allows to send extemporary notifications'
  version '0.0.1'
  url 'http://github.com/pic/redmine_cc'
  author 'Nicola Piccinini'
  author_url 'mailto:piccinini@gmail.com'
end
