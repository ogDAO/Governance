pragma solidity ^0.7.0;

// ----------------------------------------------------------------------------
// Collect Optino Governance tokens based on POAP tokenEvents
//
// Enjoy. (c) The Optino Project 2020
//
// SPDX-License-Identifier: GPLv2
// ----------------------------------------------------------------------------

// import "Owned.sol";
/// @notice Ownership
contract Owned {
    bool initialised;
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function initOwned(address _owner) internal {
        require(!initialised, "Already initialised");
        owner = address(uint160(_owner));
        initialised = true;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


// import "SafeMath.sol";
/// @notice Safe maths
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "Add overflow");
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "Sub underflow");
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "Mul overflow");
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "Divide by 0");
        c = a / b;
    }
}


// import "ERC20.sol";
/// @notice ERC20 https://eips.ethereum.org/EIPS/eip-20 with optional symbol, name and decimals
interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// import "OGTokenInterface.sol";
/// @notice OGTokenInterface = ERC20 + mint + burn
interface OGTokenInterface is ERC20 {
    function mint(address tokenOwner, uint tokens) external returns (bool success);
    function burn(uint tokens) external returns (bool success);
    // function burnFrom(address tokenOwner, uint tokens) external returns (bool success);
}


interface POAP {
    function ownerOf(uint256 tokenId) external view returns (address);
    function tokenEvent(uint256 tokenId) external view returns (uint256);
}


contract POAPCollection is Owned {
    OGTokenInterface public ogToken;
    POAP public poap;
    // tokenEvent => number of tokens to mint
    mapping(uint => uint) tokenEvents;
    // tokenId => collected?
    mapping(uint => bool) collected;

    // POAP @ 0x22C1f6050E56d2876009903609a2cC3fEf83B415 Mainnet, 0x50C5CA3e7f5566dA3Aa64eC687D283fdBEC2A2F2 Ropsten
    constructor(OGTokenInterface _ogToken, POAP _poap) {
        initOwned(msg.sender);
        ogToken = _ogToken;
        poap = _poap;
    }

    function addTokenEvents(uint _tokenEvent, uint _tokensToMint) public onlyOwner {
        tokenEvents[_tokenEvent] = _tokensToMint;
    }

    function collect(uint _tokenId) public {
        uint _tokenEvent = poap.tokenEvent(_tokenId);
        require(tokenEvents[_tokenEvent] > 0, "Invalid token event");
        require(msg.sender == poap.ownerOf(_tokenId), "Not owner of POAP token");
        require(!collected[_tokenId], "Already collected");
        collected[_tokenId] = true;
        require(ogToken.mint(msg.sender, tokenEvents[_tokenEvent]), "Mint failed");
    }
}
