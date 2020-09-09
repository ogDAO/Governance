pragma solidity ^0.7.0;

/// @notice Ownership
contract Owned {
    bool initialised;
    address public owner;
    address public newOwner;

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
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
