from web3.utils.compat import (
    Timeout,
)
import binascii
from ethereum import tester
import sign


def sha3(*args) -> bytes:
    """
    Simulates Solidity's sha3 function. Integers can be passed as tuples where the second tuple
    element specifies the variable size, e.g.:
    sha3((5, 32))
    would be equivalent to Solidity's
    sha3(uint32(5))
    """
    from ethereum.utils import sha3

    msg = b''
    for arg in args:
        if isinstance(arg, bytes):
            msg += arg
        elif isinstance(arg, str):
            if arg[:2] == '0x':
                msg +=binascii.unhexlify(arg[2:])
            else:
                msg += arg.encode()
        elif isinstance(arg, int):
            if arg >= 0:
                msg += binascii.unhexlify('{:x}'.format(arg).zfill(64))
            else:
                raise ValueError('Negative integers currently not supported.')
        elif isinstance(arg, tuple):
            arg, size = arg
            if isinstance(arg, int):
                msg += binascii.unhexlify('{:x}'.format(arg).zfill(256 // size))
            else:
                raise ValueError('Explicit size only allowed for integers.')
        else:
            raise ValueError('Unsupported type: {}.'.format(type(arg)))

    return sha3(msg)


def wait(transfer_filter):
    with Timeout(30) as timeout:
        while not transfer_filter.get(False):
            timeout.sleep(2)


def test_multisig_2(chain):
    echofactory = chain.provider.get_contract_factory('Echo')
    hash = echofactory.deploy()
    receipt = chain.wait.for_receipt(hash)
    echo_address = receipt["contractAddress"]
    print("\necho address is", echo_address)
    echo = echofactory(echo_address)
    transfer_filter = echo.on("Echo")
    set_txn_hash = echo.transact().echo()
    receipt = chain.wait.for_receipt(set_txn_hash)
    wait(transfer_filter)
    log_entries = transfer_filter.get()
    print("direct call", log_entries[0]['args']['_value']);
    data = chain.web3.eth.getTransaction(receipt['transactionHash'])['input']

    multisigfactory = chain.provider.get_contract_factory('SimpleMultiSig')
    hash = multisigfactory.deploy(args=[2, [chain.web3.eth.accounts[0], chain.web3.eth.accounts[2]]])
    receipt = chain.wait.for_receipt(hash)
    address = receipt["contractAddress"]
    print("\nms address is", address)

    multisig = multisigfactory(address)
    nounce = 0; # has to be zero
    hash = sha3(binascii.unhexlify("19"), binascii.unhexlify("00"), address, echo_address, 0, binascii.unhexlify(data[2:]), nounce)
    signature = sign.check(hash, tester.k0)[0]
    r1 = signature[0:32]
    s1 = signature[32:64]
    v1 = signature[64] + 27
    signature = sign.check(hash, tester.k2)[0]
    r2 = signature[0:32]
    s2 = signature[32:64]
    v2 = signature[64] + 27
    set_txn_hash = multisig.transact().execute([v1,v2], [r1,r2], [s1,s2], echo_address, 0, binascii.unhexlify(data[2:]))
    receipt = chain.wait.for_receipt(set_txn_hash)
    wait(transfer_filter)
    log_entries = transfer_filter.get()
    print("indirect call", log_entries[0]['args']['_value']);