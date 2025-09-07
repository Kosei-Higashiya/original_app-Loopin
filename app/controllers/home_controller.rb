class HomeController < ApplicationController
  # Allow unauthenticated access to the index page (homepage)
  skip_before_action :authenticate_user!, only: [:index]

  def index
  end

  def dashboard
  end
end
