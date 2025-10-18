require 'rails_helper'

RSpec.describe "Static Pages", type: :request do
  describe "GET /pages/terms" do
    it "returns http success without login" do
      get page_path("terms")
      expect(response).to have_http_status(:success)
    end

    it "displays the terms of service content" do
      get page_path("terms")
      expect(response.body).to include("利用規約")
    end
  end

  describe "GET /pages/privacy" do
    it "returns http success without login" do
      get page_path("privacy")
      expect(response).to have_http_status(:success)
    end

    it "displays the privacy policy content" do
      get page_path("privacy")
      expect(response.body).to include("プライバシーポリシー")
    end
  end
end
