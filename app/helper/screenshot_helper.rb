require "selenium-webdriver"
require "chunky_png"

module ScreenshotHelper
  def take_screenshot(url)
    options = Selenium::WebDriver::Firefox::Options.new
    options.add_argument("--headless")

    driver = Selenium::WebDriver.for :firefox, options: options
    driver.manage.window.size = Selenium::WebDriver::Dimension.new(1280, 1280)
    driver.navigate.to url
    image_base64 = driver.screenshot_as(:base64)
    driver.quit

    image_base64
  end

  def generate_difference_image(image1_base64, image2_base64)
    image1 = ChunkyPNG::Image.from_data_url("data:image/png;base64,#{image1_base64}")
    image2 = ChunkyPNG::Image.from_data_url("data:image/png;base64,#{image2_base64}")

    width = [image1.width, image2.width].min
    height = [image1.height, image2.height].min

    diff = ChunkyPNG::Image.new(width, height, ChunkyPNG::Color::TRANSPARENT)

    width.times do |x|
      height.times do |y|
        if image1[x, y] != image2[x, y]
          diff[x, y] = ChunkyPNG::Color.rgb(255, 0, 0)
        else
          diff[x, y] = grayscale(image1[x, y])
        end
      end
    end

    diff.to_data_url
  end

  def grayscale(color)
    r = ChunkyPNG::Color.r(color)
    g = ChunkyPNG::Color.g(color)
    b = ChunkyPNG::Color.b(color)

    gray = (r + g + b) / 3
    ChunkyPNG::Color.rgb(gray, gray, gray)
  end
end
