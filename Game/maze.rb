require 'rubygems'
require 'gosu'
require 'minigl'
require 'bg_utils'

include MiniGL

module ZOrder
  BACKGROUND, BOMB, WALL, PLAYER = *0..3
end

WIDTH = 800
HEIGHT = 600

class Maze < GameWindow
	def initialize()
		super WIDTH, HEIGHT, false
		self.caption = "Maze Runner"
		@finished = false
		@finish2 = false
		@start_x = 100
		@start_y = 530
		@sprite = GameObject.new(@start_x, @start_y, 28, 28, :runner, Vector.new(0, 0), 2,2)
		#require bg_utils to make the black walls textured
		@wall = BgUtils::TiledImage.new(File.dirname(__FILE__) + "/media/wall.png",80,80)
		#end 
		@tre_x = 100
		@tre_y = 530
		@key_x = 10
		@key_y = 10
		@key = GameObject.new(@key_x, @key_y, 30, 30, :key, Vector.new(0, 0))
		@background = Gosu::Image.new(File.dirname(__FILE__) + "/media/background.png", :tileable => true)
		@door = GameObject.new(@start_x, @start_y, 30, 30, :door, Vector.new(0, 0))
		@treasure = GameObject.new(@tre_x, @tre_y, 80, 80, :treasure, Vector.new(0, 0), 2,1)
		@cspeed = 5
		
		#wall making 
		@walls = []
		#Require MiniGL
		@map = Map.new(80, 80, 20, 20)
		@walls_arr = Array.new(30) { Array.new(30) { nil } }
		f = File.open(File.dirname(__FILE__) + '/map.txt')
		f.each_line.with_index do |line, j|
			line.each_char.with_index do |char, i|
				(@walls << (@walls_arr[i][j] = Block.new(i * 80, j * 80, 80,80))) if '#' === char
				(@start_x = @sprite.x = i * 80 + 10; @start_y = @sprite.y = j * 80 + 10) if '@' === char
				(@door.x = i * 80 + 10; @door.y = j * 80 + 10) if '!' === char
				(@treasure.x = i * 80  ; @treasure.y = j * 80) if '?' === char
				(@key.x = i * 80 + 10; @key.y = j * 80 + 20) if '/' === char
			end
		end
		#end
		@button_font = Gosu::Font.new(48)
		@font2 = Gosu::Font.new(30)

		#Variables for key
		@nokey = 0
		@nochest = 0
		#end
		#Time count
		@second = 0
		diff,name = ask
		print "Enter your name: "
		@name = gets.chomp
		@time_taken = 0
		@minutes = 0
		@seconds = 0
		@last_time = Gosu::milliseconds()
		@timecollect = []
		#end
		@time_taken = 0

	end

	
	def needs_cursor?
		@finished || @finish2
	end
	
	def update
		KB.update
		Mouse.update
		if @finished || @finish2
			@second -= 0
		else
			#walking 
			v = Vector.new(0,0)
		    if KB.key_down?(Gosu::KB_RIGHT)
				v.x += @cspeed
				#Require MiniGL for animation
				@sprite.set_animation 2
			end
			if KB.key_down?(Gosu::KB_LEFT)
				v.x -= @cspeed 
				@sprite.set_animation 1
			end
		    if KB.key_down?(Gosu::KB_DOWN)	
				v.y += @cspeed
				@sprite.set_animation 3
			end
		    if KB.key_down?(Gosu::KB_UP)	
				v.y -= @cspeed
				@sprite.set_animation 0
			end
			#collision check
			#Require MiniGL
			coll_walls = []
			coll_x = @sprite.x.to_i / 80
			coll_y = @sprite.y.to_i / 80
				for i in (coll_x-1)..(coll_x+1)
					for j in(coll_y-1)..(coll_y+1)
						if i >= 0 && j >= 0 && @walls_arr[i] && @walls_arr[i][j]
							coll_walls << @walls_arr[i][j] 
						end
					end
				end
		@sprite.move(v, coll_walls, [], true)
		end
		#when the chara hits key
		if @sprite.bounds.intersect?(@key.bounds)
			if @nokey == 0
				@nokey += 1
			else 
				@key.x = 10000
			end
		end
		#when the chara hits treasure after getting key
		if @sprite.bounds.intersect?(@treasure.bounds)
			if @nokey == 0
			else
				@treasure.set_animation 1
				@nochest += 1
			end
		end		
		#when the chara hits door after getting treasure
		if @sprite.bounds.intersect?(@door.bounds)
			if @nochest >= 1
				@finished = true
			end
		end
		#time counter
		if (Gosu::milliseconds - @last_time) / 1000 == 1
			
			@last_time = Gosu::milliseconds()
			if @finished == false
				@seconds += 1
				@second -= 1
				
			else 
				@second -= 0
				@seconds += 0
			end
			if @second == 0
				@second = 0
				@finish2 = true
			end
		end
		@time_taken = @seconds
		#minigl
		@map.set_camera(@sprite.x - WIDTH/2, @sprite.y - HEIGHT/2)
	end
	
	def draw
		@background.draw(0,0, ZOrder::BACKGROUND)
		@treasure.draw(@map)
		@door.draw(@map)
		@sprite.draw(@map)
		@key.draw(@map)

		if @second > 0
			@button_font.draw_text(@second.to_s,700,30, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::WHITE)
		else
			@button_font.draw_text('0'.to_s,700,30, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::WHITE)
		end
		#minigl
		@map.foreach do |i,j,x,y|
			if @walls_arr[i][j]
				@wall.draw_as_quad(x,y,#change color to look for the path if draw_quad
				x + 80, y, 
				x, y + 80,
				x + 80, y + 80,0) 
			end
		end
		if @finished
			# @button_font.draw_text("Time Taken: " + @timer.to_s + " seconds",288,240, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::YELLOW)
			@button_font.draw_text("You Win!",318,280, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::WHITE)
			@button_font.draw_text("Press ESC to quit",270,360, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::WHITE)
		end
		if @finish2
			# @button_font.draw_text("Time Taken: " + @timer.to_s + " seconds",288,240, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::YELLOW)
			@button_font.draw_text("You Lost!",318,280, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::WHITE)
			@button_font.draw_text("Press SPACE to quit",270,360, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::WHITE)
		end
	end
	def button_down(id)
		if @finished 
			if id == Gosu::KB_ESCAPE
				@timecollect << @time_taken
				file = File.open(File.dirname(__FILE__) + '/recordwin.txt','a')
				for x in 0..@timecollect.length-1
					file.puts @name.to_s + " - Time taken: " + @timecollect[x].to_s + " seconds"
				end
				file.close()
				close
			else
				super
			end
		elsif @finish2
			if id == Gosu::KB_SPACE
				close
			end
		end
	end
end

def ask
	while true
		diff = gets.chomp.to_i
		if diff == 1
			@second = 120
			break
		elsif diff == 2
			@second = 90
			break
		elsif diff == 3
			@second = 60
			break
		else
			puts "Wrong difficulties, Try again"
			print "Selection: "
		end
	end
end

def main
	while true
		puts "\nWhat is your choice:"
		puts "1. Play Game"
		puts "2. See Record"
		puts "3. Exit Application"
		print "Choice: "
		selected = gets.chomp
		if selected == '1'
			puts""
			puts "You are given time to search for key and chest before"
			puts "finding for a door to exit between given time"
			puts "Select Difficulties"
			puts "1. Easy (Given time 2min/120secs)"
			puts "2. Medium (Given time 1.5min/90secs)"
			puts "3. Hard (Given time 1min/60secs)"
			print "Selection: "
			Maze.new.show
			break
		elsif selected == '2'
			
			puts"\nRecord of the game"
			rec = File.open(File.dirname(__FILE__) + '/recordwin.txt').read
			rec.gsub!(/\r\n?/, "\n")
			rec.each_line do |line|
				print "#{line}"
			end
			puts"Done!"
		elsif selected == '3'
			break
		else
			true
		end
	end
end

main