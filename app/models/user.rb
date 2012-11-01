class User < ActiveRecord::Base
  serialize :extra, JSON
  attr_accessible :access_token, :encrypted_access_token, :name,
    :yammer_user_id, :yammer_staging
  attr_encrypted :access_token, key: ENV['ACCESS_TOKEN_ENCRYPTION_KEY']

  has_many :events
  has_many :votes, as: :voter
  has_many :invitations, as: :invitee

  validates :email, email: true
  validates :encrypted_access_token, presence: true
  validates :name, presence: true
  validates :yammer_user_id, presence: true

  def self.create_with_auth(auth)
    create(yammer_user_id: auth[:yammer_user_id]).tap do |user|
      user.access_token = auth[:access_token]
      user.yammer_staging = auth[:yammer_staging]
      user.fetch_yammer_user_data
      user.save!
    end
  end

  def self.find_or_create_with_auth(auth)
    user = find_by_yammer_user_id(auth[:yammer_user_id]) ||
     create_with_auth(auth)

    user.tap do |user|
      user.access_token = auth[:access_token]
      user.associate_guest_invitations
      user.save!
    end
  end

  def able_to_edit?(event)
    event.owner == self
  end

  def associate_guest_invitations
    guest = Guest.find_by_email(email)

    if guest
      associate_each_invitation_with(guest)
      guest.destroy
    end
  end

  def create_yammer_activity(action, event)
    ActivityCreator.new(self, action, event).post
  end

  def guest?
    false
  end

  def fetch_yammer_user_data
    response = yammer_user_data
    update_attributes(
      {
        email: parse_email_from_response(response),
        image: response['mugshot_url'],
        name: response['full_name'],
        nickname: response['name'],
        yammer_profile_url: response['web_url'],
        yammer_network_id: response['network_id'],
        extra: response
      },
      { without_protection: true }
    )
  end

  def in_network?(test_user)
    yammer_network_id == test_user.yammer_network_id
  end

  def image
    self[:image] || 'http://' + ENV['HOSTNAME'] + '/assets/no_photo.png'
  end

  def deliver_email_or_private_message(message, sender, object)
    if in_network?(sender)
      PrivateMessenger.new(self, message, sender, object).deliver
    else
      UserMailer.send(message, sender, object).deliver
    end
  end

  def to_s
    name
  end

  def vote_for_suggestion(suggestion)
    votes.find_by_suggestion_id(suggestion.id)
  end

  def voted_for_suggestion?(suggestion)
    vote_for_suggestion(suggestion).present?
  end

  def voted_for_event?(event)
    votes_for_event(event).exists?
  end

  def votes_for_event(event)
    event.votes.where(voter_id: self, voter_type: self.class.name)
  end

  def yammer_user?
    true
  end

  def yammer_endpoint
    if yammer_staging
      'https://www.staging.yammer.com/'
    else
      'https://www.yammer.com/'
    end
  end

  def yammer_group_id
    nil
  end

  def yammer_user_data
    JSON.parse( yammer_user_url )
  end

  private

  def access_token_for_query
    { access_token: access_token }.to_query
  end

  def associate_each_invitation_with(guest)
    guest.invitations.each do |invitation|
      self.invitations << invitation
    end
  end

  def parse_email_from_response(response)
    response['contact']['email_addresses'].
      detect{ |address| address['type'] == 'primary' }['address']
  end

  def yammer_user_url
    RestClient.get yammer_endpoint +
      'api/v1/users/' +
      yammer_user_id.to_s +
      '.json?' +
      access_token_for_query
  end
end
