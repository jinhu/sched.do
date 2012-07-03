class EventsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound do |exception|
    flash[:error] = 'Sorry, you are not authorized to view that event.'
    redirect_to root_path
  end

  skip_before_filter :require_yammer_login, only: :show
  before_filter :require_guest_or_yammer_login, only: :show

  def new
    @event = current_user.events.build
    @suggestions = populate_suggestions_for(@event)
  end

  def create
    @event = current_user.events.new(params[:event])
    @event.suggestions = @event.suggestions.select(&:valid?)

    if @event.save
      flash[:success] = "Event successfully created."
      redirect_to @event
    else
      flash[:error] = "Please complete all required fields."
      @suggestions = populate_suggestions_for(@event)
      render :new
    end
  end

  def show
    @event = Event.find(params[:id])
    @suggestions = @event.suggestions
    verify_or_setup_invitation_for_current_user
  end

  def edit
    @event = current_user.events.find(params[:id])
    @invitations = populate_invitations_for(@event)
  end

  def update
    event = current_user.events.find(params[:id])
    create_invitations_for_event(event)
    event.attributes = params[:event]
    event.invitations = event.invitations.select(&:valid?)

    if event.save
      flash[:success] = 'Event successfully updated.'
      redirect_to event
    else
      @event = event
      @invitations = populate_invitations_for(@event)
      flash[:failure] = 'Please check the errors and try again.'
      render :edit
    end
  end

  private

  def create_invitations_for_event(event)
    inviter = Inviter.new(event)
    if params[:event]
      invitations_attributes = params[:event].delete(:invitations_attributes)
      invitations_attributes.values.each do |invitation|
        inviter.invite_from_params(invitation[:yammer_user_id], invitation[:name_or_email])
      end
    end
  end

  def populate_suggestions_for(event)
    if event.suggestions.empty?
      2.times { event.suggestions.build }
    end
    event.suggestions
  end

  def populate_invitations_for(event)
    event.invitations.build
  end

  def verify_or_setup_invitation_for_current_user
    if !@event.user_invited?(current_user)
      Inviter.new(@event).invite(current_user)
      @event.reload
    end
  end
end
