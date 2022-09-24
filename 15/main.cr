# Based on https://lazyfoo.net/tutorials/SDL/15_rotation_and_flipping/index.php

require "../../src/sdl-crystal-bindings.cr"
require "../../src/sdl-image-bindings.cr"

SCREEN_WIDTH = 640
SCREEN_HEIGHT = 480

class LTexture
  getter width : Int32 = 0
  getter height : Int32 = 0
  
  @texture = Pointer(LibSDL::Texture).null
  @renderer = Pointer(LibSDL::Renderer).null

  def initialize(@renderer : LibSDL::Renderer*)
  end

  def finalize
    free
    @renderer = Pointer(LibSDL::Renderer).null
  end

  def free
    if @texture
      LibSDL.destroy_texture(@texture)
      @texture = Pointer(LibSDL::Texture).null
      @width = 0
      @height = 0
    end
  end

  def set_color(red : UInt8, green : UInt8, blue : UInt8)
    LibSDL.set_texture_color_mod(@texture, red, green, blue)
  end

  def set_blend_mode(blending : LibSDL::BlendMode)
    LibSDL.set_texture_blend_mode(@texture, blending)
  end

  def set_alpha(alpha : UInt8)
    LibSDL.set_texture_alpha_mod(@texture, alpha)
  end

  def load_from_file(path : String)
    free

    loaded_surface = LibSDL.img_load(path)
    raise "Unable to load image #{path}! SDL_image Error: #{String.new(LibSDLMacro.img_get_error)}" unless loaded_surface
    LibSDL.set_color_key(loaded_surface, LibSDL::SBool::TRUE, LibSDL.map_rgb(loaded_surface.value.format, 0, 0xFF, 0xFF))

    @texture = LibSDL.create_texture_from_surface(@renderer, loaded_surface)
    raise "Unable to create texture from #{path}! SDL Error: #{String.new(LibSDL.get_error)}" unless @texture

    @width = loaded_surface.value.w
    @height = loaded_surface.value.h

    LibSDL.free_surface(loaded_surface)
  end

  def render(x : Int, y : Int, clip : LibSDL::Rect*? = nil, angle : Float = 0.0, center : LibSDL::Point*? = nil, flip : LibSDL::RendererFlip = LibSDL::RendererFlip::FLIP_NONE)
    render_quad = LibSDL::Rect.new(x: x, y: y, w: @width, h: @height)

    if clip
      render_quad.w = clip.value.w
      render_quad.h = clip.value.h
    end

    LibSDL.render_copy_ex(@renderer, @texture, clip, pointerof(render_quad), angle, center, flip)
  end
end

if LibSDL.init(LibSDL::INIT_VIDEO) != 0
  raise "SDL could not initialize! SDL Error: #{String.new(LibSDL.get_error)}"
end

if LibSDL.set_hint(LibSDL::HINT_RENDER_SCALE_QUALITY, "1") == 0
  puts "Warning: Linear texture filtering not enabled!"
end

g_window = LibSDL.create_window("SDL Tutorial", LibSDL::WINDOWPOS_UNDEFINED, LibSDL::WINDOWPOS_UNDEFINED, SCREEN_WIDTH, SCREEN_HEIGHT, LibSDL::WindowFlags::WINDOW_SHOWN)
raise "Window could not be created! SDL Error: #{String.new(LibSDL.get_error)}" unless g_window

renderer_flags = LibSDL::RendererFlags::RENDERER_ACCELERATED | LibSDL::RendererFlags::RENDERER_PRESENTVSYNC
g_renderer = LibSDL.create_renderer(g_window, -1, renderer_flags)
raise "Renderer could not be created! SDL Error: #{String.new(LibSDL.get_error)}" unless g_renderer

LibSDL.set_render_draw_color(g_renderer, 0xFF, 0xFF, 0xFF, 0xFF)

img_flags = LibSDL::IMGInitFlags::IMG_INIT_PNG
if (LibSDL.img_init(img_flags) | img_flags.to_i) == 0
  raise "SDL_image could not initialize! SDL_image Error: #{String.new(LibSDLMacro.img_get_error)}"
end

g_arrow_texture = LTexture.new(g_renderer)
g_arrow_texture.load_from_file("examples/15/arrow.png")

quit = false
degrees = 0.0
flip_type = LibSDL::RendererFlip::FLIP_NONE

while(!quit)
  while LibSDL.poll_event(out e) != 0
    if e.type == LibSDL::EventType::QUIT.to_i
      quit = true
    elsif e.type == LibSDL::EventType::KEYDOWN.to_i
      case e.key.keysym.sym
        when LibSDL::KeyCode::K_A.to_i then degrees -= 60
        when LibSDL::KeyCode::K_D.to_i then degrees += 60
        when LibSDL::KeyCode::K_Q.to_i then flip_type = LibSDL::RendererFlip::FLIP_HORIZONTAL
        when LibSDL::KeyCode::K_W.to_i then flip_type = LibSDL::RendererFlip::FLIP_NONE
        when LibSDL::KeyCode::K_E.to_i then flip_type = LibSDL::RendererFlip::FLIP_VERTICAL
      end
    end
  end

  LibSDL.set_render_draw_color(g_renderer, 0xFF, 0xFF, 0xFF, 0xFF)
  LibSDL.render_clear(g_renderer)

  g_arrow_texture.render((SCREEN_WIDTH - g_arrow_texture.width) // 2, (SCREEN_HEIGHT - g_arrow_texture.height) // 2, nil, degrees, nil, flip_type)

  LibSDL.render_present(g_renderer)
end

g_arrow_texture.free

LibSDL.destroy_renderer(g_renderer)
LibSDL.destroy_window(g_window)

LibSDL.img_quit
LibSDL.quit