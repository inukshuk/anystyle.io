Rails.application.routes.draw do
  post 'parse', to: 'anystyle#parse', as: :parse
  post 'export', to: 'anystyle#export', as: :export

  root 'anystyle#index'
end
