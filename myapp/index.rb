require 'sinatra'   # gem 'sinatra'
#require 'sinatra/reloader'
require 'line/bot'  # gem 'line-bot-api'
require 'cloudinary' 

def client
  @client ||= Line::Bot::Client.new { |config|
    config.channel_secret = 'SECRET'
    config.channel_token = 'TOKEN'
  }
end

def upload(file)
  result = Cloudinary::Uploader.upload(file, api_key: '421836929114675', api_secret: 'xy111Ul88mK0iUfEO6_vPW77E5Q', cloud_name: 'dpbbavoeq')
  return result['secure_url']
end

#def list 
#  results = Cloudinary::Api.resources(type:"upload")
#  resources = results["resources"]
#  ids = resources.map {|res| res["public_id"]}
#  ids.select! {|public_id| !public_id.include?("/")}
#end

#get '/imagelist' do 
#  erb :imagelist
#end

get '/image/:id' do
    id = params['id']
    img = File.binread("/tmp/" + id)
    content_type "image/jpeg"
    img
end

post '/callback' do
  body = request.body.read

  signature = request.env['HTTP_X_LINE_SIGNATURE']
  unless client.validate_signature(body, signature)
    error 400 do 'Bad Request' end
  end

  events = client.parse_events_from(body)
  
  events.each { |event|
    case event
    when Line::Bot::Event::Message
      case event.type
      when Line::Bot::Event::MessageType::Text
        message = {
          type: 'text',
          text: event.message['text']
        }

       #if message == "一覧" 
       #   list
       #   @images = ids
       #   puts "https://media-uploader-hirai-shuta.herokuapp.com/imagelist.erb"
       #end 

        client.reply_message(event['replyToken'], message)
      when Line::Bot::Event::MessageType::Image
          id = event.message["id"]
          response = client.get_message_content(id)
          File.binwrite("/tmp/" + id.to_s, response.body)
          url = upload("/tmp/#{id}")
		  message = {
            type: 'text',
            text: url
          }
          client.reply_message(event['replyToken'], message)
      end
     end
  }

  "OK"
end
