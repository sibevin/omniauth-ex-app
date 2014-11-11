class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  PROVIDERS = [:facebook]

  PROVIDERS.each do |provider|
    define_method(provider) do
      check_and_redirect_with(provider, env["omniauth.auth"])
    end
  end

  private

  def check_and_redirect_with(pcode, omni_raw)
    provider = OmniauthProvider.gen(pcode)
    omni_data = provider.get_data(omni_raw)
    unless omni_data
      # NOTE: handle the invalid omni raw format
      flash[:notice] = "Fail to bind with #{provider.provider_display} account."
      redirect_to new_user_registration_path
    end
    if current_user.present?
      # bind omniauth data with existing user
      if user = provider.bind_user(omni_data, current_user)
        if user == current_user
          # NOTE: success
          flash[:notice] = "Bind the #{provider.provider_display} account successfully."
        else
          # NOTE: already binded
          flash[:notice] = "This #{provider.provider_display} account is already bound with other account."
        end
        redirect_to root_path
      else
        # NOTE: cannot create the omniauth ref
        flash[:notice] = "Fail to bind the #{provider.provider_display} account. Please try again."
        redirect_to new_user_registration_path
      end
    else
      user = provider.find_user(omni_data)
      user = provider.create_user(omni_data) unless user
      if user == false
        # NOTE: cannot get the email from omniauth provider
        flash[:notice] = "You need provide the email before you continue."
        # TODO: should redirect to email input page
        redirect_to new_user_registration_path
      else
        if user.persisted?
          sign_in_and_redirect user, :event => :authentication, :notice => "Signed in successfully."
        else
          # TODO: cannot create the user
          flash[:notice] = "Fail to create an account. Please try again."
          redirect_to new_user_registration_path
        end
      end
    end
  end
end
