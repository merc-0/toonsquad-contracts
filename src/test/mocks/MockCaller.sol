// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "../../BaseToken.sol";
import "../../Minter.sol";

contract MockCaller {

    function setTokenUri(BaseToken tokenContact, uint256 tokenId, string calldata newTokenURI) public {
        tokenContact.setTokenURI(tokenId, newTokenURI);
    }

    function setBaseUri(BaseToken tokenContact, string calldata newTokenURI) public {
        tokenContact.setBaseURI(newTokenURI);
    }

    function burnOne(BaseToken tokenContact, uint256 id) public {
        tokenContact.burn(id);
    }

    function minterReserve(Minter minter, uint256 numToMint) public {
        minter.reserveTokens(numToMint);
    }

    function grantMinter(BaseToken tokenContact) public {
        tokenContact.grantRole(tokenContact.MINTER_ROLE(), address(this));
    }

    function mintOnToken(BaseToken tokenContact) public {
        tokenContact.mint(address(this));
    }

    function mintOnMinter(Minter mintingContact, uint256 numberToMint) public {
        mintingContact.mint(numberToMint);
    }
}