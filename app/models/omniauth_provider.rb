class OmniauthProvider
  # To add a new provider, you should:
  #
  # 1. Add the provider information in the PROVIDERS.
  # 2. Add a new OmniauthProvider::Base -based class for your provider,
  #    please see OmniauthProvider::Facebook for example.
  #

  # Define the supported providers
  # @note
  #   key: the provider callback name, it is defined by the omniauth provider gem.
  #   value - klass: the corresponding OmniauthProvider::Base -based class for your provider.
  #   value - pid: the provider id, it will be stored in OmniRef.
  #   value - skip: (option) true to skip this provider, i.e., it is not shown in
  #                 get_supported_providers.
  PROVIDERS = {
    facebook: {
      klass: OmniauthProvider::Facebook,
      pid: 1
    },
    google_plus: {
      klass: OmniauthProvider::Facebook,
      pid: 2,
      skip: true
    }
  }

  class << self
    # To generate omniauth provider object
    #
    # @param pcode [Symbol]
    #   The provider code, it should be same as the provider callback name.
    # @param omni_raw [Hash]
    #   The raw omni data received from the omniauth callback.
    # @param get_omni_ref [Bool]
    #   True to get omniauth ref from database by default, otherwise, false.
    # @return [OmniauthProvider::Base]
    #   The corresponding omniauth provider object
    def gen(pcode, omni_raw, get_omni_ref = false)
      provider = PROVIDERS[pcode]
      raise "Invalid provider #{provider}" unless provider
      provider[:klass].new(omni_raw, get_omni_ref)
    end

    # To get the supported provider list
    #
    # @return [Array<Symbol>]
    def get_supported_providers
      PROVIDERS.keep_if { |pcode, value| value[:skip] != true }.keys
    end
  end
end
