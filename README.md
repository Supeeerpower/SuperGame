# Hats Challenge #1

## Task: obtain the flag

`Game.sol` encodes a fighting game:

- anyone can join the game calling `game.join()`
- on joining, a player receives a deck of 3 pseudo-random Mons
- each Mon is an NFT, and each Mon has powers: FIRE; WATER; AIR and SPEED, each with a value in a range from [0,9]
- users can try to improve their deck by swapping their mons with other users, or by exchaing a Mon for a randomly generated new one
- for a swap to succeed, another player must put of one of their Mons for sale
- at each moment, one player holds the flag
- other players can try to capture the flag by fighting the flag holder and pitting their deck against the flag holders
- Fight between single Mons: can fight in one of the elements, the monster with the highest value in that element wins. If the score is the same, the fastest monster wins.
- A fight between two decks consists of pairing the three Mons of the challenger with the 3 Mons of the flag holder, pseudo-randomly choosing 3 elements, and then having the 3 paris fight in each of these elements

## THE HATS CHALLENGE:

- Obtain the flag: i.e. `game.flag()` should return an address that you control
