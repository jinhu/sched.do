class UserPrivateMessenger
  include Rails.application.routes.url_helpers

  def initialize(params)
    @recipient = params[:recipient]
    @sender = params[:sender]
    @message_object = params[:message_object]
  end

  def invitation
    tap do
      @invitation = @message_object
      @event = @invitation.event
      @message_body = invitation_message_body
    end
  end

  def reminder
    tap do
      @invitation = @message_object
      @event = @invitation.event
      @message_body = reminder_message_body
    end
  end

  def deliver
    Yam.post(
      "/messages",
      body: @message_body,
      direct_to_id: @recipient.yammer_user_id,
      og_url: event_url(@event)
    )
  end

  private

  def invitation_message_body
    <<-BODY.strip_heredoc
      #{@event.owner} created the "#{@event.name}" poll and I want your input.

       Please click this link to view the options and vote: #{event_url(@event)}

       *This poll was sent using sched.do. Create your own polls for free at #{root_url}
     BODY
  end

  def reminder_message_body
    <<-BODY.strip_heredoc
      Reminder: Help out #{@event.owner} by voting on "#{@event.name}".

      Please click this link to view the options and vote: #{event_url(@event)}

      *This poll was sent using sched.do. Create your own polls for free at #{root_url}
    BODY
  end
end
