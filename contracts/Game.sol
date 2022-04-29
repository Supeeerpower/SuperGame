// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


contract Game is ERC721 {

  uint256 public totalSupply; // total amount of Mons available

  uint8 constant WATER = 0;
  uint8 constant AIR = 1;
  uint8 constant FIRE = 2;

  uint8 constant MAX_POINTS = 22;
  uint8 constant DECK_SIZE = 3;

  uint256 internal nonce = 123; // nonce used by pseudo-random generator


  // a Mon has 4 attributes
  struct Mon {
    uint8 water;
    uint8 air;
    uint8 fire;
    uint8 speed;
  }

  // a mapping from ids to Mons
  mapping(uint256 => Mon) public mons;

  // a mapping from players to their decks
  mapping(address => uint256[DECK_SIZE]) public decks;

  // a mapping from ids of Mons to booleans - if true, the Mon is for sale
  mapping(uint256 => bool) public forSale;

  // address of the flag holder
  address public flagHolder;


  constructor() ERC721("Hats Game 1", "HG1") {
    // create an unbeatable superdeck for the deployer
    Mon memory superMon = Mon(9,9,9,9);
    flagHolder = msg.sender;
    for (uint8 i; i < DECK_SIZE; i++) {
      decks[flagHolder][i] = _mintMon(flagHolder, superMon);
    }
  }
  
  // join the game and receive 3 random Mons
  function join() external returns (uint256[3] memory deck) {
    address newPlayer = msg.sender;
    require(balanceOf(newPlayer) == 0, "player already joined");

    // give the new player 3 pseudoramon Mons
    deck[0] = _mintMon(newPlayer);
    deck[1] = _mintMon(newPlayer);
    deck[2] = _mintMon(newPlayer);

    decks[newPlayer] = deck;
  }

  // fight the flagHolder with your deck
  function fight() external {
    address attacker = msg.sender;
    address opponent = flagHolder;
    uint256[3] memory deck0 = decks[msg.sender];
    uint256[3] memory deck1 = decks[opponent];

    for (uint8 i = 0; i < DECK_SIZE; i++) {
      uint8 element = randomGen(3);
      // if the first player wins, burn the Mon of the second player
      if (_fight(deck0[i], deck1[i], element)) {
        _burn(deck1[i]);
      } else {
        _burn(deck0[i]);
      }
    }

    // winner is the player with most Mons left
    if (balanceOf(attacker) > balanceOf(opponent)) {
        flagHolder = attacker;
    }

    // replenish balance of both players so they can play again
    uint256[3] memory deckAttacker = decks[attacker];
    uint256[3] memory deckOpponent = decks[opponent];
    for (uint i; i < DECK_SIZE; i++) {
      if (!_exists(deckAttacker[i])) {
        deckAttacker[i] = _mintMon(attacker);
      }
      if (!_exists(deckOpponent[i])) {
        deckOpponent[i] = _mintMon(opponent);
      }
    }
    
    decks[attacker] = deckAttacker;
    decks[opponent] = deckOpponent;
  }

  // fight _mon0 againts _mon1 in element _element
  function _fight(uint256 _mon0, uint256 _mon1, uint8 _element) internal view returns(bool) {
    assert(_element < 3);
    Mon memory mon0;
    Mon memory mon1;

    mon0 = mons[_mon0];
    mon1 = mons[_mon1];

    if (_element == WATER) {
      if (mon0.water > mon1.water) {
        return true;
      } else if (mon0.water < mon1.water) {
        return false;
      } else {
        return mon0.speed > mon1.speed;
      }
    } else if (_element == AIR) {
      if (mon0.air > mon1.air) {
        return true;
      } else if (mon0.air < mon1.air) {
        return false;
      } else {
        return mon0.speed > mon1.speed;
      }
    } else if (_element == FIRE) {
      if (mon0.fire > mon1.fire) {
        return true;
      } else if (mon0.fire < mon1.fire) {
        return false;
      } else {
        return mon0.speed > mon1.speed;
      }
    }
  }

  // put a mon up for sale
  function putUpForSale(uint256 _monId) public {
    require(ownerOf(_monId) == msg.sender, "Can only put your own mons up for sale");
    forSale[_monId] = true;
  }

  // swap your _mon1 for a _mon2 that is for sale and owned by _to
  function swap(address _to, uint256 _mon1, uint256 _mon2) external {
    address swapper = msg.sender;
    require(forSale[_mon2], "Cannot swap a Mon that is not for sale");
    require(swapper != _to, "Cannot swap a card with yourself");

    uint256 idx1 = indexInDeck(swapper, _mon1);
    uint256 idx2 = indexInDeck(_to, _mon2);

    _safeTransfer(swapper, _to, _mon1, "");
    _safeTransfer(_to, swapper, _mon2, "");

    // update the decks
    decks[swapper][idx1] = _mon2;
    decks[_to][idx2] = _mon1;

  }

  function indexInDeck(address _owner, uint256 _monId) internal view returns(uint256 idx) {
    for (uint256 i; i < DECK_SIZE; i++) {
      if (decks[_owner][i] == _monId) {
        idx = i;
      }
    }
  }


  function swapForNewCard(uint256 _mon) external {
    address swapper = msg.sender;
    uint256 idx = indexInDeck(swapper, _mon);
    _burn(_mon);
    decks[swapper][idx] = _mintMon(swapper);
  }

  function _mintMon(address _to, Mon memory mon) internal returns(uint256) {
    uint256 tokenId = totalSupply;
    totalSupply += 1;
    mons[tokenId] = mon;
    _mint(_to, tokenId);
    return tokenId;
  }

  function _mintMon(address _to) internal returns(uint256) {
    Mon memory newMon = genMon();
    return _mintMon(_to, newMon);
  }

  // generate a new Mon
  function genMon() private returns (Mon memory newMon) {
    // generate a new Mon
    uint8 fire = randomGen(10);
    uint8 water = randomGen(10);
    uint8 air = randomGen(10);
    uint8 speed;
    if (fire + water + air >= MAX_POINTS) {
      speed = 0;
    } else {
      speed = randomGen(MAX_POINTS - fire - water - air);
      if (speed > 9) {
        speed = 9;
      }
    }
    newMon = Mon(fire, water, air, speed);
  }

  // function that generates pseudorandom numbers
  function randomGen(uint256 i) private returns (uint8) {
    uint8 x = uint8(uint256(keccak256(abi.encodePacked(block.number, msg.sender, nonce))) % i);
    nonce++;
    return x;
  }
}
