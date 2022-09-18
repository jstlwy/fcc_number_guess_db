#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align --csv -c"

echo "Enter your username:"
read USERNAME
while [[ ! $USERNAME =~ ^[a-zA-Z0-9_]+$ || ${#USERNAME} -gt 30 ]]
do
  echo "Usernames may only contain letters, numbers, and underscores, and they must be no greater than 30 characters in length."
  echo "Please enter a valid username:"
  read USERNAME
done

# Try to find the user in the database
USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
if [[ -n $USER_ID ]]; then
  # If the user exists, get the user's stats
  STAT_LOOKUP_RESULT=$($PSQL "SELECT COUNT(*), MIN(guesses) FROM games WHERE user_id = '$USER_ID'")
  # Don't change IFS before SQL queries,
  # and be sure to reset it as soon as possible.
  OLDIFS=$IFS
  IFS=","
  USER_STATS=($STAT_LOOKUP_RESULT)
  IFS=$OLDIFS
  echo "Welcome back, $USERNAME! You have played ${USER_STATS[0]} games, and your best game took ${USER_STATS[1]} guesses."
else
  # If the user doesn't exist, register the user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  USER_INSERT_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
fi

MAX_NUMBER=1000
SECRET_NUMBER=$(( RANDOM % $MAX_NUMBER + 1 ))
echo "Guess the secret number between 1 and $MAX_NUMBER:"
read USER_GUESS
NUM_GUESSES=1
while [[ $USER_GUESS -ne $SECRET_NUMBER ]]
do
  if [[ ! $USER_GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  else
    if [[ $USER_GUESS -lt $SECRET_NUMBER ]]; then
      echo "It's higher than that, guess again:"
    else
      echo "It's lower than that, guess again:"
    fi
    # Only increment NUM_GUESSES if the input was valid
    (( ++NUM_GUESSES ))
  fi
  read USER_GUESS
done

echo "You guessed it in $NUM_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

# Record the user's current game
GAME_INSERT_RESULT=$($PSQL "INSERT INTO games(user_id, guesses) VALUES('$USER_ID', $NUM_GUESSES)")
