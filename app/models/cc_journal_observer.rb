class CcJournalObserver <  ActiveRecord::Observer
  observe :journal

  @@field_name = 'Cc'
  cattr_accessor :field_name

  def after_create(journal)
    journalized = journal.journalized
    cv = journalized.custom_values.select {|c_v| CcJournalObserver.field_name == c_v.custom_field.name}.first
    if cv and !cv.value.blank?
      #journalized.logger.info("would send to #{cv.value}")
      users, emails = extract_rcpts(cv.value)
      cc_recipients = (users + emails).uniq
      would_send_notifications = false
      if Setting.notified_events.include?('issue_updated') ||
         (Setting.notified_events.include?('issue_note_added') && journal.notes.present?) ||
         (Setting.notified_events.include?('issue_status_updated') && journal.new_status.present?) ||
         (Setting.notified_events.include?('issue_priority_updated') && journal.new_value_for('priority_id').present?)
        would_send_notifications = true
      end
      if would_send_notifications
        standard_recipients = (journalized.recipients + journalized.watcher_recipients).uniq
        cc_recipients -= standard_recipients
      end
      CcMailer.deliver_cc_issue_edit(journal, cc_recipients) unless cc_recipients.empty?
      # if you want that users were "sticky", then use watchers instead
      cv.update_attribute(:value, emails.join(', '))
    end
  end

  def extract_rcpts(v)
    ps = v.split(/\s*,\s*|\s+/)
    users, emails = [], []
    all = false
    ps.each do |p|
      if 'all' == p.downcase
        all = true
      elsif p =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/
        emails << p
      else
        users << p
      end
    end
    if all
      users = User.active.map(&:mail)
    else
      users.map! do |u|
        u = User.find_by_login(u)
        u and u.mail
      end
    end
    [users.compact, emails]
  end

  def reload_observer
    observed_classes.each do |klass| 
      klass.name.constantize.add_observer(self)
    end
  end

end

