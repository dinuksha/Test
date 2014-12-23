class Downtime
  include Mongoid::Document
  include Mongoid::Timestamps

  field :message, type: String
  field :start_time, type: DateTime
  field :end_time, type: DateTime

  belongs_to :artefact

  validates_presence_of :message, :start_time, :end_time, :artefact
  validate :time_fields, on: :create

  before_validation :generate_message, if: ->{ message.nil? || message.strip.empty? }

  def self.for(artefact)
    where(artefact_id: artefact.id).first
  end

  def publicise?
    Time.zone.now.between?(start_time.to_date - 1, end_time) # starting at midnight a day before start time
  end

  private

  def generate_message
    datetime_format = '%l:%M%P on %e %B'
    write_attribute(:message, "This service will be unavailable between #{start_time.strftime(datetime_format).strip} and #{end_time.strftime(datetime_format).strip}")
  end

  def time_fields
    errors.add(:end_time, "must be in the future") if end_time && ! end_time.future?
    errors.add(:start_time, "can't be later than end time") if start_time && end_time && start_time > end_time
  end
end
