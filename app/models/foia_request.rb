class FoiaRequest < ApplicationRecord
  belongs_to :user
  has_many :documents, dependent: :destroy

  # Status enum
  enum :status, {
    pending: 0,
    in_progress: 1,
    completed: 2,
    cancelled: 3
  }

  # Validations
  validates :request_number, presence: true, uniqueness: true
  validates :requester_name, presence: true
  validates :requester_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true
  validates :received_at, presence: true
  validates :due_on, presence: true
  validates :status, presence: true

  # Callbacks
  before_validation :generate_request_number, on: :create
  before_validation :set_received_at, on: :create
  before_validation :calculate_due_date, if: :received_at_changed?
  after_initialize :set_default_status, if: :new_record?

  # Scopes
  scope :overdue, -> { where('due_on < ? AND status != ?', Time.current, statuses[:completed]) }
  scope :due_soon, -> { where('due_on BETWEEN ? AND ? AND status != ?', Time.current, 2.days.from_now, statuses[:completed]) }
  scope :active, -> { where.not(status: [:completed, :cancelled]) }

  # Instance methods
  def days_until_due
    return 0 if completed? || cancelled?
    business_days_between(Time.current, due_on)
  end

  def overdue?
    due_on < Time.current && !completed? && !cancelled?
  end

  def processing_progress
    return 100 if documents.empty?
    
    completed_count = documents.where(processing_status: :completed).count
    (completed_count.to_f / documents.count * 100).round
  end

  private

  def generate_request_number
    # Format: FOIA-YYYYMMDD-XXXX (e.g., FOIA-20251014-0001)
    date_prefix = Time.current.strftime('%Y%m%d')
    last_request = FoiaRequest.where('request_number LIKE ?', "FOIA-#{date_prefix}-%").order(:request_number).last
    
    if last_request
      last_number = last_request.request_number.split('-').last.to_i
      next_number = (last_number + 1).to_s.rjust(4, '0')
    else
      next_number = '0001'
    end
    
    self.request_number = "FOIA-#{date_prefix}-#{next_number}"
  end

  def set_received_at
    self.received_at ||= Time.current
  end

  def calculate_due_date
    # Calculate 5 business days from received_at
    self.due_on = business_days_from(received_at, 5)
  end

  def set_default_status
    self.status ||= :pending
  end

  def business_days_from(start_date, num_days)
    date = start_date
    days_added = 0
    
    while days_added < num_days
      date += 1.day
      days_added += 1 unless weekend?(date)
    end
    
    date
  end

  def business_days_between(start_date, end_date)
    return 0 if end_date <= start_date
    
    days = 0
    current = start_date.to_date
    
    while current < end_date.to_date
      days += 1 unless weekend?(current)
      current += 1.day
    end
    
    days
  end

  def weekend?(date)
    date.saturday? || date.sunday?
  end
end
