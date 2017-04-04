require 'ffi'

class WS281X
  extend FFI::Library

  FREQUENCY = 800000
  GPIO = 18
  DMA = 5
  WIDTH = 8
  HEIGHT = 8
  BRIGHTNESS = 255
  RPI_PWM_CHANNELS = 2
  WS2811_STRIP_RGB = 0x00100800

  @config = nil

  class Ws2811_led_t < FFI::Struct
    layout \
      :blue,  :uint8,
      :red,   :uint8,
      :green, :uint8,
      :white, :uint8
  end
  
  class Ws2811_channel_t < FFI::Struct
    layout \
      :gpionum,    :int,
      :invert,     :int,
      :count,      :int,
      :strip_type, :int,
      :leds,       :pointer,
      :brightness, :uint8,
      :wshift,     :uint8,
      :rshift,     :uint8,
      :gshift,     :uint8,
      :bshift,     :uint8
  end
  
  class Ws2811_t < FFI::Struct
    layout \
      :device,  :pointer,
      :rpi_hw,  :pointer,
      :freq,    :uint32,
      :dmanum,  :int,
      :channel, [Ws2811_channel_t, RPI_PWM_CHANNELS]
  end

  ffi_lib 'c'
  attach_function :malloc, [:size_t], :pointer
  attach_function :free, [:pointer], :void

  ffi_lib '../rpi_ws281x.so'

  enum :ws2811_return_t, [
    :WS2811_SUCCESS,                  0,
    :WS2811_ERROR_GENERIC,           -1,
    :WS2811_ERROR_OUT_OF_MEMORY,     -2,
    :WS2811_ERROR_HW_NOT_SUPPORTED,  -3,
    :WS2811_ERROR_MEM_LOCK,          -4,
    :WS2811_ERROR_MMAP,              -5,
    :WS2811_ERROR_MAP_REGISTERS,     -6,
    :WS2811_ERROR_GPIO_INIT,         -7,
    :WS2811_ERROR_PWM_SETUP,         -8,
    :WS2811_ERROR_MAILBOX_DEVICE,    -9,
    :WS2811_ERROR_DMA,              -10,
  ]

  attach_function :ws2811_init, [ Ws2811_t ], :ws2811_return_t
  attach_function :ws2811_fini, [ Ws2811_t ], :int
  attach_function :ws2811_render, [ Ws2811_t ], :int
  attach_function :ws2811_get_return_t_str, [ :ws2811_return_t ], :string

  def initialize
    channel0_pointer = WS281X.malloc Ws2811_channel_t.size
    channel1_pointer = WS281X.malloc Ws2811_channel_t.size
    config_pointer = WS281X.malloc Ws2811_t.size

    ObjectSpace.define_finalizer(self, proc {
      if not @config.nil?
        WS281X.ws2811_fini @config
        @config = nil
      end

      WS281X.free channel0_pointer
      WS281X.free channel1_pointer
      WS281X.free config_pointer
    })

    channel0 = Ws2811_channel_t.new channel0_pointer
    channel0[:gpionum] = GPIO
    channel0[:count] = WIDTH * HEIGHT
    channel0[:invert] = 0
    channel0[:brightness] = BRIGHTNESS
    channel0[:strip_type] = WS2811_STRIP_RGB
    
    channel1 = Ws2811_channel_t.new channel1_pointer
    channel1[:gpionum] = 0
    channel1[:count] = 0
    channel1[:invert] = 0
    channel1[:brightness] = 0
    
    @config = Ws2811_t.new config_pointer
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
    led = Ws2811_led_t.new @config[:channel][0][:leds][(row * 8 + col) * Ws2811_led_t.size]
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

  def self.test
    ws281x = WS281X.new
    
    ws281x.set_pixel_color(0,0, 255,0,0)
    ws281x.set_pixel_color(0,1, 0,255,0)
    ws281x.set_pixel_color(0,2, 0,0,255)

    ws281x.render
    
    sleep 1
    ws281x.clear
    ws281x.render
  end
end

WS281X.test

