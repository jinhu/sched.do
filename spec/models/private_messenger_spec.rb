require 'spec_helper'

describe UserPrivateMessenger, '#invitation' do
  it 'sends the correct invitation' do
    event_owner = create(:user)
    invitee = create(:user)
    message = :invitation
    event = create(:event, owner: event_owner)
    invitation = build(:invitation, event: event, invitee: invitee)

    UserPrivateMessenger.new(
      recipient: invitee,
      message: message,
      sender: event_owner,
      message_object: invitation
    ).deliver

    FakeYammer.messages_endpoint_hits.should == 1
    FakeYammer.message.should include('vote')
    FakeYammer.message.should include(event_owner.name)
  end
end

describe UserPrivateMessenger, '#reminder' do
  it 'sends the correct reminder' do
    event_owner = create(:user)
    invitee = create(:user)
    message = :reminder
    event = create(:event, owner: event_owner)
    invitation = build(:invitation, event: event, invitee: invitee)

    UserPrivateMessenger.new(
      recipient: invitee,
      message: message,
      sender: event_owner,
      message_object: invitation
    ).deliver

    FakeYammer.messages_endpoint_hits.should == 1
    FakeYammer.message.should include('Reminder')
    FakeYammer.message.should include(event_owner.name)
  end
end

describe GroupPrivateMessenger, '#group_invitation' do
  it 'sends a group invitation' do
    event_owner = create(:user)
    group = create(:group)
    message = :invitation
    event = create(:event, owner: event_owner)
    invitation = build(:invitation, event: event, invitee: group)

    GroupPrivateMessenger.new(
      recipient: group,
      message: message,
      sender: event_owner,
      message_object: invitation
    ).deliver

    FakeYammer.messages_endpoint_hits.should == 1
    FakeYammer.message.should include('I want your input')
    FakeYammer.message.should include(group.name)
  end
end

describe GroupPrivateMessenger, '#group_reminder' do
  it 'sends a group reminder' do
    event_owner = create(:user)
    group = create(:group)
    message = :reminder
    event = create(:event, owner: event_owner)
    invitation = build(:invitation, event: event, invitee: group)

    GroupPrivateMessenger.new(
      recipient: group,
      message: message,
      sender: event_owner,
      message_object: invitation
    ).deliver

    FakeYammer.messages_endpoint_hits.should == 1
    FakeYammer.message.should include('Reminder')
    FakeYammer.message.should include(event_owner.name)
  end
end
