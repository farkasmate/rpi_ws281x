require 'ffi'

module WS281X
  extend FFI::Library

  RPI_PWM_CHANNELS = 2
  
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

  def self.dump(config)
    print "DEVICE:  #{config[:device]}\n"
    print "RPI_HW:  #{config[:rpi_hw]}\n"
    print "FREQ:    #{config[:freq]}\n"
    print "DMANUM:  #{config[:dmanum]}\n"
    print "CHANNEL: #{config[:channel]}\n"
    config[:channel].each_with_index { |channel, index|
      print "  [#{index}] GPIONUM:    #{channel[:gpionum]}\n"
      print "  [#{index}] INVERT:     #{channel[:invert]}\n"
      print "  [#{index}] COUNT:      #{channel[:count]}\n"
      print "  [#{index}] STRIP_TYPE: #{channel[:strip_type]}\n"
      print "  [#{index}] BRIGHTNESS: #{channel[:brightness]}\n"
      print "  [#{index}] WSHIFT:     #{channel[:wshift]}\n"
      print "  [#{index}] RSHIFT:     #{channel[:rshift]}\n"
      print "  [#{index}] GSHIFT:     #{channel[:gshift]}\n"
      print "  [#{index}] BSHIFT:     #{channel[:bshift]}\n"
      print "  [#{index}] LEDS:       #{channel[:leds]}\n"
      channel[:count].times { |i|
        led = Ws2811_led_t.new channel[:leds][i]
        print "    [#{i}] : #{led[:red]},#{led[:green]},#{led[:blue]}\n"
      }
    }
  end

  def self.test
    channel0_pointer = WS281X.malloc Ws2811_channel_t.size
    channel0 = Ws2811_channel_t.new channel0_pointer
    channel0[:gpionum] = 18
    channel0[:count] = 64
    channel0[:invert] = 0
    channel0[:brightness] = 255
    channel0[:strip_type] = 0x00100800
    
    channel1_pointer = WS281X.malloc Ws2811_channel_t.size
    channel1 = Ws2811_channel_t.new channel1_pointer
    channel1[:gpionum] = 0
    channel1[:count] = 0
    channel1[:invert] = 0
    channel1[:brightness] = 0
    
    config_pointer = WS281X.malloc Ws2811_t.size
    config = Ws2811_t.new config_pointer
    config[:freq] = 800000
    config[:dmanum] = 5
    config[:channel][0] = channel0
    config[:channel][1] = channel1
    
    init_code = WS281X.ws2811_init config
    print "#{WS281X.ws2811_get_return_t_str init_code}\n"
    
    dump config
    
    led0 = Ws2811_led_t.new config[:channel][0][:leds][0 * Ws2811_led_t.size]
    led0[:red]   = 255
    led0[:green] = 0
    led0[:blue]  = 0
    
    led1 = Ws2811_led_t.new config[:channel][0][:leds][1 * Ws2811_led_t.size]
    led1[:red]   = 0
    led1[:green] = 255
    led1[:blue]  = 0
    
    led2 = Ws2811_led_t.new config[:channel][0][:leds][2 * Ws2811_led_t.size]
    led2[:red]   = 0
    led2[:green] = 0
    led2[:blue]  = 255
    
    WS281X.ws2811_render config
    
    sleep 1

    led0[:red]   = 0
    led0[:green] = 0
    led0[:blue]  = 0
    led1[:red]   = 0
    led1[:green] = 0
    led1[:blue]  = 0
    led2[:red]   = 0
    led2[:green] = 0
    led2[:blue]  = 0
    WS281X.ws2811_render config

    WS281X.ws2811_fini config

    WS281X.free channel0_pointer
    WS281X.free channel1_pointer
    WS281X.free config_pointer
  end
end

WS281X.test

