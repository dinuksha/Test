require "test_helper"

class DowntimeTest < ActiveSupport::TestCase
  context "validations" do
    should "validate presence of start time" do
      downtime = FactoryGirl.build(:downtime, start_time: nil)

      refute downtime.valid?
      assert_includes downtime.errors[:start_time], "can't be blank"
    end

    should "validate presence of end time" do
      downtime = FactoryGirl.build(:downtime, end_time: nil)

      refute downtime.valid?
      assert_includes downtime.errors[:end_time], "can't be blank"
    end

    should "validate end time is in future" do
      downtime = FactoryGirl.build(:downtime, end_time: 1.day.ago)

      refute downtime.valid?
      assert_includes downtime.errors[:end_time], 'must be in the future'
    end

    should "validate start time is earlier than end time" do
      downtime = FactoryGirl.build(:downtime, start_time: 2.days.from_now, end_time: 1.day.from_now)

      refute downtime.valid?
      assert_includes downtime.errors[:start_time], "can't be later than end time"
    end

    should "validate datetime fields only on create" do
      downtime = FactoryGirl.create(:downtime)
      downtime.assign_attributes(start_time: 2.days.from_now, end_time: 1.day.from_now)

      assert downtime.valid?
    end
  end

  context "callbacks" do
    should "generate a message before validation if no message is given" do
      downtime = FactoryGirl.build(:downtime, message: nil, start_time: DateTime.new(Time.zone.now.year + 1, 10, 10, 15), end_time: DateTime.new(Time.zone.now.year + 1, 10, 11, 18))

      assert downtime.valid?
      assert_equal "This service will be unavailable between 3:00pm on 10 October and 6:00pm on 11 October", downtime.message

      downtime = FactoryGirl.build(:downtime, message: '  ', start_time: DateTime.new(Time.zone.now.year + 1, 10, 10, 15), end_time: DateTime.new(Time.zone.now.year + 1, 10, 11, 18))

      assert downtime.valid?
      assert_equal "This service will be unavailable between 3:00pm on 10 October and 6:00pm on 11 October", downtime.message
    end
  end
end
