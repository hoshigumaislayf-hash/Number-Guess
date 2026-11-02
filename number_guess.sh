#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME

USERNAME_ESCAPED=${USERNAME//\'/\'\'}
USER_DATA=$($PSQL "SELECT games_played || '|' || COALESCE(best_game::text, '0') FROM users WHERE username='$USERNAME_ESCAPED';")

if [[ -z $USER_DATA ]]; then
	echo "Welcome, $USERNAME! It looks like this is your first time here."
else
	IFS='|' read -r GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
	echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

echo "Guess the secret number between 1 and 1000:"
while true; do
	read GUESS
	NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))
	if [[ ! $GUESS =~ ^[0-9]+$ ]]; then
		echo "That is not an integer, guess again:"
	elif (( 10#$GUESS == SECRET_NUMBER )); then
		break
	elif (( 10#$GUESS > SECRET_NUMBER )); then
		echo "It's lower than that, guess again:"
	else
		echo "It's higher than that, guess again:"
	fi
done

echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
$PSQL "INSERT INTO users (username, games_played, best_game) VALUES ('$USERNAME_ESCAPED', 1, $NUMBER_OF_GUESSES) ON CONFLICT (username) DO UPDATE SET games_played = users.games_played + 1, best_game = LEAST(users.best_game, EXCLUDED.best_game);" >/dev/null