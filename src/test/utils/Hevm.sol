// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract Hevm {
    // sets the block timestamp to x
    function warp(uint256 x) public virtual;

    // sets the block number to x
    function roll(uint256 x) public virtual;

    // sets the slot loc of contract c to val
    function store(
        address c,
        bytes32 loc,
        bytes32 val
    ) public virtual;

    function ffi(string[] calldata) external virtual returns (bytes memory);

    function sign(uint256 sk, bytes32 digest) external virtual returns (uint8 v, bytes32 r, bytes32 s);
    function addr(uint256 sk) external virtual returns (address addr);
}
