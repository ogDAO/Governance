pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";

// Use prefix "./" normally and "https://github.com/ogDAO/Governance/blob/master/contracts/" in Remix
import "./SafeMath.sol";
import "./Owned.sol";
import "./CurveInterface.sol";


/// @notice Simple interpolated curve by term
// SPDX-License-Identifier: GPLv2
contract SimpleCurve is Owned, CurveInterface {
    using SafeMath for uint;

    struct Point {
        uint term;
        uint rate;
    }
    Point[] public points;
    event PointUpdated(uint index, uint term, uint rate);

    constructor(uint[] memory terms, uint[] memory rates) {
        initOwned(msg.sender);
        _addPoints(terms, rates);
    }

    function pointsLength() public view returns (uint) {
        return points.length;
    }

    function replacePoints(uint[] memory terms, uint[] memory rates) public onlyOwner {
        _addPoints(terms, rates);
    }

    function replacePoint(uint i, uint term, uint rate) public onlyOwner {
        require(i < points.length);
        // Check gas
        // delete points[i[];
        points[i] = Point(term, rate);
        emit PointUpdated(i, term, rate);
    }

    function _addPoints(uint[] memory terms, uint[] memory rates) internal {
        require(terms.length == rates.length, "Invalid data");
        delete points;
        for (uint i = 0; i < terms.length; i++) {
            if (i > 0) {
                require(terms[i-1] < terms[i], "Invalid terms");
            }
            points.push(Point(terms[i], rates[i]));
            emit PointUpdated(i, terms[i], rates[i]);
        }
    }

    function getRate(uint term) override external view returns (uint rate) {
        require(points.length > 0, "Curve empty");
        if (term <= points[0].term) {
            rate = points[0].rate;
        } else if (term >= points[points.length-1].term) {
            rate = points[points.length-1].rate;
        } else {
            for (uint i = 1; i < points.length; i++) {
                if (term == points[i].term) {
                    rate = points[i].rate;
                } else if (term > points[i-1].term && term < points[i].term) {
                    if (points[i].rate >= points[i-1].rate) {
                        rate = points[i-1].rate + (points[i].rate - points[i-1].rate) * (term - points[i-1].term) / (points[i].term - points[i-1].term);
                    } else {
                        rate = points[i-1].rate - (points[i-1].rate - points[i].rate) * (term - points[i-1].term) / (points[i].term - points[i-1].term);
                    }
                }
            }
        }
    }
}
