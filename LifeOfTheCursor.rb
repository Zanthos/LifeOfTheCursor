require 'rubygems'
require 'gosu'
require 'yaml'

module Z
  Background, Line, Mouse = *0...3
end

class Coord
  attr_accessor :x, :y
  def initialize(x, y)
    @x, @y = x, y
  end
  def dup
    Coord.new(@x, @y)
  end
  def ==(c)
    (@x == c.x && @y == c.y)
  end
  def to_s
    "#{@x}:#{@y}"
  end
end

class Quad
  attr_accessor :c1, :c2, :c3, :c4
  def initialize(c1, c2, c3, c4)
    @c1, @c2, @c3, @c4 = c1, c2, c3, c4
  end
  def draw(color, z)
    $window.draw_quad(c1.x, c1.y, color, c2.x, c2.y, color,
                      c3.x, c3.y, color, c4.x, c4.y, color, z)
  end
end

class Window < Gosu::Window
  def initialize
    super(800, 800, false)
    $window = self
    self.caption = "Switch"
    @background = Quad.new(Coord.new(0, 0),
                           Coord.new(width, 0),
                           Coord.new(width, height),
                           Coord.new(0, height))
    @middle = Coord.new(width / 2, height / 2)
    restart
  end
  def restart
    @mouse = Mouse.new(self)
  end
  def update
    change = Coord.new(mouse_x - @middle.x, mouse_y - @middle.y)
    @mouse.update(change)
    self.mouse_x = @middle.x
    self.mouse_y = @middle.y
  end
  def draw
    color = 0xffff0000
    @background.draw(color, Z::Background)
    @mouse.draw
  end
  def button_down(id)
    exit if id == Gosu::KbEscape
  end
end

class Mouse
  attr_reader :coord
  def initialize(window)
    @window = window
    @image = Gosu::Image.new(@window, 'lib/cursor.png', false)
    @size = Coord.new(16, 26)
    @sizeMult = Coord.new(@size.x.to_f / @image.width.to_f, @size.y.to_f / @image.height.to_f)
    @coord = Coord.new(0, 0)
    @line = nil
    @lines = []
  end

  def anyCollisions?(coord = @coord)
    bool = false
    c1 = coord.dup
    c2 = Coord.new(coord.x + @size.x, coord.y + @size.y)
    bool = true if c1.x < 0 || c2.x > @window.width
    bool = true if c1.y < 0 || c2.y > @window.height
    bool
  end

  def collisionCalc(orig)
    if anyCollisions?
      fy = Coord.new(@coord.x, orig.y)
      fx = Coord.new(orig.x, @coord.y)
      fyWorks = !anyCollisions?(fy)
      fxWorks = !anyCollisions?(fx)
      origWorks = !anyCollisions?(orig)
      if fyWorks
        @coord = fy
      elsif fxWorks
        @coord = fx
      elsif origWorks
        @coord = orig
      else
        workingCoord = nil
        i = 0
        while workingCoord.nil?
          i += 1
          coords = [Coord.new(orig.x + i, orig.y),
                    Coord.new(orig.x - i, orig.y),
                    Coord.new(orig.x, orig.y + i),
                    Coord.new(orig.x, orig.y - i)]
          for c in coords
            workingCoord = c if !anyCollisions?(c)
          end
        end
        @coord = workingCoord
      end
    end
  end
  
  def update(change)
    orig = @coord.dup
    @coord.x += change.x
    @coord.y += change.y
    collisionCalc(orig)
    if @line
      @line.update(false, @coord)
      if !@window.button_down?(Gosu::MsLeft)
        @lines << @line
        @line = nil
      end
    else
      if @window.button_down?(Gosu::MsLeft)
        @line = Line.new(@coord)
      end
    end
    @lines.each {|line| line.update}
  end

  def draw
    @image.draw @coord.x, @coord.y, Z::Mouse, @sizeMult.x, @sizeMult.y
    @line.draw if @line
    @lines.each {|line| line.draw}
  end
end

class Line
  attr_reader :c1, :c2
  def initialize(coord)
    @c1 = coord.dup
    @c2 = coord.dup
    @slope = Coord.new(1, 1)
    @perpSlope = Coord.new(-1, 1-1)
    @width = 5
    @speed = 3
  end
  def update(shoot = true, coord = @c2)
    @c2 = coord.dup
    xSlope = (@c2.x - @c1.x)
    ySlope = (@c2.y - @c1.y)
    divider = [xSlope.abs.to_f, ySlope.abs.to_f].max
    @slope = Coord.new(xSlope.to_f / divider, ySlope.to_f / divider)
    @perpSlope = Coord.new(@slope.y * -1, @slope.x)
    if shoot
      @c1.x += @slope.x * @speed
      @c1.y += @slope.y * @speed
      @c2.x += @slope.x * @speed
      @c2.y += @slope.y * @speed
    end
  end
  def draw
    color = 0xff00ff00
    $window.draw_quad(@c1.x, @c1.y, color,
                      @c1.x + @perpSlope.x * @width, @c1.y + @perpSlope.y * @width, color,
                      @c2.x + @perpSlope.x * @width, @c2.y + @perpSlope.y * @width, color,
                      @c2.x, @c2.y, color, Z::Line)
  end
end

window = Window.new
window.show