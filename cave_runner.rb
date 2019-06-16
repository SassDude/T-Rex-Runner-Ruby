# Encoding: UTF-8

require 'rubygems'
require 'gosu'

# Create some constants for the screen width and height
WIDTH = 800
HEIGHT = 300
PLAY = 1
GAMEOVER = 2
HOMESCREEN = 3

module ZOrder
    BACKGROUND, CLOUDS, PATH, OBEJECTS, UI = *0..5
end

class Player
    def initialize
        @stand, @blank, @walk1, @walk2, @hit = *Gosu::Image.load_tiles("media/dino.png", 88, 95)
        @jump = Gosu::Sample.new("media/jump.wav")
        @die = Gosu::Sample.new("media/die.wav")
        @duck, @duck2 = *Gosu::Image.load_tiles("media/dino_ducking.png", 118, 95)
        @vel_y = 0
        @x = WIDTH/6
        @y = HEIGHT - (HEIGHT/8) * 4
        @image = @stand
        @n = 0
    end

    def jump
        if (@vel_y == 0)
            @vel_y -= 2
            @jump.play
        end
    end

    def gravity
        # Vertical movement
        if @vel_y > 0
            @vel_y.times { if @y <= 150 then @y += 2 else @vel_y = 0 end }
        end
        if @vel_y < 0
            (-@vel_y).times { if @y >= 0 then @y -= 4 else @vel_y = 2 end }
        end
    end

    def duck
        if @y >= (150)
            if @n.to_i.even?
                @image = @duck
            else
                @image = @duck2
            end
        else
            @vel_y += 2

        end
    end

    def run
        if @n.to_i.even?
            @image = @walk2
        else
            @image = @walk1
        end
        @n += 0.05
    end

    def draw
        @image.draw(@x, @y, ZOrder::OBEJECTS)
    end

    def collide_object(all_objects)
        if all_objects.size >= 1
            all_objects.reject! do |object|
                if Gosu.distance(@x, @y, object.x, object.y) < object.hit_distance # an arbitrary distance - could be improved!!!
                    @die.play
                    @image = @hit
                end
            end
        end
    end

end

class Object
    attr_reader :x, :y, :type, :hit_distance

    def initialize(image, type, pos_y, hit_distance, level)
        @type = type;
        @hit_distance = hit_distance;
        case type
            when :flyer
                @fly, @fly2 = *Gosu::Image.load_tiles(image, 46, 41);
                @image = @fly
            when :big_catus_heap
                @big, @big2, @big3, @big4, @big5=  *Gosu::Image.load_tiles(image, 50, 101);
                case rand(5)
                    when 0
                        @image = @big
                    when 1
                        @image = @big2
                    when 2
                        @image = @big3
                    when 3
                        @image = @big4
                    when 4
                        @image = @big5
                end
            when :small_catus_heap
                @small, @small2, @small3, @small4, @small5=  *Gosu::Image.load_tiles(image, 34, 70);
                case rand(5)
                    when 0
                        @image = @small
                    when 1
                        @image = @small2
                    when 2
                        @image = @small3
                    when 3
                        @image = @small4
                    when 4
                        @image = @small5
                end
            else
                @image = Gosu::Image.new(image);
        end
        @x = WIDTH + WIDTH/6
        @y = pos_y;
        @vel_x = 5 + level/50;
        @n = 0
    end

    def move
        @x -= @vel_x
    end

    def update
        case type
            when :flyer
                if @n.to_i.even?
                    @image = @fly
                else
                    @image = @fly2
                end
        end
        @n += 0.1
    end

    def draw
        @image.draw(@x, @y, ZOrder::OBEJECTS)
    end
end

class Cloud
    attr_reader :x, :y, :type

    def initialize(image, type, pos_y, level)
        @type = type;
        @image = Gosu::Image.new(image);
        @x = WIDTH + WIDTH/6
        @y = pos_y;
        @vel_x = 5 + level/50;
    end

    def move
        @x -= @vel_x
    end

    def draw
        @image.draw(@x, @y, ZOrder::CLOUDS)
    end
end

