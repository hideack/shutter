module Api
  module V1
    class ShuttersController < ApplicationController
      include ScreenshotHelper

      def show
        url = params[:url]
        key = params[:key]
        diff = params[:diff]

        return head :unauthorized if key != ENV["API_KEY"]

        cache_key = "latest_screenshot_base64_#{url}"
        latest_screenshot_base64 = Rails.cache.read(cache_key)

        Rails.logger.info "Cache hit: #{latest_screenshot_base64.present?}"
        current_screenshot_base64 = take_screenshot(url)

        if diff == "true" && latest_screenshot_base64.present?
          difference_image_data_url = generate_difference_image(latest_screenshot_base64, current_screenshot_base64)
          send_data Base64.decode64(difference_image_data_url.split(",")[1]), type: "image/png", disposition: "inline"
          Rails.logger.info "Difference mode"
        else
          send_data Base64.decode64(current_screenshot_base64), type: "image/png", disposition: "inline"
          Rails.logger.info "Normal mode"
        end

        Rails.cache.write(cache_key, current_screenshot_base64)
      end
    end
  end
end
