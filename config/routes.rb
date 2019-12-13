Rails.application.routes.draw do
  post 'parse', to: 'anystyle#parse', as: :parse
  post 'format', to: 'anystyle#format', as: :format

  root 'anystyle#index'
end
