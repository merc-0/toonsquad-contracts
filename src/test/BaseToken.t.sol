// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "./mocks/MockCaller.sol";
import "../BaseToken.sol";


contract BaseTest is DSTest {

    // contracts
    BaseToken internal baseToken;
    MockCaller internal mockCaller;
    string internal name = "Test Token";
    string internal symbol = "TT";


    function setUp() public virtual {
        baseToken = new BaseToken(name, symbol);
        mockCaller = new MockCaller();

        baseToken.grantRole(baseToken.MINTER_ROLE(), address(this));
        baseToken.setMaxSupply(50);
    }


    /* -------------------------------- Metadata -------------------------------- */

    function invariantMeta() public {
        assertEq(baseToken.name(), name);
        assertEq(baseToken.symbol(), symbol);
    }


    /* ------------------------------- Permissions ------------------------------ */

    function testPermission() public {
        assertEq(baseToken.owner(), address(this));
        assertTrue(baseToken.hasRole(baseToken.DEFAULT_ADMIN_ROLE(), address(this)));
    }

    function testSetBaseUri() public {
        baseToken.mint(address(this));

        baseToken.setBaseURI("something/");
        assertEq(baseToken.tokenURI(1), "something/1");
    }

    function testSetTokenUri() public {
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.setBaseURI("something/");
        baseToken.setTokenURI(2, "anotherthing/2");
        assertEq(baseToken.tokenURI(1), "something/1");
        assertEq(baseToken.tokenURI(2), "anotherthing/2");
    }

    function testFailSetBaseUri() public {
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        mockCaller.setBaseUri(baseToken, "somethingnew");
    }

    function testFailSetTokenUri() public {
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        mockCaller.setTokenUri(baseToken, 1, "somethingnew");
    }

    function testFailSetMinter() public {
        mockCaller.grantMinter(baseToken);
    }

    function testSetMinter() public {
        baseToken.grantRole(baseToken.MINTER_ROLE(), address(mockCaller));
        assertTrue(baseToken.hasRole(baseToken.MINTER_ROLE(), address(mockCaller)));
    }


    /* --------------------------------- Burning -------------------------------- */

    function testBurn() public {
        
        // Setup.
        baseToken.mint(address(this));
        assertEq(baseToken.balanceOf(address(this)), 1);
        assertEq(baseToken.totalSupply(), 1);
        assertEq(baseToken.totalMinted(), 1);

        // Burn.
        baseToken.burn(1);
        assertEq(baseToken.balanceOf(address(this)), 0);
        assertEq(baseToken.totalSupply(), 0);
        assertEq(baseToken.totalMinted(), 1);
        assertEq(baseToken.totalBurned(), 1);
    }

    function testBurnThenMint() public {
        
        // Setup.
        baseToken.mint(address(this));
        assertEq(baseToken.balanceOf(address(this)), 1);
        assertEq(baseToken.totalSupply(), 1);
        assertEq(baseToken.totalMinted(), 1);

        // Burn.
        baseToken.burn(1);
        assertEq(baseToken.balanceOf(address(this)), 0);
        assertEq(baseToken.totalSupply(), 0);
        assertEq(baseToken.totalMinted(), 1);
        assertEq(baseToken.totalBurned(), 1);

        // Mint again.
        baseToken.mint(address(this));
        assertEq(baseToken.balanceOf(address(this)), 1);
        assertEq(baseToken.totalSupply(), 1);
        assertEq(baseToken.totalMinted(), 2);
        assertEq(baseToken.totalBurned(), 1);

        // Burn again.
        baseToken.burn(2);
        assertEq(baseToken.balanceOf(address(this)), 0);
        assertEq(baseToken.totalSupply(), 0);
        assertEq(baseToken.totalMinted(), 2);
        assertEq(baseToken.totalBurned(), 2);
    }

    function testFailBurn() public {
        baseToken.mint(address(this));
        mockCaller.burnOne(baseToken, 1);
    }


    /* --------------------------------- Minting -------------------------------- */

    function testFailMint() public {
        mockCaller.mintOnToken(baseToken);
    }

    function testMint() public {
        baseToken.mint(address(this));
    }

    function testCounters() public {
        baseToken.mint(address(this));
        assertEq(baseToken.balanceOf(address(this)), 1);
        assertEq(baseToken.totalSupply(), 1);
        assertEq(baseToken.totalMinted(), 1);
    }

    function testMaxMint() public {

        for (uint256 index = 0; index < 50; index++) {
            baseToken.mint(address(this));
        }

        assertEq(baseToken.balanceOf(address(this)), 50);
        assertEq(baseToken.totalSupply(), 50);
        assertEq(baseToken.totalMinted(), 50);
    }

    function testFailOverMaxMint() public {
        for (uint256 index = 0; index < 51; index++) {
            baseToken.mint(address(this));
        }
    }

}