class CaveRunnerGame < Gosu::Window

    def initialize
        super WIDTH, HEIGHT
        self.caption = "Cave Runner Game"

        @background_image = Gosu::Image.new("media/ground.png")
        @checkpoint = Gosu::Sample.new("media/checkpoint.wav")
        @object = Array.new
        @cloud = Array.new
        @player = Player.new

        @font = Gosu::Font.new(20)
        @big_font = Gosu::Font.new(120)
        @score = 0
        @state = HOMESCREEN
        @highscores = read_scores_file()
        @colour = 0xffffffff
        @blue = 1
        @vel = 0
        @y = 1203
        @x = 0
        @min = @vel * 14
        @max = @vel * 36
    end

    def update
        if (@state == PLAY)
            if @player.collide_object(@object)
                @state = GAMEOVER
                update_highscore()
            end

            if Gosu.button_down? Gosu::KB_UP or Gosu.button_down? Gosu::KbSpace
                @player.jump
            end

            if Gosu.button_down? Gosu::KB_DOWN or Gosu.button_down? Gosu::GP_BUTTON_9
                @player.duck
            end

            @player.gravity

            @object.each { |object| object.move }

            self.remove_object

            @cloud.each { |cloud| cloud.move }

            self.remove_cloud

            @length = @object.length-1

            if rand(100) < 2 and @object.size < 8
                if @length >= 0
                    if @object[@length].x < WIDTH - rand(@min..@max)
                        @object.push(generate_object)
                    end
                else
                    @object.push(generate_object)
                end
            end

            if rand(100) < 2 and @cloud.size < 5
                @cloud.push(generate_cloud)
            end
            @score += 0.03
            @level = @score.floor
            @min = @vel * 14 + @vel
            @max = @vel * 36 - @vel
            @x -= @vel
            @y -= @vel
            @vel = 5 + @level/50
        else
            if ( button_down?(Gosu::KbSpace) )
                @score = 0
                @state = PLAY
                @object = Array.new
                @cloud = Array.new
                @player = Player.new
                @highscores = read_scores_file()
                @vel = 5
                @x = 0
                @y = 1203
                @min = @vel * 14
                @max = @vel * 36
            end
      	end


    end

    def draw
        Gosu.draw_rect(0, 0, WIDTH, HEIGHT, 0xffffffff, ZOrder::BACKGROUND, mode=:default)
            @player.draw

        if (@state == PLAY)
            @player.run

            if @y >= -1203
                @background_image.draw(@y, (HEIGHT - (HEIGHT/8) * 2), ZOrder::PATH,)
            else
                @y = WIDTH
            end
            if @x >= -1203
                @background_image.draw(@x, (HEIGHT - (HEIGHT/8) * 2), ZOrder::PATH,)
            else
                @x = WIDTH
            end
        end
        if (@state == HOMESCREEN)
            @background_image.draw(@x, (HEIGHT - (HEIGHT/8) * 2), ZOrder::PATH,)
            @big_font.draw("RUNNER", WIDTH/6 + 60, HEIGHT/6, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
            @font.draw("By Patrick Siassios", WIDTH/3 + 70, HEIGHT/3 + 70, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
        end
        if (@state != HOMESCREEN)
            @cloud.each { |cloud| cloud.draw }
            @object.each { |object| object.draw }
            @object.each { |object| object.update }
            @font.draw("Score: #{@score.floor}", WIDTH - 110, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
            @font.draw("Highscore: #{@highscores[0]}", WIDTH - 250, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::GRAY)
        end
        if (@state == GAMEOVER)
            @background_image.draw(0, (HEIGHT - (HEIGHT/8) * 2), ZOrder::PATH,)
            @big_font.draw("GAMEOVER", WIDTH/6 - 40, HEIGHT/6, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
            @font.draw("Score: #{@score.floor}", WIDTH/3 + 70, HEIGHT/3 + 50, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
        end
    end

    def generate_object
        case rand(5)
            when 0
                Object.new("media/large_catus.png", :large_catus, HEIGHT - (HEIGHT/8) * 4, 70, @level)
            when 1
                Object.new("media/small_catus.png", :small_catus, HEIGHT - (HEIGHT/8) * 3, 60, @level)
            when 2
                Object.new("media/flyer.png", :flyer, HEIGHT - (HEIGHT/8) * rand(4.5..6), 24, @level)
            when 3
                Object.new("media/cacti-small.png", :small_catus_heap, HEIGHT - (HEIGHT/8) * 3.2, 70, @level)
            when 4
                Object.new("media/cacti-big.png", :big_catus_heap, HEIGHT - (HEIGHT/8) * 4, 70, @level)
        end
    end

    def generate_cloud
        case rand(1)
            when 0
                Cloud.new("media/cloud.png", :cloud, HEIGHT - (HEIGHT/8) * rand(5..8), @level)
        end
    end

    def remove_object
        @object.reject! do |object|
            if object.x < -100
                true
            else
                false
            end
        end
    end

    def remove_ground
        @ground.reject! do |ground|
            if ground.x < -1203
                true
            else
                false
            end
        end
    end

    def remove_cloud
        @cloud.reject! do |cloud|
            if cloud.x < -100
                true
            else
                false
            end
        end
    end

    def read_scores scores_file
        count = scores_file.gets().to_i
        scores = Array.new()

        n = 0
        while count > n
            score = scores_file.gets
            scores << score
            n += 1
        end
        scores
    end

    def read_scores_file
        file_path = "scores.txt"
        if File.exist?(file_path)
            a_file = File.new(file_path, "r") # open for reading
            highscores = read_scores(a_file)
            a_file.close
        else
            system "echo.>score.txt"
            highscores = File.open(file_path, "r")
        end
        highscores
    end

    def update_highscore
        i = 1
        score = @score.floor
        while @highscores[i].to_i > score
            i += 1
        end
        @highscores.insert(i - 1, score)
        a_file = File.new("scores.txt", "w") # open for writing

        n = @highscores.length
        if a_file  # if nil this test will be false
            index = 0
            a_file.puts(n)
            while n > index
                a_file.puts(@highscores[index])
                index += 1
            end
            a_file.close
            else
            puts "Unable to open file to write!"
        end
    end

    def button_down(id)
        if id == Gosu::KB_ESCAPE
            close
        else
            super
        end
    end
end

CaveRunnerGame.new.show if __FILE__ == $0
