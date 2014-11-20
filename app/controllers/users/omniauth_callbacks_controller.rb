class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  OmniauthProvider.get_supported_providers.each do |provider|
    define_method(provider) do
      check_and_redirect_with(provider, env["omniauth.auth"])
    end
  end

  private

  def check_and_redirect_with(pcode, omni_raw)
    provider = OmniauthProvider.gen(pcode, omni_raw, true)
    unless provider.omni_data
      # NOTE: handle the invalid omni raw format
      flash[:notice] = "Fail to bind with #{provider.provider_display} account."
      raise :omni_data_failed
    end
    if current_user.present?
      # bind omniauth data with existing user
      if user = provider.bind_user(current_user)
        if user == current_user
          flash[:notice] = "Bind the #{provider.provider_display} account successfully."
        else
          flash[:notice] = "This #{provider.provider_display} account is already bound with other account."
        end
        redirect_to root_path and return
      else
        # NOTE: cannot create the omniauth ref
        flash[:notice] = "Fail to bind the #{provider.provider_display} account. Please try again."
        raise :binding_failed
      end
    else
      user = provider.find_user
      unless user
        result = provider.create_user
        case result[:behavior]
          when :no_email
            if result[:status] == :succ
              flash[:notice] = "You need provide the email before you continue."
              redirect_to new_users_omniauth_mail_path(t: result[:ref].bind_token) and return
            else
              flash[:notice] = "Fail to bind the #{provider.provider_display} account. Please try again."
              raise :no_email_failed
            end
          when :create
            if result[:status] == :succ
              user = result[:user]
            else
              flash[:notice] = "Fail to create the #{provider.provider_display} account. Please try again."
              raise :create_failed
            end
          when :binding
            if result[:status] == :succ
              user = result[:user]
            else
              flash[:notice] = "Fail to bind the #{provider.provider_display} account. Please try again."
              raise :binding_failed
            end
        end
      end
      raise :failed unless user.persisted?
      sign_in_and_redirect user, :event => :authentication, :notice => "Signed in successfully."
    end
  rescue StandardError => e
    redirect_to new_user_registration_path
  end
end
