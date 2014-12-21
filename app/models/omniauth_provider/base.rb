class OmniauthProvider::Base

  attr_reader :omni_data

  # The provider code, it should be same as the provider callback name defined in OmniauthProvider::PROVIDERS.
  # @return [String]
  #   The provider code.
  def pcode
    raise "You should implement 'pcode' method in your omniauth provider."
  end

  # The method to parse the raw omni data received from the omniauth callback.
  # @param omni_raw [Hash]
  #   The raw omni data received from the omniauth callback.
  # @return [Hash]
  #   The parsed omni information, it should be a hash contains the following info:
  #
  #   {
  #     uuid: "user_uuid",
  #     account: "user_account",
  #     email: "user_email"
  #   }
  #
  #   where
  #
  #   :uuid - The user unique id associated with the provider, it will be stored in the uuid col in OmniauthRef.
  #   :account - The user's account name, it will be stored in the account col in OmniauthRef.
  #   :email - (optional) The user's email
  def get_data(omni_raw)
    raise "You should implement 'get_data' method in your omniauth provider."
  end

  # To show the account
  # @param account_str [String]
  #   The account stored in OmniauthRef.
  # @return [String]
  #   The account to display.
  # @note You can override this method in your omniauth provider.
  # @example
  #   def account_display(account_str)
  #     "@#{account_str}"
  #   end
  def account_display(account_str)
    account_str
  end

  # You should not override the following methods unless you know what you are doing...

  # The initializer
  # @param omni_raw [Hash] (see OmniauthProvider::Base.get_data)
  # @param get_omni_ref [Boolean] (see OmniauthProvider::gen)
  def initialize(omni_raw, get_omni_ref = false)
    @omni_data = get_data(omni_raw)
    if get_omni_ref
      @omni_ref = OmniauthRef.where(pid: self.pid, uuid: @omni_data[:uuid]).take
    else
      @omni_ref = nil
    end
  end

  # The provider id, it will be stored in the OmniauthRef provider_id column.
  def pid
    OmniauthProvider::PROVIDERS[pcode][:pid]
  end

  # The provider display
  def provider_display
    self.pcode.capitalize
  end

  # Find the user associated with current omniauth ref.
  def find_user
    if @omni_ref
      { user: @omni_ref.user, ref: @omni_ref }
    else
      { user: nil, ref: nil }
    end
  end

  # Create the user associated with current omniauth ref.
  def create_user(given_email = nil)
    email = @omni_data[:email] || given_email
    unless @omni_ref
      @omni_ref = OmniauthRef.new(pid: self.pid,
                                  uuid: @omni_data[:uuid],
                                  account: @omni_data[:account])
    end
    if email
      if @omni_data[:email]
        # if email is from omniauth, try to find the user has this email and bind with it first
        if user = User.where(email: email).take
          bound_user = bind_user(user)
          return {
            behavior: :binding,
            status: (bound_user.persisted? ? :succ : :failed),
            user: bound_user,
            email: email,
            ref: @omni_ref
          }
        end
      end
      created_user = @omni_ref.create_omni_user(email)
      return {
        behavior: :create,
        status: (created_user.persisted? ? :succ : :failed),
        user: created_user,
        email: email,
        ref: @omni_ref
      }
    else
      # has no email from omniauth data
      @omni_ref.bind_token = RandomToken.gen(64)
      ref_created = @omni_ref.save
      return {
        behavior: :no_email,
        status: (ref_created ? :succ : :failed),
        user: nil,
        email: nil,
        ref: (ref_created ? @omni_ref : nil)
      }
    end
  end

  # Bind the current omniauth ref to the given user.
  def bind_user(user)
    existing_user = find_user
    return existing_user if existing_user
    if @omni_ref
      @omni_ref.update_attributes(user_id: user.id,
                                  bind_token: nil)
    else
      @omni_ref = OmniauthRef.create(pid: self.pid,
                                     uuid: @omni_data[:uuid],
                                     user_id: user.id,
                                     account: @omni_data[:account],
                                     bind_token: nil)
    end
    return @omni_ref.persisted? ? user : nil
  end

  # Unbind the current omniauth ref from the given user.
  def unbind_user(user)
    omni_ref = OmniauthRef.where(pid: self.pid,
                                 uuid: @omni_data[:uuid],
                                 user_id: user.id).take
    return false unless omni_ref
    omni_ref.destroy
  end
end
