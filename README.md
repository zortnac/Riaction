## Overview ##

riaction provides both a ruby wrapper for IActionable's restful API and an "acts-as" style interface for a Rails application's ActiveRecord models to associate them with IActionable profiles and have them drive the logging of game events.

## API Wrapper ##

The wrapper for IActionable's API is used internally by the rest of the gem, but also may be used directly if desired.  IActionable's API is restful, and this wrapper takes each resource and HTTP verb of that API and wraps them as a method that takes arguments that match to the resource and query or body parameters.  Before the wrapper can be instantiated or used it must be pre-initialized with your IActionable credentials and version number (IActionable supports older versions but recommends staying up to date):

    IActionable::Api.init_settings( :app_key => "12345",
                                    :api_key => "abcde",
                                    :version => 3 )
    @api = IActionable::Api.new

IActionable's API speaks in JSON, and here those responses are wrapped in simple objects where nesting and variable names are determined by [IActionable's documentation](http://www.http://iactionable.com/api/).  For example, here the wrapper is making a call to load a profile summary:

    profile_summary = @api.get_profile_summary("user", "username", "zortnac", 10)
    profile_summary.display_name # => "Chris Eberz"
    profile_summary.identifiers.first # => instance of IActionable::Objects::Identifier
    profile_summary.identifiers.first.id_type # => "username"
    profile_summary.identifiers.first.id # => "zortnac"
  
## Using riaction In Rails ##

While the API wrapper in riaction can be used directly (and I ought just pull it out as a separate gem), the rest of riaction consists of an "acts-as" style interface for your application's ActiveRecord models that leverages the API wrapper to associate your models with IActionable profiles and to have IActionable event logging be driven by your models' CRUD actions.  riaction relies on Resque for tasking all of the requests made to IActionable's service.

### Initializing the API Wrapper ###

Just as above, before the wrapper can be used (either directly or by the riaction interface) it needs to be initialized with your IActionable credentials.  This can be done in a small rails initializer:

    I_ACTIONABLE_CREDS = (YAML.load_file("#{::Rails.root.to_s}/config/i_actionable.yml")[::Rails.env]).symbolize_keys!
    IAction::Api.init_settings(I_ACTIONABLE_CREDS)

### Declaring A Model As A Profile ###

Models in your application may declare themselves as profiles that exist on IActionable.

    class User < ActiveRecord::Base
      riaction :profile, :type => :player, :username => :nickname, :custom => :id
    end
    
    # == Schema Information
    #
    # Table name: users
    #
    #  id                           :integer(4)
    #  nickname                     :string(255)
  
Here, the class User declares itself as a profile of type "player", identifiable by two of IActionable's supported ID types, username and custom, the values of which are the fields (or any symbol that an instance of the class responds to) nickname and id, respectively.  When a class declares itself as an riaction profile, an after_create callback will be added to register that model on IActionable as a profile as the type, and with the identifiers, described in the class.

#### Profile Instance Methods ####

Classes that declare themselves as IActionable profiles are given instance methods that tie in to the IActionable API, as many uses of the API take a profile as an argument.

    @api.get_profile_summary("player", "username", "zortnac", 10)
    # is equivalent to the following...
    @user_instance.riaction_profile_summary(10)
    
    @api.get_profile_challenges("player", "username", "zortnac", :completed)
    # is equivalent to the following...
    @user_instance.riaction_profile_challenges(:completed)
    
    @api.add_profile_identifier("player", "username", "zortnac", "custom", 42)
    # is equivalent to the following...
    @user_instance.riaction_update_profile(:custom)

### Declaring Events ###

Models in your application may declare any number of events that they log through IActionable.  For each event that is declared the important elements are:

1. The event's name (or key)
2. The type of trigger that causes the event to be logged
3. The profile under which the event is logged
4. Any optional parameters (key-value pairs) that you want to pass

` `

    class Comment
      belongs_to :user
      belongs_to :post
      
      riaction :event, :name => :make_a_comment, :trigger => :create, :profile => :user, :params => {:post => :post_id}
    end
    
    # == Schema Information
    #
    # Table name: comments
    #
    #  id                           :integer(4)
    #  user_id                      :integer(4)
    #  post_id                      :integer(4)

Here, the name of the event is `make_a_comment`.  The trigger for the event, in this case, is `:create`, which will add an after_create callback to log the event to the API.  

_Note: If the trigger is one of :create, :update, or :destroy, then the appropriate ActiveRecord callback will log the event.  If the trigger is anything else, then an instance method is provided to log the event by hand.  For example, an argument of `:trigger => :foo` will provide an instance method `trigger_foo!`_

The profile that this event will be logged under can be any object whose class declares itself as a profile.  Here, the profile is the object returned by the ActiveRecord association `:user`, and we assume is an instance of the User class from above.  Lastly, the optional params passed along with the event is the key-value pair `{:post => :post_id}`, where `:post_id` is an ActiveRecord table column.

Putting this all together, whenever an instance of the Comment class is created, an event is logged for which the equivalent call to the API might look like this:

    @api.log_event("player", "username", "zortnac", "make_a_comment", {:post => 33})

_Note: If a class both declares itself as a profile and declares one or more events, and wants to refer to itself as the profile for any of those events, use `:profile => :self`_

## IActionable ##

[Visit their website!](http://www.iactionable.com)

## Author ##

Christopher Eberz; chris@chriseberz.com; @zortnac