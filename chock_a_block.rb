
require 'httparty'
require 'json'


# config parameters


file = File.read('config.json')

config = JSON.parse(file)

apikey = config["apikey"]
venue = config["venue"]
stock = config["stock"]
account = config["account"]
base_url = "https://api.stockfighter.io/ob/api"

# get the price for the last trade
response = HTTParty.get("#{base_url}/venues/#{venue}/stocks/#{stock}/quote")

last = response.parsed_response["last"].to_i

#set the limit for the order as 1 percent less than the last trade
limit = last - (last /100)


#set the order hash
order = {
  "account" => account,
  "venue" => venue,
  "symbol" => stock,
  "price" => limit,
  "direction" => "buy",
  "orderType" => "limit"
}


# execute orders until the target quantity is reached
while (quantity ||= 0) < 100000 do

  # generate a random quantity for the order
  order["qty"] = rand(100..500)
  #execute the order
  response = HTTParty.post("#{base_url}/venues/#{venue}/stocks/#{stock}/orders",
                           :body => JSON.dump(order),
                           :headers => {"X-Starfighter-Authorization" => apikey}
                           )


  # check that the order has been submited correctly
  case response.code

  # order has been placed
  when 200


    # get the status of the order
    id = response.parsed_response["id"]

    response = HTTParty.get("#{base_url}/venues/#{venue}/stocks/#{stock}/orders/#{id}", :headers => {"X-Starfighter-Authorization" => apikey})

    status = response.parsed_response["open"]


    # check the status of the order 3 times, if it's still open after 3 times
    # close the order and accept the partial fill
    while status

      count ||= 0

      response = HTTParty.get("#{base_url}/venues/#{venue}/stocks/#{stock}/orders/#{id}",
                              :headers => {"X-Starfighter-Authorization" => apikey})

      status = response.parsed_response["open"]

      puts "The order #{id} is still open"

      count += 1
        #order has been checked 3 times
        if count.equal?(3)
          # close the order
          response = HTTParty.delete("#{base_url}/venues/#{venue}/stocks/#{stock}/orders/#{id}",
                                    :headers => {"X-Starfighter-Authorization" => apikey})
          count = 0

          break

        end

    end

    puts "The order #{id} is closed"


    #update the quantity
    quantity += response.parsed_response["totalFilled"].to_i

    puts "Quantity: #{quantity}"


  # Order has not been placed
  else

    puts response

  end


end

puts "#{quantity} stocks has been ordered"



