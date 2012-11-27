class Group < ActiveRecord::Base
  attr_accessible :name, :yammer_group_id

  has_many :invitations, as: :invitee

  validates :yammer_group_id, :name, presence: true

  def invite(sender, object)
    GroupPrivateMessenger.new(
      recipient: self,
      sender: sender,
      message_object: object
    ).invitation.deliver
  end

  def remind(sender, object)
    GroupPrivateMessenger.new(
      recipient: self,
      sender: sender,
      message_object: object
    ).reminder.deliver
  end

  def voted_for_event?(_)
    false
  end

  def yammer_user?
   false
  end

  def yammer_user_id
    nil
  end
end
