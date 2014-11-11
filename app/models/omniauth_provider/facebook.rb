class OmniauthProvider::Facebook < OmniauthProvider::Base
  def pcode
    :facebook
  end

  def get_data(omni_raw)
    email = omni_raw[:extra][:raw_info][:email] rescue nil
    account = email || omni_raw[:info][:name] rescue ""
    {
      pid: self.pid,
      pcode: self.pcode,
      uuid: omni_raw[:uid],
      email: email,
      account: account
    }
  end
end
