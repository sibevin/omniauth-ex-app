class Users::OmniauthMailController < ApplicationController
  def new
    @token = params[:t]
  end

  def create
    if params[:token] == nil || params[:user][:email] == nil || params[:user][:email_confirmation] == nil
      # NOTE: Invalid request
      redirect_to new_user_registration_path and return
    end
    omni_ref = OmniauthRef.where(bind_token: params[:token]).take
    unless omni_ref
      flash[:notice] = "Invalid binding token."
      redirect_to new_user_registration_path and return
    end
    if params[:user][:email] != params[:user][:email_confirmation]
      flash[:notice] = "This email and email confirmation is not the same."
      redirect_to new_users_mail_path(t: params[:token]) and return
    end
    if user = User.where(email: params[:user][:email]).take
      # NOTE: This email is already used
      flash[:notice] = "This email is already used, please choose another one."
      redirect_to new_users_mail_path(t: params[:token]) and return
    end
    if omni_ref.user
      sign_in_and_redirect omni_ref.user, :event => :authentication, :notice => "Signed in successfully."
    else
      user = omni_ref.create_omni_user(params[:user][:email])
      if user && user.persisted?
        sign_in_and_redirect user, :event => :authentication, :notice => "Signed in successfully."
      else
        flash[:notice] = "Fail to create the #{provider.provider_display} account. Please try again."
        redirect_to new_users_mail_path(t: params[:token])
      end
    end
  end

  def show
    @token = params[:id]
    omni_ref = OmniauthRef.where(bind_token: @token).take
    if user = omni_ref && omni_ref.user
      @email = user.email
    else
      flash[:notice] = "Invalid binding token."
      redirect_to new_user_registration_path and return
    end
  end

  def destroy
    omni_ref = OmniauthRef.where(bind_token: params[:id]).take
    if user = omni_ref && omni_ref.user
      ActiveRecord::Base.transaction do
        omni_ref.destroy!
        user.destroy!
      end
      flash[:notice] = "Your email is reset, please login with FB account again."
      redirect_to new_user_registration_path
    else
      flash[:notice] = "Fail to reset FB information, please try again later."
      redirect_to new_user_registration_path
    end
  end

end
