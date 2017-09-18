pragma solidity ^0.4.11;

import "./lib/Resolver.sol";
import "./lib/EtherRouter.sol";
import "./gov/GovernanceTemplate.sol";
import "./CurrencyNetwork.sol";

contract CurrencyNetworkFactory {

    event CurrencyNetworkCreated(address _real, address _currencyNetworkContract, address _governanceTemplate, address _resolver);

    function CurrencyNetworkFactory(address _registry) {
    }

    //cost XXXXXXX gas
    function CreateCurrencyNetwork
    (
        string _tokenName,
        string _tokenSymbol,
        address _adminKey,
        uint16 _network_fee_divisor,
        uint16 _capacity_fee_divisor,
        uint16 _imbalance_fee_divisor,
        uint16 _maxInterestRate
    ) external {
        GovernanceTemplate governance = new GovernanceTemplate(_maxInterestRate);
        address tokenAddr = new CurrencyNetwork();
        Resolver resolver = new Resolver(tokenAddr);
        resolver.setAdmin(_adminKey);
        address routerAddr = new EtherRouter(resolver);
        CurrencyNetwork(routerAddr).init(_tokenName, _tokenSymbol, _network_fee_divisor, _capacity_fee_divisor, _imbalance_fee_divisor);
        CurrencyNetworkCreated(tokenAddr, routerAddr, governance, resolver);
    }
}
