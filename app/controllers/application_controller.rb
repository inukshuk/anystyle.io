class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  private

  def bad_request(message = 'status.bad_request')
    render status: :bad_request, text: I18n.t(message)
  end

  def not_authorized(message = 'status.unauthorized')
    render status: :unauthorized, text: I18n.t(message)
  end
end
