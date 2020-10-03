pragma solidity ^0.7.0;

/// @notice DividendTokens to map [token] => [enabled]
// SPDX-License-Identifier: GPLv2
library DividendTokens {
    struct DividendToken {
        uint timestamp;
        uint index;
        address token;
        bool enabled;
    }
    struct Data {
        bool initialised;
        mapping(address => DividendToken) entries;
        address[] index;
    }

    event DividendTokenAdded(address indexed token, bool enabled);
    event DividendTokenRemoved(address indexed token);
    event DividendTokenUpdated(address indexed token, bool enabled);

    function init(Data storage self) internal {
        require(!self.initialised);
        self.initialised = true;
    }
    function add(Data storage self, address token, bool enabled) internal {
        require(self.entries[token].timestamp == 0, "DividendToken.add: Cannot add duplicate");
        self.index.push(token);
        self.entries[token] = DividendToken(block.timestamp, self.index.length - 1, token, enabled);
        emit DividendTokenAdded(token, enabled);
    }
    function remove(Data storage self, address token) internal {
        require(self.entries[token].timestamp > 0, "DividendToken.update: Address not registered");
        uint removeIndex = self.entries[token].index;
        emit DividendTokenRemoved(token);
        uint lastIndex = self.index.length - 1;
        address lastIndexKey = self.index[lastIndex];
        self.index[removeIndex] = lastIndexKey;
        self.entries[lastIndexKey].index = removeIndex;
        delete self.entries[token];
        if (self.index.length > 0) {
            self.index.pop();
        }
    }
    function update(Data storage self, address token, bool enabled) internal {
        DividendToken storage entry = self.entries[token];
        require(entry.timestamp > 0, "DividendToken.update: Address not registered");
        entry.timestamp = block.timestamp;
        entry.enabled = enabled;
        emit DividendTokenUpdated(token, enabled);
    }
    function length(Data storage self) internal view returns (uint) {
        return self.index.length;
    }
}
