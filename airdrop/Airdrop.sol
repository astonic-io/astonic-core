// SPDX-License-Identifier: MIT
pragma solidity ^0.4.23;

import "./curve/Curve.sol";
import "./Base64.sol";
import "./SafeMath.sol";

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address to, uint256 value) public returns (bool success);
    function transferFrom(address from, address to, uint256 value) public returns (bool success);

    function balanceOf(address who) public view returns (uint256 balance);
    function allowance(address owner, address spender) public view returns (uint256 remaining);

    function approve(address spender, uint256 value) public returns (bool success);
}

contract AirdropVerifier {
    using SafeMath for uint256;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public airdropAmount;
    mapping(address => uint256) public airdropAmountCosmos;
    address private owner;
    address private airgrabAddress;

    address public constant airdropTokenAddress = 0x1234567891234567891234567891234567891234;

    address public constant secp256k1CurveAddress = 0x9e0BC6DB02E5aF99b8868f0b732eb45c956B92dD;
    CurveInterface secp256k1Curve = CurveInterface(secp256k1CurveAddress);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAirgrab() {
        require(msg.sender == airgrabAddress);
        _;
    }

    constructor(address[] memory eligibleAddresses, uint256[] memory amounts) public {
        require(eligibleAddresses.length == amounts.length);
        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            airdropAmount[eligibleAddresses[i]] = amounts[i];
        }
        owner = msg.sender;
    }

    function setAirgrabAddress(address _airgrabAddress) public onlyOwner {
        airgrabAddress = _airgrabAddress;
    }

    function isEligible(address addr) public view returns (bool) {
        return airdropAmount[addr] > 0 || airdropAmountCosmos[addr] > 0;
    }

    function addEligibleAddresses(address[] memory eligibleAddresses, uint256[] memory amounts) public onlyOwner {
        require(eligibleAddresses.length == amounts.length);
        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            airdropAmount[eligibleAddresses[i]] = airdropAmount[eligibleAddresses[i]].add(amounts[i]);
        }
    }

    function addEligibleCosmosAddresses(address[] memory eligibleAddresses, uint256[] memory amounts) public onlyOwner {
        require(eligibleAddresses.length == amounts.length);
        for (uint256 i = 0; i < eligibleAddresses.length; i++) {
            airdropAmountCosmos[eligibleAddresses[i]] = airdropAmountCosmos[eligibleAddresses[i]].add(amounts[i]);
        }
    }

    function addressToString(address _address) public pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(40);

        for(uint i = 0; i < 20; i++) {
            _string[0+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[1+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    function appendString(string memory a, string memory b) public pure returns (string memory) {
        return string(abi.encodePacked(a,b));
    }

    function verifyMessageHash(bytes32 messageHash, address destinationAddress, string bech32Address) public pure returns (bool) {
        bytes memory addressBytes  = bytes(addressToString(destinationAddress));
        string memory message = appendString('{"account_number":"0","chain_id":"","fee":{"amount":[],"gas":"0"},"memo":"","msgs":[{"type":"sign/MsgSignData","value":{"data":"',Base64.encode(addressBytes));
        message = appendString(message, '","signer":"');
        message = appendString(message, bech32Address);
        message = appendString(message, '"}}],"sequence":"0"}');
        return messageHash == sha256(bytes(message));
    }

    function verifySecp256k1Signature(bytes32 message, uint[2] signature, uint[2] pubkey, address destinationAddress, string bech32Address) public view returns (bool) {
        return (verifyMessageHash(message, destinationAddress, bech32Address) && secp256k1Curve.validateSignature(message, signature, pubkey));
    }

    function convertUncompressedPubKey(uint[2] pubkey) public pure returns (bytes20) {
        bytes20 ripemdAddr;
        uint x = pubkey[0];
        bytes memory pubkeyx = new bytes(32);
        assembly {
            mstore(add(pubkeyx, 32), x)
        }
        if(pubkey[1] % 2 == 0) {
            bytes memory resultEven = new bytes(33);
            resultEven[0] = 0x02;
            for(uint f = 0; f < pubkeyx.length; f++) {
                resultEven[f+1] = pubkeyx[f];
            }

            bytes32 resultEvenSha256 = sha256(resultEven);
            ripemdAddr = ripemd160(sha256(resultEvenSha256));
        } else {
            bytes memory resultOdd = new bytes(33);
            resultOdd[0] = 0x03;
            for(uint i = 0; i < pubkeyx.length; i++) {
                resultOdd[i+1] = pubkeyx[i];
            }

            bytes32 resultOddSha256 = sha256(resultOdd);
            ripemdAddr = ripemd160(resultOddSha256);
        }

        return ripemdAddr;
    }

    function claimAmount(address claimAddr) public view returns(uint256) {
        return airdropAmount[claimAddr];
    }

    function claimAmountCosmos(address claimAddr) public view returns(uint256) {
        return airdropAmountCosmos[claimAddr];
    }

    function claimAirdropCosmos(bytes32 message, uint[2] signature, uint[2] pubkey, address destinationAddress, string bech32Address) public onlyAirgrab returns(uint256) {
        address claimAddress = address(convertUncompressedPubKey(pubkey));
        require(isEligible(claimAddress));
        require(verifySecp256k1Signature(message, signature, pubkey, destinationAddress, bech32Address));

        uint256 balanceBefore = airdropAmountCosmos[claimAddress];
        airdropAmountCosmos[claimAddress] = 0;
        return balanceBefore;
    }

    function claimAirdrop(address destination) public onlyAirgrab returns (uint256) {
        require(isEligible(destination));
        uint256 balanceBefore = airdropAmount[destination];
        airdropAmount[destination] = 0;
        return balanceBefore;
    }
}
