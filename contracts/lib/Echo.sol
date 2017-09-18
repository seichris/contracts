pragma solidity ^0.4.11;

contract Echo {

    event Echo(uint256 _value);

    uint public state;

    function echo() public {
        state += 1;
        Echo(state);
    }

}