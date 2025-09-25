class MvcDemoController < ApplicationController
  def index
    @message = "Welcome to MVC Demo!"
    @current_time = Time.current
  end

  def hello
    @name = params[:name] || "World"
    @greeting = "Hello, #{@name}!"
  end

  def counter
    @count = params[:count].to_i
    @count += 1
  end

  def form_demo
    if request.post?
      @user_input = params[:user_input]
      @processed_message = "You entered: #{@user_input.upcase}"
    end
  end
end