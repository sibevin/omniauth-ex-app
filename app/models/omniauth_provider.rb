class OmniauthProvider
  PROVIDERS = {
    facebook: {
      klass: OmniauthProvider::Facebook,
      pid: 1
    }
  }

  class << self
    def gen(pcode)
      provider = PROVIDERS[pcode]
      raise "Invalid provider #{provider}" unless provider
      provider[:klass].new
    end
  end
end
