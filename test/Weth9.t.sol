// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Weth9.sol";

contract Weth9Test is Test {
    WETH9 public weth9;
    address addr1 = address(123);
    address addr2 = address(456);

    receive() external payable {}

    event Transfer(address indexed from, address indexed to, uint value);
    event Withdrawal(address indexed src, uint256 wad);

    function setUp() public {
        weth9 = new WETH9();
    }

    //1
    function testDepositMintEqualsToValue(uint96 eth) public {
        weth9.deposit{value: eth}();
        assertEq(weth9.balanceOf(address(this)), eth);
    }

    //2
    function testDepositTransferValueToContract(uint96 eth) public {
        weth9.deposit{value: eth}();
        assertEq(address(weth9).balance, eth);
    }

    //3
    function testEmitDeposit() public {
        vm.deal(addr1, 1 ether);
        vm.prank(addr1);
        vm.expectEmit(true, true, false, false);
        emit Transfer(address(0), addr1, 1 ether);
        weth9.deposit{value: 1 ether}();
    }

    //4
    function testWithdrawBurnEqualsToValue(uint eth) public {
        vm.deal(addr1, eth);
        vm.startPrank(addr1);
        weth9.deposit{value: eth}();
        uint balanceBefore = weth9.balanceOf(addr1);
        weth9.withdraw(eth);
        uint balanceAfter = weth9.balanceOf(addr1);
        assertEq(balanceBefore - eth, balanceAfter);
    }

    //5
    function testBurnWeth9AndExchangeEth() public {
        weth9.deposit{value: 200 ether}();
        uint256 balanceBefore = address(this).balance;
        weth9.withdraw(1 ether);
        uint256 balanceAfter = address(this).balance;
        assertEq(balanceBefore + 1 ether, balanceAfter);
    }

    //6
    function testWithdrawEmitWithdraw() public {
        vm.deal(addr1, 1 ether);
        vm.startPrank(addr1);
        weth9.deposit{value: 1 ether}();
        vm.expectEmit(true, true, false, false);
        emit Transfer(addr1, address(0), 1 ether);
        weth9.withdraw(1 ether);
    }

    //7
    function testTransferWeth9ToOthers() public {
        deal(address(weth9), addr1, 1 ether);
        vm.startPrank(addr1);
        assertEq(weth9.balanceOf(addr1), 1 ether);
        assertEq(weth9.balanceOf(addr2), 0);
        weth9.transfer(addr2, 1 ether);
        assertEq(weth9.balanceOf(addr1), 0);
        assertEq(weth9.balanceOf(addr2), 1 ether);
    }

    //8
    function testApproveAllowance(uint96 wad) public {
        weth9.approve(addr1, wad);
        assertEq(weth9.allowance(address(this), addr1), wad);
    }

    //9
    function testUseOthersAllowanceAndTransferFrom() public {
        weth9.deposit{value: 200}();
        weth9.approve(addr1, 2);
        vm.prank(addr1);
        bool result = weth9.transferFrom(address(this), addr2, 1);
        require(result, "failed");
    }

    //10
    function testTransferFromAndMinusAllowance() public {
        weth9.deposit{value: 200}();
        weth9.approve(addr1, 2);
        vm.prank(addr1);
        weth9.transferFrom(address(this), addr2, 1);
        assertEq(weth9.allowance(address(this), addr1), 2 - 1);
    }
}
