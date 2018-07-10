pragma solidity ^0.4.23;

import 'openzeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

/**
 * @title Rentledger Contract
 *
 * @dev Implementation of OpenZeppelin StandardBurnableToken.
 * @dev Ability for Owner to save notes to each Address
 * @dev Ability for AirDrop to be distributed by Owner
 */
contract Rentledger is StandardBurnableToken, Ownable {
    using SafeMath for uint256;

    string public name = "Rentledger";
    string public symbol = "RTL";
    uint public decimals = 18;
    uint public totalAmount = 10000000000;
    uint public multiplier = (10 ** decimals);

    address public constant addrDevelopment = 0x3de89f56eb251Bc105FB4e6e6F95cd98F3797496;
    uint public constant developmentPercent = 10;

    address public constant addrLockedFunds = 0xA1D7A9ACa0AAD152624be07CddCE1036C3404d4C;
    uint public constant lockedFundsPercent = 10;

    address public constant addrAirDrop = 0x9b2466235741D3d8E018acBbC8feCcf4c6C96859;
    uint public constant airDropPercent = 10;

    address public constant addrDistribution = 0x7feB9Bdf4Ea954264C735C5C5F731E14e4D5327e;
    uint public constant distributionPercent = 70;

    uint64 public constant lockedFundsSeconds = 60 * 60 * 24 * 365 * 1; // 1 year
    uint public contractStartTime;

    mapping(address => string) saveData;

    constructor() public { }

    function initializeContract() onlyOwner public {
        if (totalSupply_ != 0) return;

        require((developmentPercent + lockedFundsPercent + airDropPercent + distributionPercent) == 100);

        contractStartTime = now;

        totalSupply_ = totalAmount * multiplier;

        balances[addrDevelopment] = totalSupply_ * developmentPercent / 100;
        balances[addrLockedFunds] = totalSupply_ * lockedFundsPercent / 100;
        balances[addrAirDrop] = totalSupply_ * airDropPercent / 100;
        balances[addrDistribution] = totalSupply_ * distributionPercent / 100;

        emit Transfer(0x0, addrDevelopment, balances[addrDevelopment]);
        emit Transfer(0x0, addrLockedFunds, balances[addrLockedFunds]);
        emit Transfer(0x0, addrAirDrop, balances[addrAirDrop]);
        emit Transfer(0x0, addrDistribution, balances[addrDistribution]);
    }

    function unlockFunds() onlyOwner public {
        require(uint256(now).sub(lockedFundsSeconds) > contractStartTime);
        uint _amount = balances[addrLockedFunds];
        balances[addrLockedFunds] = balances[addrLockedFunds].sub(_amount);
        balances[addrDevelopment] = balances[addrDevelopment].add(_amount);
        emit Transfer(addrLockedFunds, addrDevelopment, _amount);
    }

    function putSaveData(address _address, string _text) onlyOwner public {
        saveData[_address] = _text;
    }

    function getSaveData(address _address) constant public returns (string) {
        return saveData[_address];
    }

    function airDrop(address[] _recipients, uint[] _values) onlyOwner public returns (bool) {
        return distribute(addrAirDrop, _recipients, _values);
    }

    function distribute(address _from, address[] _recipients, uint[] _values) internal returns (bool) {
        require(_recipients.length > 0 && _recipients.length == _values.length);

        uint total = 0;
        for(uint i = 0; i < _values.length; i++) {
            total = total.add(_values[i]);
        }
        require(total <= balances[_from]);
        balances[_from] = balances[_from].sub(total);

        for(uint j = 0; j < _recipients.length; j++) {
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            emit Transfer(_from, _recipients[j], _values[j]);
        }

        return true;
    }
}
