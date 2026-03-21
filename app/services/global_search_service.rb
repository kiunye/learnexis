# frozen_string_literal: true

class GlobalSearchService
  # more_type is a symbol indicating which index page to link to (built in the view)
  ResultGroup = Struct.new(:title, :items, :more_type, keyword_init: true)

  class << self
    def call(user:, query:)
      q = query.to_s.strip
      return empty(q) if q.blank? || q.length < 2

      like = "%#{sanitize_like(q)}%"

      groups = []

      # Students (admin/teacher via StudentPolicy; parents scope to their children)
      students = policy_scope(user, Student)
                 .joins(:user)
                 .where("users.first_name LIKE :q OR users.last_name LIKE :q OR users.email_address LIKE :q OR students.admission_number LIKE :q", q: like)
                 .order("users.first_name ASC, users.last_name ASC")
                 .limit(10)
      groups << ResultGroup.new(title: "Students", items: students, more_type: :students) if students.any?

      # Classrooms
      classrooms = policy_scope(user, Classroom)
                   .where("name LIKE :q OR section LIKE :q OR room_number LIKE :q", q: like)
                   .order(grade_level: :asc, section: :asc, name: :asc)
                   .limit(10)
      groups << ResultGroup.new(title: "Classrooms", items: classrooms, more_type: :classrooms) if classrooms.any?

      # Invoices
      invoices = policy_scope(user, Invoice)
                 .joins(student: :user)
                 .where(
                   "CAST(invoices.id AS TEXT) LIKE :q OR users.first_name LIKE :q OR users.last_name LIKE :q OR students.admission_number LIKE :q",
                   q: like
                 )
                 .order(created_at: :desc)
                 .limit(10)
      groups << ResultGroup.new(title: "Invoices", items: invoices, more_type: :invoices) if invoices.any?

      # Transactions
      transactions = policy_scope(user, Transaction)
                     .joins(student: :user)
                     .where(
                       "transactions.reference LIKE :q OR CAST(transactions.id AS TEXT) LIKE :q OR users.first_name LIKE :q OR users.last_name LIKE :q OR students.admission_number LIKE :q",
                       q: like
                     )
                     .order(transaction_date: :desc, created_at: :desc)
                     .limit(10)
      groups << ResultGroup.new(title: "Transactions", items: transactions, more_type: :transactions) if transactions.any?

      # Events
      events = policy_scope(user, Event)
               .where("title LIKE :q OR description LIKE :q OR location LIKE :q", q: like)
               .order(start_datetime: :asc)
               .limit(10)
      groups << ResultGroup.new(title: "Events", items: events, more_type: :events) if events.any?

      # Notices
      notices = policy_scope(user, Notice)
                .where("title LIKE :q OR content LIKE :q", q: like)
                .order(published_at: :desc)
                .limit(10)
      groups << ResultGroup.new(title: "Notices", items: notices, more_type: :notices) if notices.any?

      empty(q).merge(groups: groups)
    rescue Pundit::NotDefinedError
      empty(q)
    end

    private

    def empty(q)
      { query: q, groups: [] }
    end

    def policy_scope(user, scope)
      Pundit.policy_scope!(user, scope)
    end

    # Escape % and _ for LIKE
    def sanitize_like(str)
      str.gsub("%", "\\%").gsub("_", "\\_")
    end
  end
end

