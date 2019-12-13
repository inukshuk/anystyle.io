class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  rescue_from ActionController::ParameterMissing, with: :bad_request

  private

  def bad_request(message = 'Bad Request')
    render status: :bad_request, text: message
  end
end

