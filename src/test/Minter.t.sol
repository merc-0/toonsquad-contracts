// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "./mocks/MockCaller.sol";
import "../BaseToken.sol";
import "../Minter.sol";
import "./utils/Hevm.sol";


contract MinterTest is DSTest {
    Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

    // contracts
    BaseToken internal baseToken;
    Minter internal minter;
    MockCaller internal mockCaller;
    string internal name = "Test Token";
    string internal symbol = "TT";
    address[] internal payees = [
        0xaa1CF06BA699c40b2EAfb5e9bc43AC5C71EcC780,
        0xC95876d9D0E954068C2B6840d226cc9Cab5Dfc1a
    ];
    uint256[] internal shares = [75, 25];
    uint256 internal privateKey = 0xBEEF;
    address internal minterSigner = hevm.addr(privateKey);


    function signPayload(Minter mintContract, uint256 sk, address accountToMint, uint256 maxPermitted)
        internal
        returns(bytes memory)
    {
        (uint8 v, bytes32 r, bytes32 s) = hevm.sign(
            sk,
            mintContract.hashTransaction(accountToMint, maxPermitted)
        );
        return abi.encodePacked(r, s, v);
    }

    function setUp() public virtual {
        baseToken = new BaseToken(name, symbol);
        mockCaller = new MockCaller();
        minter = new Minter(address(baseToken), payees, shares);
        minter.setMintSigner(minterSigner);

        baseToken.grantRole(baseToken.MINTER_ROLE(), address(minter));
        baseToken.setMaxSupply(50);
    }

    receive() external payable { }


    /* ------------------------------- Constructor ------------------------------ */

    function testConstructorArgs() public {
        assertEq(minter.payee(0), payees[0]);
        assertEq(minter.payee(1), payees[1]);
        assertEq(minter.shares(payees[0]), shares[0]);
        assertEq(minter.shares(payees[1]), shares[1]);
        assertEq(minter.tokenContract(), address(baseToken));
    }


    /* ------------------------------- Permissions ------------------------------ */

    function testPermission() public {
        assertTrue(minter.hasRole(minter.ADMIN_ROLE(), address(this)));
    }


    /* ----------------------------- Reserve Tokens ----------------------------- */

    function testReserveTokens() public {
        minter.reserveTokens(10);
        assertEq(baseToken.balanceOf(address(this)), 10);
        assertEq(baseToken.totalSupply(), 10);
        assertEq(baseToken.totalMinted(), 10);
    }

    function testFailReserveTokens() public {
        mockCaller.minterReserve(minter, 10);
    }
    


    /* ---------------------------------- Mint ---------------------------------- */

    function testFailMintNotActive() public {
        minter.mint(1);
    }

    function testMintActive() public {
        // Activate sale.
        minter.flipSaleState();
        minter.setPrice(0.08 ether);

        // Mint.
        minter.mint{ value: 0.16 ether }(2);
        assertEq(baseToken.balanceOf(address(this)), 2);
        assertEq(baseToken.totalSupply(), 2);
        assertEq(baseToken.totalMinted(), 2);
    }

    function testFailMintIfNumTokensZero() public {
        // Activate sale.
        minter.flipSaleState();
        minter.setPrice(0.08 ether);

        // Mint.
        minter.mint{ value: 0.16 ether }(0);
    }

    function testFailMintIfPriceSetToZero() public {
        // Activate sale.
        minter.flipSaleState();
        minter.setPrice(0);

        // Mint.
        minter.mint{ value: 0.16 ether }(2);
    }
    function testFailMintNotEnoughEther() public {
        // Activate sale.
        minter.flipSaleState();
        minter.setPrice(0.08 ether);

        // Mint.
        minter.mint{ value: 0.16 ether }(3);
    }

    function testRefundIfOverpay() public {
        // Activate sale.
        minter.flipSaleState();
        minter.setPrice(0.08 ether);

        uint256 cachedBalance = address(this).balance;

        // Mint.
        minter.mint{ value: 0.16 ether }(1);

        assertEq(address(this).balance, cachedBalance - 0.08 ether);
    }

    function testFailSurpassTotalSupply() public {
        // Activate sale.
        minter.flipSaleState();
        minter.setPrice(0.08 ether);

        uint256 numToMint = baseToken.maxSupply() + 1;
        minter.mint{ value: 0.08 ether * numToMint }(numToMint);
    }

    function testMintTotalSupply() public {
        // Activate sale.
        minter.flipSaleState();
        minter.setPrice(0.08 ether);

        uint256 numToMint = baseToken.maxSupply();
        minter.mint{ value: 0.08 ether * numToMint }(numToMint);
        
        assertEq(baseToken.balanceOf(address(this)), numToMint);
        assertEq(baseToken.totalSupply(), numToMint);
        assertEq(baseToken.totalMinted(), numToMint);
    }

    function testMintMaxTimesPerWallet() public {
        // Activate sale.
        minter.flipSaleState();
        minter.setPrice(0.08 ether);
        uint256 numToMint = 5;
        minter.setMaxWalletPurchase(numToMint);

        minter.mint{ value: 0.08 ether * numToMint }(numToMint);

        assertEq(baseToken.balanceOf(address(this)), numToMint);
        assertEq(baseToken.totalSupply(), numToMint);
        assertEq(baseToken.totalMinted(), numToMint);
    }

    function testFailMintTooManyTimesPerWallet() public {
        // Activate sale.
        minter.flipSaleState();
        minter.setPrice(0.08 ether);
        uint256 numToMint = 5;
        minter.setMaxWalletPurchase(numToMint);
        minter.mint{ value: 0.08 ether * (numToMint + 1) }(numToMint + 1);
    }


    /* ------------------------------- Signed Mint ------------------------------ */
    function testFailSignedMintNotActive() public {
        // Setup.
        minter.setPrice(0.08 ether);
        minter.setMaxWalletPurchase(5);
        bytes memory sig = signPayload(minter, privateKey, address(this), 5);

        minter.signedMint{ value: 0.08 ether }(1, 5, sig);
    }

    function testFailSignedMintPriceNotSet() public {
        // Setup.
        minter.flipSignedMintState();
        minter.setMaxWalletPurchase(5);
        bytes memory sig = signPayload(minter, privateKey, address(this), 5);

        minter.signedMint{ value: 0.08 ether }(1, 5, sig);
    }

    function testSignedMint() public {
        // Setup.
        minter.flipSignedMintState();
        minter.setPrice(0.08 ether);
        minter.setMaxWalletPurchase(5);
        bytes memory sig = signPayload(minter, privateKey, address(this), 5);

        minter.signedMint{ value: 0.08 ether }(1, 5, sig);

        assertEq(baseToken.balanceOf(address(this)), 1);
        assertEq(baseToken.totalSupply(), 1);
        assertEq(baseToken.totalMinted(), 1);
    }

    function testSignedMintTwoPurchases() public {
        // Setup.
        minter.flipSignedMintState();
        minter.setPrice(0.08 ether);
        minter.setMaxWalletPurchase(5);
        bytes memory sig = signPayload(minter, privateKey, address(this), 5);

        minter.signedMint{ value: 0.08 ether }(1, 5, sig);
        minter.signedMint{ value: 0.08 ether }(1, 5, sig);

        assertEq(baseToken.balanceOf(address(this)), 2);
        assertEq(baseToken.totalSupply(), 2);
        assertEq(baseToken.totalMinted(), 2);
    }

    function testFailSignedMintOverMax() public {
        // Setup.
        minter.flipSignedMintState();
        minter.setPrice(0.08 ether);
        minter.setMaxWalletPurchase(5);
        bytes memory sig = signPayload(minter, privateKey, address(this), 5);

        minter.signedMint{ value: 0.08 ether }(3, 5, sig);
        minter.signedMint{ value: 0.08 ether }(3, 5, sig);
    }

    function testFailSignedMintNumTokensZero() public {
        // Setup.
        minter.flipSignedMintState();
        minter.setPrice(0.08 ether);
        minter.setMaxWalletPurchase(5);
        bytes memory sig = signPayload(minter, privateKey, address(this), 5);

        minter.signedMint{ value: 0.08 ether }(0, 5, sig);
    }

    function testFailSignedMintPriceZero() public {
        // Setup.
        minter.flipSignedMintState();
        minter.setPrice(0.08 ether);
        minter.setPrice(0 ether);
        minter.setMaxWalletPurchase(5);
        bytes memory sig = signPayload(minter, privateKey, address(this), 5);

        minter.signedMint{ value: 0.08 ether }(1, 5, sig);
    }

    function testFailSignedMintAboveMaxSupply() public {
        // Setup.
        minter.flipSignedMintState();
        minter.setPrice(0.008 ether);

        uint256 maxPlus1 = baseToken.maxSupply() + 1;
        minter.setMaxWalletPurchase(maxPlus1);
        bytes memory sig = signPayload(minter, privateKey, address(this), maxPlus1);

        minter.signedMint{ value: (0.008 ether) * maxPlus1 }(maxPlus1, maxPlus1, sig);
    }

    function testMintMaxSupply() public {
        // Setup.
        minter.flipSignedMintState();
        minter.setPrice(0.008 ether);

        uint256 max = baseToken.maxSupply();
        minter.setMaxWalletPurchase(max);
        bytes memory sig = signPayload(minter, privateKey, address(this), max);

        minter.signedMint{ value: (0.008 ether) * max }(max, max, sig);
    }

    function testMintMaxWallet() public {
        // Setup.
        minter.flipSignedMintState();
        minter.setPrice(0.008 ether);
        minter.setMaxWalletPurchase(8);

        bytes memory sig = signPayload(minter, privateKey, address(this), 8);

        minter.signedMint{ value: 0.008 ether * 8 }(1, 8, sig);
    }


    /* -------------------------------- Claiming -------------------------------- */


}