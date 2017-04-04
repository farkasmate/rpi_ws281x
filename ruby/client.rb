require 'unicorn_hat'

unicorn = UnicornHat.new
unicorn.set_pixel_color(0,0, 255,0,0)
unicorn.set_pixel_color(0,1, 0,255,0)
unicorn.set_pixel_color(0,2, 0,0,255)

unicorn.render

sleep 1
unicorn.clear
unicorn.render

