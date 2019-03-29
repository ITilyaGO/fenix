class Account < ActiveRecord::Base
  attr_accessor :password, :password_confirmation
  attr_accessor :current
  belongs_to :section

  # Validations
  validates_presence_of     :email, :role, :message => 'не может быть пустым'
  validates_presence_of     :password,                   :if => :password_required
  validates_presence_of     :password_confirmation,      :if => :password_required
  validates_length_of       :password, :within => 4..40, :if => :password_required
  validates_confirmation_of :password,                   :if => :password_required
  validates_length_of       :email,    :within => 3..100
  validates_uniqueness_of   :email,    :case_sensitive => false, :message => 'уже используется'
  validates_format_of       :email,    :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  validates_format_of       :role,     :with => /[A-Za-z]/

  # Callbacks
  before_save :encrypt_password, :if => :password_required

  ##
  # This method is for authentication purpose.
  #
  def self.authenticate(email, password)
    account = where("lower(email) = lower(?)", email).first if email.present?
    account && account.has_password?(password) ? account : nil
  end

  def self.authenticate_customer(email, password)
    account = where("lower(email) = lower(?)", email).first if email.present?
    account && account.has_password?(password) ? account : nil
  end

  def has_password?(password)
    ::BCrypt::Password.new(crypted_password) == password
  end

  def is_admin?
    # TODO: fix this
    self.role == "admin" || self.role == "editor"
  end

  def is_me?
    !id.nil? && id == current
  end

  def new_orders
    # OrderPart.where(:section => self.section, :state => OrderPart.states[:anew]).where(order: { :status => Order.statuses[:current] }).where(order: { :status => Order.statuses[:anew] }).count
    c = OrderPart.where(:section => self.section, :state => OrderPart.states[:anew])
      .joins(:order).merge(Order.in_work).count
    c > 0 ? c : ''
    # where("status >= ?", Order.statuses[:draft]).size

    # Order.where("status >= ?", Order.statuses[:draft])).where(:)
  end

  private

  def encrypt_password
    value = ::BCrypt::Password.create(password)
    value = value.force_encoding(Encoding::UTF_8) if value.encoding == Encoding::ASCII_8BIT
    self.crypted_password = value
  end

  def password_required
    crypted_password.blank? || password.present?
    # false if self.role == "temp"
  end
end
