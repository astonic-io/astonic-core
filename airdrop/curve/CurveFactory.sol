pragma solidity ^0.4.23;

import {Curve} from "./Curve.sol";
/**
* @title Curve factory
*
* Factory to create curve arithmetics contracts.
*
* Takes curve parameters and produces a new contract.
*
* @author Alexander Vlasov (alex.m.vlasov@gmail.com).
*/

contract GenericCurveFactory {
    event CurveCreated(address indexed newCurve);
    address[] public knownCurves;
    constructor() public {

    }

    function createSecp256k1Curve() public returns (Curve _curve) {
        return createCurve(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F,
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141,
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            1,
            [0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798,0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8],
            0,
            7
        );
    }

    function createCurve(uint256 fieldSize, uint256 groupOrder, uint256 lowSmax, uint256 cofactor, uint256[2] generator, uint256 a, uint256 b) public returns (Curve _curve) {
        _curve = new Curve(fieldSize, groupOrder, lowSmax, cofactor, generator, a, b);
        knownCurves.push(_curve);
        emit CurveCreated(_curve);
        return _curve;
    }
}
