# Sends SMS notifications. Development: logs only. Production: placeholder for
# Africastalking or similar provider.
class SmsService
  class << self
    # @param phone [String] E.164-style number
    # @param message [String]
    # @return [true] on success (or stub success)
    def send_single(phone, message)
      return false if phone.blank?

      normalized = phone.to_s.strip
      return false if normalized.blank?

      if Rails.env.development?
        Rails.logger.info "[SmsService] Would send SMS to #{normalized}: #{message.truncate(80)}"
        true
      else
        # Production: plug in Africastalking or other provider here.
        # Example: Africastalking::Sms.send(to: normalized, message: message)
        Rails.logger.info "[SmsService] Production stub: would send SMS to #{normalized}"
        true
      end
    end

    # Send absence alert to all parents of the student who have a phone number.
    # @param student [Student]
    # @param date [Date]
    # @return [Integer] number of messages sent (or stubbed)
    def send_absence_alert(student, date)
      return 0 unless student.present? && date.present?

      student_name = student.full_name
      message = "Learnexis: #{student_name} was marked absent on #{date.strftime('%d %b %Y')}. Please contact the school if you have questions."

      sent = 0
      student.parents.each do |parent|
        next if parent.phone_number.blank?

        if send_single(parent.phone_number, message)
          sent += 1
        end
      end
      sent
    end
  end
end
