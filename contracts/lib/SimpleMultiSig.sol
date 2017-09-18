pragma solidity ^0.4.11;

contract SimpleMultiSig {

    uint public nonce;                    // (only) mutable state
    uint8 public threshold;               // immutable state
    mapping (address => bool) isOwner;    // immutable state
    address[] public ownersArr;           // immutable state

    function SimpleMultiSig(uint8 _threshold, address[] _owners) {
        require(_owners.length <= 10 && _threshold <= _owners.length && _threshold != 0);

        address lastAdd = address(0);
        for (uint i = 0; i < _owners.length; i++) {
            require(_owners[i] > lastAdd);
            isOwner[_owners[i]] = true;
            lastAdd = _owners[i];
        }
        ownersArr = _owners;
        threshold = _threshold;
    }

    // Note that address recovered from signatures must be strictly increasing
    function execute(uint8[] _sigV, bytes32[] _sigR, bytes32[] _sigS, address _destination, uint _value, bytes _data) {
        require(_sigR.length == threshold);
        require(_sigR.length == _sigS.length && _sigR.length == _sigV.length);
        // Follows ERC191 signature scheme: https://github.com/ethereum/EIPs/issues/191
        bytes32 txHash = sha3(byte(0x19), byte(0), this, _destination, _value, _data, nonce);

        address lastAdd = address(0);
        // cannot have address(0) as an owner
        for (uint i = 0; i < threshold; i++) {
            address recovered = ecrecover(txHash, _sigV[i], _sigR[i], _sigS[i]);
            require(recovered > lastAdd && isOwner[recovered]);
            lastAdd = recovered;
        }

        // If we make it here all signatures are accounted for
        nonce = nonce + 1;
        require(_destination.call.value(_value)(_data));
    }

    function() payable {}
}