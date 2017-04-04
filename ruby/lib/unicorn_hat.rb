require 'ws281x.rb'

class UnicornHat
  FREQUENCY = 800000
  GPIO = 18
  DMA = 5
  WIDTH = 8
  HEIGHT = 8
  BRIGHTNESS = 255
  WS2811_STRIP_RGB = 0x00100800

  def initialize
    channel0_pointer = WS281X.malloc WS281X::Ws2811_channel_t.size
    channel1_pointer = WS281X.malloc WS281X::Ws2811_channel_t.size
    config_pointer = WS281X.malloc WS281X::Ws2811_t.size

    ObjectSpace.define_finalizer(self, proc {
      if not @config.nil?
        WS281X.ws2811_fini @config
        @config = nil
      end

      WS281X.free channel0_pointer
      WS281X.free channel1_pointer
      WS281X.free config_pointer
    })

    channel0 = WS281X::Ws2811_channel_t.new channel0_pointer
    channel0[:gpionum] = GPIO
    channel0[:count] = WIDTH * HEIGHT
    channel0[:invert] = 0
    channel0[:brightness] = BRIGHTNESS
    channel0[:strip_type] = WS2811_STRIP_RGB
    
    channel1 = WS281X::Ws2811_channel_t.new channel1_pointer
    channel1[:gpionum] = 0
    channel1[:count] = 0
    channel1[:invert] = 0
    channel1[:brightness] = 0
    
    @config = WS281X::Ws2811_t.new config_pointer
    @config[:freq] = FREQUENCY
    @config[:dmanum] = DMA
    @config[:channel][0] = channel0
    @config[:channel][1] = channel1
    
    init_code = WS281X.ws2811_init @config
    
    if init_code != :WS2811_SUCCESS
      raise "#{WS281X.ws2811_get_return_t_str init_code}"
    end
  end

  def set_pixel_color(row, col, red, green, blue)
    led = WS281X::Ws2811_led_t.new @config[:channel][0][:leds][(row * 8 + col) * WS281X::Ws2811_led_t.size]
    led[:red]   = red
    led[:green] = green
    led[:blue]  = blue
  end

  def clear
    HEIGHT.times { |row|
      WIDTH.times { |col|
        set_pixel_color(row, col, 0,0,0)
      }
    }
  end

  def render
    WS281X.ws2811_render @config
  end
end

