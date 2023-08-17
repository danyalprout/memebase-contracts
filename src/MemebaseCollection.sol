// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "contracts/base/ERC1155SignatureMint.sol";

contract MemebaseCollection is ERC1155SignatureMint {
    error TooManyMints();

    uint256 public immutable EDITION_SIZE;
    mapping(uint256 => uint256) public mintCounts;

    constructor(address _owner, uint256 _editionSize, string memory _name, string memory _symbol)
        ERC1155SignatureMint(_owner, _name, _symbol, address(0), 0, address(0))
    {
        EDITION_SIZE = _editionSize;
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory
    ) internal virtual override {
        // Mints are modelled as transfers from address(0)
        if (address(0) == from) {
            uint256 length = ids.length;

            for (uint256 i; i < length;) {
                _incrementAndCheckMintCounts(ids[i], amounts[i]);
                unchecked {
                    ++i;
                }
            }
        }
    }

    function _incrementAndCheckMintCounts(uint256 _id, uint256 _amount) internal {
        mintCounts[_id] += _amount;
        if (mintCounts[_id] > EDITION_SIZE) {
            revert TooManyMints();
        }
    }
}
