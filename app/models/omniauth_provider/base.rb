class OmniauthProvider::Base
  def pid
    OmniauthProvider::PROVIDERS[pcode][:pid]
  end

  def find_user(omni_data)
    omni_ref = OmniauthRef.where(pid: self.pid, uuid: omni_data[:uuid]).first
    return omni_ref ?  omni_ref.user : nil
  end

  def create_user(omni_data, given_email = nil)
    email = omni_data[:email] || given_email
    return false unless email
    user = nil
    ActiveRecord::Base.transaction do
      omni_ref = OmniauthRef.new(pid: self.pid,
                                 uuid: omni_data[:uuid],
                                 account: omni_data[:account])
      password = RandomToken.gen(64)
      user = omni_ref.create_user(email: omni_data[:email],
                                  password: password,
                                  password_confirmation: password)
      omni_ref.save
    end
    user
  end

  def bind_user(omni_data, user)
    existing_user = find_user(omni_data)
    return existing_user if existing_user
    omni_ref = OmniauthRef.create(pid: self.pid,
                                  uuid: omni_data[:uuid],
                                  user_id: user.id,
                                  account: omni_data[:account])
    return omni_ref.persisted? ? user : nil
  end

  def unbind_user(omni_data, user)
    omni_ref = OmniauthRef.where(pid: self.pid,
                                 uuid: omni_data[:uuid],
                                 user_id: user.id).first
    return false unless omni_ref
    omni_ref.destroy
  end

  # NOTE: You can override this method in your omniauth provider,
  #       take twitter for example:
  #
  #       def account_display(account_str)
  #         "@#{account_str}"
  #       end
  #
  def account_display(account_str)
    account_str
  end

  def provider_display
    self.pcode.capitalize
  end

  def pcode
    raise "You should implement 'pcode' method in your omniauth provider."
  end

  def get_data(omni_raw)
    raise "You should implement 'get_data' method in your omniauth provider."
  end
end
