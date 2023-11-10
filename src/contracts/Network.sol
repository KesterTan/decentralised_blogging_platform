pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        require(counter._value > 0, "Counter: decrement overflow");
        counter._value -= 1;
    }
}

contract Medium is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    // Counter for keeping track of token IDs
    Counters.Counter private _tokenIdCounter;

    // Fee required to mint a new blog post NFT
    uint256 public mintingFee;

    // ERC-20 token used for tipping
    IERC20 public tippingToken;

    /**
     * @dev Constructor for the blogging platform contract.
     * @param name_ Name of the NFT collection.
     * @param symbol_ Symbol of the NFT collection.
     * @param mintingFee_ Fee required to mint a blog post.
     * @param tippingTokenAddress Address of the ERC-20 token used for tipping.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 mintingFee_,
        address tippingTokenAddress
    ) ERC721(name_, symbol_) {
        mintingFee = mintingFee_;
        tippingToken = IERC20(tippingTokenAddress);
    }

    /**
     * @dev Function to mint a new blog post NFT.
     * Users need to send enough MATIC to cover the minting fee.
     * @param recipient Address that will receive the minted NFT.
     * @param uri URI pointing to the blog post's metadata.
     */
    function mintBlogPost(address recipient, string memory uri) public payable {
        require(msg.value >= mintingFee, "Insufficient MATIC sent for minting.");

        // Transfer the minting fee to the owner of the contract
        payable(owner()).transfer(mintingFee);

        // Mint the NFT
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId, uri);

        // Refund any MATIC sent above the required minting fee
        uint256 excessAmount = msg.value - mintingFee;
        if (excessAmount > 0) {
            payable(msg.sender).transfer(excessAmount);
        }
    }

    /**
     * @dev Function to tip a blog post creator with ERC-20 tokens.
     * The caller must have enough ERC-20 tokens and must have given the contract
     * an allowance to transfer these tokens on their behalf.
     * @param tokenId Token ID of the NFT representing the blog post.
     * @param amount Amount of ERC-20 tokens to tip.
     */
    function tipBlogPostCreator(uint256 tokenId, uint256 amount) external {
        require(_exists(tokenId), "Blog post with this ID does not exist.");
        
        // Get the creator's address (owner of the NFT)
        address creator = ownerOf(tokenId);

        // Transfer ERC-20 tokens from the tipper to the creator
        require(tippingToken.transferFrom(msg.sender, creator, amount), "Failed to transfer ERC-20 tokens.");
    }

    // Overridden function from ERC721URIStorage to burn a token
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    // Overridden function from ERC721URIStorage to get a token's URI
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
