class OmniauthRef < ActiveRecord::Base
  belongs_to :user
  validates :bind_token, uniqueness: true, allow_blank: true

  def bound?
    self.bind_token.blank?
  end

  # Create a user bound with the omniauth ref
  # @param email [String]
  #   The user email.
  # @return [User]
  #   The created user object if success, otherwise nil.
  def create_omni_user(email)
    user = nil
    ActiveRecord::Base.transaction do
      password = RandomToken.gen(64)
      user = User.new(email: email,
                      password: password,
                      password_confirmation: password)
      user.skip_confirmation!
      user.save
      self.bind_token = nil
      self.user_id = user.id
      self.save
    end
    return user.persisted? ? user : nil
  end
end
