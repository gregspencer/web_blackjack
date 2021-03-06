require 'rubygems'
require 'sinatra'
require "sinatra/reloader" if development?

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
INITIAL_POT_AMOUNT = 500

helpers do
  def calculate_total(cards)
    arr = cards.map{|element| element[0]}
    total = 0
    arr.each do |a|
      if a == "Ace"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
  end
  arr.select{|element| element == "Ace"}.count.times do
    break if total <= BLACKJACK_AMOUNT
    total -= 10
    end
    total
  end

  def card_images(cards)
    value = cards[0]
    suit = cards[1]
    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image' width='10%'' height='10%''>"
  end

  def winner(msg)
  	@play_again = true
  	@show_hit_or_stay = false
    session[:player_wallet] += session[:player_bet]
  	@winner = "<strong>#{session[:player_name].capitalize} wins.</strong> #{msg}"
  end

  def loser(msg)
  	@play_again = true
  	@show_hit_or_stay = false
    session[:player_wallet] -= session[:player_bet]
  	@loser = "<strong>#{session[:player_name].capitalize} loses.</strong> #{msg}"
  end

end

before do
  @show_hit_or_stay = true
end

get '/' do
  if session[:player_name]
    erb :game
  else
      redirect '/new_player'
    end
end

get '/new_player' do
  session[:player_wallet] = INITIAL_POT_AMOUNT
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "You must enter a name."
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  redirect to '/bet'
end

get '/bet' do
  session[:player_bet] = nil
  erb :bet
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "Must make a bet."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_wallet].to_i
    @error = "You don't have that kind of money. ($#{session[:player_wallet]})"
    halt erb(:bet)
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end
get '/game' do
  session[:turn] = session[:player_name]

  session[:deck] = ['2', '3', '4',  '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace'].product(['Diamonds', 'Spades', 'Hearts', 'Clubs']).shuffle!
  
  session[:player_cards] =[]
  session[:player_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  session[:dealer_cards] =[]
  session[:dealer_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop

  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
  	winner("#{session[:player_name].capitalize} hit blackjack.")
    session[:turn] = "Dealer"
  elsif calculate_total(session[:player_cards]) > 21
    loser("#{session[:player_name].capitalize} busted.")
  end

  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == BLACKJACK_AMOUNT
  	loser("Dealer hit blackjack.")
    session[:turn] = "Dealer"
  elsif dealer_total > BLACKJACK_AMOUNT
  	winner("Dealer busted.")
    session[:turn] = "Dealer"
  end
  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == BLACKJACK_AMOUNT
  	winner("#{session[:player_name].capitalize} hit blackjack.")
  elsif calculate_total(session[:player_cards]) > 21
  	loser("#{session[:player_name].capitalize} busted.")
  end
  erb :game, layout: false
end

post '/game/player/stay' do
  @show_hit_or_stay = false
  @success = "You chose to stay"
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "Dealer"
  @show_hit_or_stay = false
  dealer_total = calculate_total(session[:dealer_cards])
  if dealer_total == BLACKJACK_AMOUNT
  	loser("Dealer hit blackjack.")
    session[:turn] = "Dealer"
  elsif dealer_total > BLACKJACK_AMOUNT
  	winner("Dealer busted.")
  elsif dealer_total >= DEALER_MIN_HIT # dealer stays
    redirect '/game/compare'
  else # dealer hits
    @show_dealer_hit_btn = true
  end
  erb :game
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay = false
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  if player_total < dealer_total
  	loser("#{session[:player_name].capitalize} stayed at #{player_total}. Dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
  	winner("#{session[:player_name].capitalize} stayed at #{player_total}. Dealer stayed at #{dealer_total}.")
  else
  	loser("You tied at #{player_total}. Dealer wins tie.")
  end
  erb :game
end

get "/game_over" do
  erb :game_over
end