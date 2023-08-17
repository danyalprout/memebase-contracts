// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "forge-std/Test.sol";
import "../src/MemebaseCollection.sol";
import "contracts/extension/interface/ISignatureMintERC1155.sol";

contract MemebaseCollectionTest is Test {
    uint256 internal defaultEditionSize = 100;

    uint160 internal ownerPrivateKey = 1;
    address internal owner;

    uint160 internal alicePrivateKey = 2;
    address internal alice;

    uint160 internal bobPrivateKey = 3;
    address internal bob;

    uint256 internal constant NEW_TOKEN = type(uint256).max;
    uint256 internal requestId = 0;

    MemebaseCollection internal collection;

    bytes32 internal immutable typehashMintRequest = keccak256(
        "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,uint256 tokenId,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
    );

    function setUp() public virtual {
        owner = vm.addr(ownerPrivateKey);
        vm.label(alice, "owner");

        alice = vm.addr(alicePrivateKey);
        vm.label(alice, "alice");

        bob = vm.addr(bobPrivateKey);
        vm.label(bob, "bob");

        vm.prank(owner);
        collection = new MemebaseCollection(
            owner,
            defaultEditionSize,
            "Drake Meme",
            "DRAKE"
        );
    }

    function _domainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("SignatureMintERC1155")),
                keccak256(bytes("1")),
                block.chainid,
                address(collection)
            )
        );
    }

    function _encodeRequest(ERC1155SignatureMint.MintRequest memory _request) internal view returns (bytes memory) {
        return abi.encode(
            typehashMintRequest,
            _request.to,
            _request.royaltyRecipient,
            _request.royaltyBps,
            _request.primarySaleRecipient,
            _request.tokenId,
            keccak256(bytes(_request.uri)),
            _request.quantity,
            _request.pricePerToken,
            _request.currency,
            _request.validityStartTimestamp,
            _request.validityEndTimestamp,
            _request.uid
        );
    }

    function _signMintRequest(ERC1155SignatureMint.MintRequest memory _request, uint256 privateKey)
        internal
        view
        returns (bytes memory)
    {
        bytes memory encodedRequest = _encodeRequest(_request);
        bytes32 structHash = keccak256(encodedRequest);
        bytes32 typedDataHash = keccak256(abi.encodePacked("\x19\x01", _domainSeparator(), structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, typedDataHash);
        bytes memory sig = abi.encodePacked(r, s, v);

        return sig;
    }

    function _mintMeme(address toUser, uint256 tokenId, uint256 quantity) internal {
        ISignatureMintERC1155.MintRequest memory request = ISignatureMintERC1155.MintRequest(
            toUser,
            address(0),
            0,
            address(0),
            tokenId,
            "uri",
            quantity,
            0,
            address(0),
            0,
            type(uint128).max,
            bytes32(requestId)
        );

        requestId += 1;

        bytes memory signature = _signMintRequest(request, ownerPrivateKey);
        collection.mintWithSignature(request, signature);
    }

    function _createMeme(address toUser, uint256 quantity) internal returns (uint256) {
        uint256 memeId = collection.nextTokenIdToMint();
        _mintMeme(toUser, NEW_TOKEN, quantity);
        return memeId;
    }

    function testCreatingMeme() public {
        assertEq(collection.balanceOf(alice, collection.nextTokenIdToMint()), 0);
        assertEq(collection.balanceOf(bob, collection.nextTokenIdToMint()), 0);
        assertEq(collection.mintCounts(collection.nextTokenIdToMint()), 0);

        uint256 memeId = _createMeme(alice, 1);
        assertEq(collection.balanceOf(alice, memeId), 1);
        assertEq(collection.balanceOf(bob, memeId), 0);
        assertEq(collection.mintCounts(memeId), 1);
    }

    function testMintingMeme() public {
        uint256 memeId = _createMeme(alice, 1);
        _mintMeme(alice, memeId, 2);
        _mintMeme(bob, memeId, 10);

        assertEq(collection.mintCounts(memeId), 13);
        assertEq(collection.balanceOf(bob, memeId), 10);
        assertEq(collection.balanceOf(alice, memeId), 3);
    }

    function testCreatingMemeWithTooManyMints() public {
        _createMeme(alice, defaultEditionSize - 1);
        _createMeme(alice, defaultEditionSize);
        // Errors as too many initial mints. Split into two calls for revert checking to work
        collection.nextTokenIdToMint();
        vm.expectRevert(MemebaseCollection.TooManyMints.selector);
        _mintMeme(alice, NEW_TOKEN, defaultEditionSize + 1);
    }

    function testMintingErrorsWhenTooMany() public {
        // Works as equal to amount
        uint256 memeId = _createMeme(alice, defaultEditionSize - 1);
        _mintMeme(alice, memeId, 1);

        memeId = _createMeme(alice, defaultEditionSize - 1);
        vm.expectRevert(MemebaseCollection.TooManyMints.selector);
        _mintMeme(alice, memeId, 2);
    }

    function testBurningDoesNotImpactMintCount() public {
        uint256 memeId = _createMeme(alice, 10);

        assertEq(collection.mintCounts(memeId), 10);

        vm.prank(alice);
        collection.burn(alice, memeId, 10);

        assertEq(collection.mintCounts(memeId), 10);
    }
}
