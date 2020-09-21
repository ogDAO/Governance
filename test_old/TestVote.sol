pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// ----------------------------------------------------------------------------
// Optino Governance Token
//
// Enjoy. (c) The Optino Project 2020
//
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

contract TestVote {

    string public constant name = "Optino Gov";
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");
    bytes32 public constant EIP712_VOTE_TYPEHASH = keccak256("Vote(uint256 proposalId,uint256 value)");
    bytes public constant SIGNING_PREFIX = "\x19Ethereum Signed Message:\n32";

    event Voted(address voter, uint proposalId, uint value);

    // ------------------------------------------------------------------------
    // ecrecover from a signature rather than the signature in parts [v, r, s]
    // The signature format is a compact form {bytes32 r}{bytes32 s}{uint8 v}.
    // Compact means, uint8 is not padded to 32 bytes.
    //
    // An invalid signature results in the address(0) being returned, make
    // sure that the returned result is checked to be non-zero for validity
    //
    // Parts from https://gist.github.com/axic/5b33912c6f61ae6fd96d6c4a47afde6d
    // ------------------------------------------------------------------------
    function ecrecoverFromSig(bytes32 hash, bytes memory sig) public pure returns (address recoveredAddress) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (sig.length != 65) return address(0);
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            // Here we are loading the last 32 bytes. We exploit the fact that 'mload' will pad with zeroes if we overread.
            // There is no 'mload8' to do this, but that would be nicer.
            v := byte(0, mload(add(sig, 96)))
        }
        // Albeit non-transactional signatures are not specified by the YP, one would expect it to match the YP range of [27, 28]
        // geth uses [0, 1] and some clients have followed. This might change, see https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
          v += 27;
        }
        if (v != 27 && v != 28) return address(0);
        return ecrecover(hash, v, r, s);
    }


    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function vote(uint proposalId, uint value) public {
        /* return */ _vote(msg.sender, proposalId, value);
    }

    function voteBySig(uint proposalId, uint value, bytes memory sig) public {
        bytes32 digest = voteDigest(proposalId, value);
        // EIP-712 address voter = ecrecoverFromSig(digest, sig);
        // web3js 0.x go-ethereum
        address voter = ecrecoverFromSig(keccak256(abi.encodePacked(SIGNING_PREFIX, digest)), sig);
        require(voter != address(0), "OptinoGov::voteBySig: invalid signature");
        /* return */ _vote(voter, proposalId, value);
    }

    function voteBySigs(uint proposalId, uint[] memory values, bytes[] memory sigs) public {
        require(values.length == sigs.length);
        for (uint i = 0; i < values.length; i++) {
            uint value = values[i];
            bytes memory sig = sigs[i];
            bytes32 digest = voteDigest(proposalId, value);
            // EIP-712 address voter = ecrecoverFromSig(digest, sig);
            // web3js 0.x go-ethereum
            address voter = ecrecoverFromSig(keccak256(abi.encodePacked(SIGNING_PREFIX, digest)), sig);
            require(voter != address(0), "OptinoGov::voteBySig: invalid signature");
            /* return */ _vote(voter, proposalId, value);
        }
    }

    function voteDigest(uint proposalId, uint value) public view returns (bytes32 digest) {
        bytes32 domainSeparator = keccak256(abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(EIP712_VOTE_TYPEHASH, proposalId, value));
        digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }


    function _vote(address voter, uint proposalId, uint value) internal {
        emit Voted(voter, proposalId, value);
        // require(state(proposalId) == ProposalState.Active, "GovernorAlpha::_castVote: voting is closed");
        // Proposal storage proposal = proposals[proposalId];
        // Receipt storage receipt = proposal.receipts[voter];
        // require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");
        // uint96 votes = comp.getPriorVotes(voter, proposal.startBlock);

        // if (support) {
        //     proposal.forVotes = add256(proposal.forVotes, votes);
        // } else {
        //     proposal.againstVotes = add256(proposal.againstVotes, votes);
        // }

        // receipt.hasVoted = true;
        // receipt.support = support;
        // receipt.votes = votes;

        // emit VoteCast(voter, proposalId, support, votes);
    }

    // function voteHash(address tokenOwner, uint vote) public view returns (bytes32 hash) {
    //     hash = keccak256(signedTransferSig, address(this), tokenOwner, to, tokens, fee, nonce);
    // }



}
