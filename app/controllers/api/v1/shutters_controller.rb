require "open-uri"
require "tempfile"
require "diffy"

module Api
  module V1
    class ShuttersController < ApplicationController
      include ScreenshotHelper
      before_action :validate_key

      def show
        mode = params[:mode] || "screenshot"
        url = params[:url]
        diff = params[:diff] == "true"

        Rails.logger.info "Diff mode: #{diff}"

        if mode == "screenshot"
          handle_screenshot_mode(url, diff)
        elsif mode == "html"
          handle_html_mode(url, diff)
        else
          render json: { error: "Invalid mode parameter" }, status: :bad_request
        end
      end

      private

      def handle_screenshot_mode(url, diff)
        cache_key = "latest_screenshot_base64_#{url}"
        latest_screenshot_base64 = Rails.cache.read(cache_key)

        Rails.logger.info "Cache hit: #{latest_screenshot_base64.present?}"
        current_screenshot_base64 = take_screenshot(url)

        if diff && latest_screenshot_base64.present?
          difference_image_data_url = generate_difference_image(latest_screenshot_base64, current_screenshot_base64)
          send_data Base64.decode64(difference_image_data_url.split(",")[1]), type: "image/png", disposition: "inline"
          Rails.logger.info "Difference mode"
        else
          send_data Base64.decode64(current_screenshot_base64), type: "image/png", disposition: "inline"
          Rails.logger.info "Normal mode"
        end

        Rails.cache.write(cache_key, current_screenshot_base64)
      end

      def handle_html_mode(url, diff)
        cache_key = "html_#{url}"
        current_html = fetch_html(url)
      
        if diff
          previous_html = Rails.cache.exist?(cache_key) ? Rails.cache.read(cache_key) : current_html
          diff_result = Diffy::Diff.new(previous_html, current_html, include_diff_info: true)
        
          additions = diff_result.select { |line| line.start_with?('+') && !line.start_with?('+++ ') }
          deletions = diff_result.select { |line| line.start_with?('-') && !line.start_with?('--- ') }
      
          render json: { diff: { additions: additions, deletions: deletions } }
        else
          render json: { html: current_html }
        end
      
        Rails.cache.write(cache_key, current_html) # この行をメソッドの最後に移動します
      end

      def fetch_html(url)
        URI.parse(url).open.read
      end

      def validate_key
        if params[:key] != ENV["API_KEY"]
          render json: { error: "Invalid API key" }, status: :unauthorized
        end
      end
    end
  end
end
