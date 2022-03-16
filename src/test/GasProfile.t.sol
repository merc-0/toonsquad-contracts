// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "./mocks/MockCaller.sol";
import "../BaseToken.sol";
import "../Minter.sol";
import "./utils/Hevm.sol";


contract GasProfile is DSTest {
    Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

    // contracts
    BaseToken internal baseToken;
    Minter internal minter;
    string internal name = "Test Token";
    string internal symbol = "TT";
    address[] internal payees = [
        0xaa1CF06BA699c40b2EAfb5e9bc43AC5C71EcC780,
        0xC95876d9D0E954068C2B6840d226cc9Cab5Dfc1a
    ];
    uint256[] internal shares = [75, 25];
    uint256 internal privateKey = 0xBEEF;
    address internal minterSigner = hevm.addr(privateKey);
    bytes sig;

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
        minter = new Minter(address(baseToken), payees, shares);
        minter.setMintSigner(minterSigner);

        baseToken.grantRole(baseToken.MINTER_ROLE(), address(minter));
        baseToken.grantRole(baseToken.MINTER_ROLE(), address(this));
        baseToken.setMaxSupply(50);

        // Activate sale.
        minter.flipSaleState();
        minter.flipSignedMintState();
        minter.setMaxWalletPurchase(20);
        minter.setPrice(0.08 ether);

        sig = signPayload(minter, privateKey, address(this), 20);

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


    /* ------------------------------- Mint Direct ------------------------------ */

    function testMintDirectSingle() public {
        baseToken.mint(address(this));
    }

    function testMintDirectFive() public {
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
    }

    function testMintDirectTen() public {
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
    }

    function testMintDirectTwenty() public {
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
        baseToken.mint(address(this));
    }

    /* ---------------------------------- Mint ---------------------------------- */

    function testMintSingle() public {
        minter.mint{ value: 0.08 ether }(1);
    }

    function testMintFive() public {
        minter.mint{ value: 0.08 ether * 5 }(5);
    }

    function testMintTen() public {
        minter.mint{ value: 0.08 ether * 10 }(10);
    }

    function testMintTwenty() public {
        minter.mint{ value: 0.08 ether * 20 }(20);
    }


    /* ------------------------------- Signed Mint ------------------------------ */

    function testLoadingSig() view public {
        bytes memory sigInMemory = sig;
    }
    
    function testSignedMintSingle() public {
        minter.signedMint{ value: 0.08 ether }(1, 20, sig);
    }

    function testSignedMintFive() public {
        minter.signedMint{ value: 0.08 ether * 5 }(5, 20, sig);
    }

    function testSignedMintTen() public {
        minter.signedMint{ value: 0.08 ether * 10 }(10, 20, sig);
    }

    function testSignedMintTwenty() public {
        minter.signedMint{ value: 0.08 ether * 20 }(20, 20, sig);
    }

}