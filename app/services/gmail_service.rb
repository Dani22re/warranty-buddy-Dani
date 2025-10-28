require 'google/apis/gmail_v1'

class GmailService
  Gmail = Google::Apis::GmailV1

  def initialize(access_token)
    @service = Gmail::GmailService.new
    @service.authorization = access_token
  end

  def list_messages(user_id = 'me', query = '')
    result = @service.list_user_messages(user_id, q: query)
    result.messages || []
  end

  def get_message(message_id, user_id = 'me')
    @service.get_user_message(user_id, message_id)
  end
end
