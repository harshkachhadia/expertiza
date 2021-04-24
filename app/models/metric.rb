class Metric < ActiveRecord::Base
    # Adding a function to integrate suggestion detection algorithm (SDA)
    require 'net/http'

#     https://peerlogic.csc.ncsu.edu/sentiment/analyze_reviews_bulk
# http://152.7.99.200:5000/suggestions
# http://152.7.99.200:5000/problem
# http://152.7.99.200:5000/volume






# Get sentiment analysis for review ( get_review_response_metrics ) 
  def response_sentiments_metrics(input_params)

    uri = URI.parse('https://peerlogic.csc.ncsu.edu/sentiment/analyze_reviews_bulk')
    puts uri.hostname
    puts uri.port
    http = Net::HTTP.new(uri.hostname, uri.port)
    req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})
    req.body = input_params
    http.use_ssl = true
    http.ssl_version = 'TLSv1'
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
 
    begin

      @sent_hash = Hash.new
      res = http.request(req)
      puts res.code
        if (res.code == "200" && res.content_type == "application/json")
          @output = res.body
          @output=JSON.parse(@output)

          0.upto(@output['sentiments'].length-1) do |i|                  

              @pos = @output['sentiments'][i]['pos']
              @neg = @output['sentiments'][i]['neg']
              @neu = @output['sentiments'][i]['neu'] 

              @sent = 'positive' if ( @pos > @neg && @pos > @neu )
              @sent = 'neutral' if ( @neu > @pos && @neu > @neg )
              @sent = 'negative' if ( @neg > @neu && @neg > @pos )    
              @sent_hash[i] = @sent 
              
          end

          return @sent_hash
        else 
          return nil 
        end

    rescue StandardError
      return nil
    end
  end

  def show_confirmation_page
        flash[:error] = params[:error_msg] unless params[:error_msg] and params[:error_msg].empty?
        flash[:note] = params[:msg] unless params[:msg] and params[:msg].empty?

        @response = Response.find(params[:id])
        @metric = Metric.new

        # a response should already exist when viewing this page
        render nothing:true unless @response
        @all_comments = []

        # NEW change: since response already saved 
        # fetch comments from Answer model in db instead
        answers = Answer.where(response_id: @response.id)
        answers.each do |a|
        comment = a.comments
        comment.slice! "<p>"
        comment.slice! "</p>"
        @all_comments.push(comment) unless comment.empty?
        end

        
        final_hash = Hash.new
        @reviews = []
        0.upto(@all_comments.size-1) do |i|
                    hash = Hash.new
                    hash[:id] = i
                    hash[:text] = @all_comments[i]
                    @reviews.push(hash)
        end        
        final_hash[:reviews] = @reviews
        @final_hash_json = final_hash.to_json     
        




        # send user review to API for analysis
        @api_response = response_sentiments_metrics(final_hash_json)

    end



end
