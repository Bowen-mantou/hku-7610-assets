// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title ClubToken (CPT) - HKU Drone Club points token
/// @notice ERC-20 token. 1000 CPT are minted in one batch at deployment.
///         Only club administrators (owner) can mint/distribute additional points.
///         The Campus-Memo NFT contract is authorized to mint refunds (see CampusMemo.redeem).
contract ClubToken is ERC20, ERC20Burnable, Ownable {
    /// @notice Initial club points minted to the deployer in one batch.
    uint256 public constant INITIAL_SUPPLY = 1000 * 10 ** 18;

    /// @notice The Campus-Memo contract authorized to mint CPT refunds.
    address public nftContract;

    event NftContractSet(address indexed nftContract);

    constructor() ERC20("Club Points Token", "CPT") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    /// @notice Club administrators mint/distribute additional points to a member.
    function distribute(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "ClubToken: zero address");
        _mint(to, amount);
    }

    /// @notice Owner registers the Campus-Memo contract as the only caller of mintRefund.
    function setNftContract(address _nftContract) external onlyOwner {
        nftContract = _nftContract;
        emit NftContractSet(_nftContract);
    }

    /// @notice Called by CampusMemo.redeem() to refund CPT to a member who
    ///         surrenders a commemorative NFT. Callable only by the NFT contract.
    function mintRefund(address to, uint256 amount) external {
        require(msg.sender == nftContract, "ClubToken: only NFT contract");
        _mint(to, amount);
    }
}
