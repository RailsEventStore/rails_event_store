# frozen_string_literal: true

Rails.application.routes.draw do
  mount DresRails::Engine => "/dres_rails"
end
