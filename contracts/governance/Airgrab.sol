// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable immutable-vars-naming, gas-custom-errors
pragma solidity 0.8.18;

import { IERC20 } from "openzeppelin-contracts-next/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "openzeppelin-contracts-next/contracts/token/ERC20/utils/SafeERC20.sol";
import { ECDSA } from "openzeppelin-contracts-next/contracts/utils/cryptography/ECDSA.sol";
import { SignatureChecker } from "openzeppelin-contracts-next/contracts/utils/cryptography/SignatureChecker.sol";
import { Strings } from "openzeppelin-contracts-next/contracts/utils/Strings.sol";
import { ReentrancyGuard } from "openzeppelin-contracts-next/contracts/security/ReentrancyGuard.sol";

import { ILocking } from "./locking/interfaces/ILocking.sol";

interface AirdropVerifier {
  function claimAmount(address claimAddr) external view returns(uint256);
  function claimAmountCosmos(address claimAddr) external view returns(uint256);
  function claimAirdropCosmos(bytes32 message, uint[2] memory signature, uint[2] memory pubkey, address destinationAddress, string memory bech32Address) external returns(uint256);
  function claimAirdrop(address destination) external returns (uint256);
  function isEligible(address addr) external view returns (bool);
}

/**
 * @title Airgrab
 * @author Astonic Labs
 * @notice This contract implements a token airgrab.
 * The airgrab also forces claimers to immediately lock their tokens as veTokens for a
 * predetermined period.
 */
contract Airgrab is ReentrancyGuard {
  using SafeERC20 for IERC20;

  uint32 public constant MAX_CLIFF_PERIOD = 103;
  uint32 public constant MAX_SLOPE_PERIOD = 104;

  /**
   * @notice Emitted when tokens are claimed
   * @param claimer The account claiming the tokens
   * @param amount The amount of tokens being claimed
   * @param lockId The ID of the resulting veAstonic lock
   */
  event TokensClaimed(address indexed claimer, uint256 amount, uint256 lockId);

  /**
   * @notice Emitted when tokens are drained
   * @param token The token addresses that was drained
   * @param amount The amount drained
   */
  event TokensDrained(address indexed token, uint256 amount);

  uint256 public immutable endTimestamp;
  /// @notice The slope period that the airgrab will be locked for.
  uint32 public immutable slopePeriod;
  /// @notice The cliff period that the airgrab will be locked for.
  uint32 public immutable cliffPeriod;
  /// @notice The token in the airgrab.
  IERC20 public immutable token;
  /// @notice The locking contract for veToken.
  ILocking public immutable locking;
  /// @notice The Astonic Treasury address where unclaimed tokens will be refunded to.
  address payable public immutable astonicTreasury;

  address public airdropVerifier = address(0);


  /**
   * @dev Check if the account can claim
   * @notice This modifier checks if the airgrab is still active and
   * if the account hasn't already claimed.
   * @param account The address of the account to check.
   */
  modifier canClaim(address account) {
    require(block.timestamp <= endTimestamp, "Airgrab: finished");
    _;
  }

  modifier onlyDeployer() {
    require(msg.sender == address(0xe7aB5A40b8Ef85Fa3ff91EEc6444f4472F616887), "Airgrab: not deployer");
    _;
  }

  /**
   * @dev Constructor for the Airgrab contract.
   * @notice It checks and configures all immutable params
   * @param endTimestamp_ The timestamp when the airgrab ends.
   * @param cliffPeriod_ The cliff period that the airgrab will be locked for.
   * @param slopePeriod_ The slope period that the airgrab will be locked for.
   * @param token_ The token address in the airgrab.
   * @param locking_ The locking contract for veToken.
   * @param astonicTreasury_ The Astonic Treasury address where unclaimed tokens will be refunded to.
   */
  constructor(
    uint256 endTimestamp_,
    uint32 cliffPeriod_,
    uint32 slopePeriod_,
    address token_,
    address locking_,
    address airdropVerifier_,
    address payable astonicTreasury_
  ) {
    require(endTimestamp_ > block.timestamp, "Airgrab: invalid end timestamp");
    require(cliffPeriod_ <= MAX_CLIFF_PERIOD, "Airgrab: cliff period too large");
    require(slopePeriod_ <= MAX_SLOPE_PERIOD, "Airgrab: slope period too large");
    require(airdropVerifier_ != address(0), "Airgrab: invalid airdrop verifier");
    require(token_ != address(0), "Airgrab: invalid token");
    require(locking_ != address(0), "Airgrab: invalid locking");
    require(astonicTreasury_ != address(0), "Airgrab: invalid Astonic Treasury");

    endTimestamp = endTimestamp_;
    cliffPeriod = cliffPeriod_;
    slopePeriod = slopePeriod_;
    airdropVerifier = airdropVerifier_;
    token = IERC20(token_);
    locking = ILocking(locking_);
    astonicTreasury = astonicTreasury_;

    require(token.approve(locking_, type(uint256).max), "Airgrab: approval failed");
  }

  /**
   * @dev Allows `msg.sender` to claim `amount` tokens if the merkle proof and kyc is valid.
   * @notice This function can be called by anybody, but the (msg.sender, amount) pair
   * must be in the merkle tree, has to not have claimed yet, and must have
   * an associated KYC signature from Fractal. And the airgrab must not have ended.
   * The tokens will be locked for the cliff and slope configured at the contract level.
   * @param delegate The address of the account that gets voting power delegated
   */
  function claim(
    address delegate
  ) external canClaim(msg.sender) nonReentrant {
    uint256 amount = AirdropVerifier(airdropVerifier).claimAirdrop(msg.sender);
    require(token.balanceOf(address(this)) >= amount, "Airgrab: insufficient balance");
    _claim(uint96(amount), delegate);
  }

  function claimCosmos(
    bytes32 message, uint[2] memory signature, uint[2] memory pubkey, address destinationAddress, string memory bech32Address
  ) external canClaim(msg.sender) nonReentrant {
    uint256 amount = AirdropVerifier(airdropVerifier).claimAirdropCosmos(message, signature, pubkey, destinationAddress, bech32Address);
    require(token.balanceOf(address(this)) >= amount, "Airgrab: insufficient balance");
    _claim(uint96(amount), destinationAddress);
  }

  /**
   * @dev Internal function to claim tokens and lock them.
   * @param amount The amount of tokens to be claimed.
   * @param delegate The address of the account that gets voting power delegated
   */
  function _claim(uint96 amount, address delegate) internal {
    uint256 lockId = locking.lock(msg.sender, delegate, uint96(amount), slopePeriod, cliffPeriod);
    emit TokensClaimed(msg.sender, amount, lockId);
  }

  /**
   * @dev Allows the Astonic Treasury to reclaim any tokens after the airgrab has ended.
   * @notice This function can only be called after the airgrab has ended.
   * @param tokenToDrain Token is parameterized in case the contract has been sent
   *  tokens other than the airgrab token.
   */
  function drain(address tokenToDrain) external nonReentrant {
    require(block.timestamp > endTimestamp, "Airgrab: not finished");
    uint256 balance = IERC20(tokenToDrain).balanceOf(address(this));
    require(balance > 0, "Airgrab: nothing to drain");
    IERC20(tokenToDrain).safeTransfer(astonicTreasury, balance);
    emit TokensDrained(tokenToDrain, balance);
  }

  function setAirdropVerifier(address _airdropVerifier) external onlyDeployer {
    airdropVerifier = _airdropVerifier;
  }
}
