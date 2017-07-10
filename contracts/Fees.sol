pragma solidity ^0.4.0;

import "./lib/SafeMath.sol";
import "./Trustline.sol";

library Fees {

    using SafeMath for int48;
    using SafeMath for int256;
    using SafeMath for uint16;
    using SafeMath for uint24;
    using SafeMath for uint192;

    /*
     * @notice The network fee is payable by the inititator of a transfer.
     * @notice It is tracked in the outgoing account to avoid updating a user global storage slot.
     * @notice The system fee is splitted between the onboarders and the investors.
     * @param sender User wishing to send funds to receiver, incurring the fee
     * @param receiver User receiving the funds
     * @param value Amount of tokens being transferred
     */
    function applyNetworkFee(Trustline.Account storage _account, address _sender, address _receiver, int48 _value, uint16 _network_fee_divisor) internal {
        //Account account = accounts[hashFunc(sender, receiver)];
        int fee = calculateNetworkFee(_value, _network_fee_divisor);
        if (_sender < _receiver) {
            _account.feesOutstandingA += uint16(fee);
        } else {
            _account.feesOutstandingB += uint16(fee);
        }

    }

    /*
     * @notice Calculates the system fee from the value being transferred
     * @param value being transferred
     */
    function calculateNetworkFee(int48 _value, uint16 _network_fee_divisor) internal returns (int48) {
        return int48(_value.div(_network_fee_divisor));
    }

    /*
     * @notice The fees deducted from the value while being transferred from second hop onwards in the mediated transfer
     */
    function deductedTransferFees(Trustline.Account storage _account, address _sender, address _receiver, uint24 _value, uint16 _capacity_fee_divisor, uint16 _imbalance_fee_divisor) internal returns (uint16) {
        return capacityFee(_value, _capacity_fee_divisor).add16(uint16(_imbalanceFee(_account, _sender, _receiver, _value, _imbalance_fee_divisor)));
    }

    /*
     * @notice reward for providing the edge with sufficient capacity
     * @notice beneficiary: sender (because receiver will receive if he's the next hop)
     */
    function capacityFee(uint24 _value, uint16 _capacity_fee_divisor) internal returns (uint16) {
        return uint16(_value.div24(_capacity_fee_divisor));
    }

    /*
     * @notice penality for increasing account imbalance
     * @notice beneficiary: sender (because receiver will receive if he's the next hop)
     * @notice NOTE: It should also incorporate the interest as users will favor being indebted in
     */
    function _imbalanceFee(Trustline.Account storage _account, address _sender, address _receiver, uint24 _value, uint16 _imbalance_fee_divisor) internal returns (uint24) {
        //Account account = accounts[hashFunc(sender, receiver)];
        int48 addedImbalance = 0;
        int48 newBalance = 0;
        if (_sender < _receiver) {
            // negative hence sender indebted to receiver so addedImbalace is the incoming value
            if (_account.balanceAB <= 0) {
                addedImbalance = _value;
            } else {
            // positive hence receiver indebted to sender so if the newBalance is smaller then zero we introduce imbalance
                newBalance = int48(_account.balanceAB.sub(_value));
                if (newBalance < 0)
                    addedImbalance = -newBalance;
            }
        } else {
            //sender address is greater, here semantics will be opposite of the one above
            // positive hence sender is indebted to receiver so addedImbalance is the incoming value
            if (_account.balanceAB >= 0) {
                addedImbalance = _value;
            } else {
            // negative hence receiver is indebted to the sender so if the newBalance is greater than zero we introduce imbalance
                newBalance = int48(_account.balanceAB.add(_value));
                if (newBalance > 0)
                    addedImbalance = newBalance;
            }
        }
        return (addedImbalance.div4824(_imbalance_fee_divisor));
    }

}