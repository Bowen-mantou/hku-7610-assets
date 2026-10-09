// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Minimal interface of ClubToken used by CampusMemo.
interface IClubToken {
    function burnFrom(address account, uint256 amount) external;
    function mintRefund(address to, uint256 amount) external;
}

/// @title CampusMemo - HKU Drone Club limited-edition commemorative NFT
/// @notice ERC-721 NFT. Maximum total supply is 10.
///         Minting 1 NFT consumes (burns) 100 CPT from the minter.
contract CampusMemo is ERC721, ERC721URIStorage, Ownable {
    uint256 public constant MAX_SUPPLY = 10;
    uint256 public constant PRICE = 100 * 10 ** 18;   // CPT burnt per NFT
    uint256 public constant REFUND = 80 * 10 ** 18;   // CPT refunded on redeem

    IClubToken public immutable clubToken;
    uint256 private _nextTokenId;

    event MemoMinted(address indexed to, uint256 indexed tokenId, string uri);
    event AdminMinted(address indexed to, uint256 indexed tokenId, string uri);
    event MemoRedeemed(address indexed from, uint256 indexed tokenId, uint256 refund);

    constructor(IClubToken _clubToken) ERC721("Campus-Memo", "MEMO") Ownable(msg.sender) {
        clubToken = _clubToken;
    }

    modifier belowMaxSupply() {
        require(_nextTokenId < MAX_SUPPLY, "CampusMemo: max supply reached");
        _;
    }

    /// @notice Total number of NFTs ever minted (max 10).
    ///         Burning does not free a slot: the commemorative stays scarce.
    function totalSupply() public view returns (uint256) {
        return _nextTokenId;
    }

    /// @notice A member mints 1 commemorative NFT by burning 100 CPT.
    ///         The caller must first approve() this contract for >= 100 CPT.
    function mintNFT(string memory uri) external belowMaxSupply {
        uint256 tokenId = _nextTokenId++;
        clubToken.burnFrom(msg.sender, PRICE);
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        emit MemoMinted(msg.sender, tokenId, uri);
    }

    // ---------------------------------------------------------------------
    // Custom function 1: adminMint
    // The club awards a free commemorative NFT (no CPT consumed) to winners
    // of drone competitions, e.g. the annual HKU drone-race champion.
    // Only the club administrator can call it; the 10-supply cap still applies.
    // ---------------------------------------------------------------------
    function adminMint(address to, string memory uri) external onlyOwner belowMaxSupply {
        require(to != address(0), "CampusMemo: zero address");
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit AdminMinted(to, tokenId, uri);
    }

    // ---------------------------------------------------------------------
    // Custom function 2 (headline): redeem
    // A member leaving the club can surrender (burn) their own commemorative
    // NFT and receive an 80% CPT refund. The remaining 20 CPT stays burnt as
    // the club's "consumed" cost, keeping the points economy deflationary.
    // Works in the opposite direction of the example (which burns CPT to
    // leave): here the NFT is destroyed and points are re-minted, which
    // requires a cross-contract mint authorized via ClubToken.setNftContract.
    // ---------------------------------------------------------------------
    function redeem(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "CampusMemo: not token owner");
        _burn(tokenId);
        clubToken.mintRefund(msg.sender, REFUND);
        emit MemoRedeemed(msg.sender, tokenId, REFUND);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
