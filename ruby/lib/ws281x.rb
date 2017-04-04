require 'ffi'

class WS281X
  extend FFI::Library

  RPI_PWM_CHANNELS = 2

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

end

