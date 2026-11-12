Rails.application.configure do
  config.after_initialize do
    Bullet.enable = Rails.env.development? || Rails.env.test?
    Bullet.bullet_logger = true
    Bullet.rails_logger = true
    Bullet.console = Rails.env.development?
    Bullet.raise = Rails.env.test?
  end
end
