pragma solidity 0.5.10;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./collectors/Pools.sol";
import "./Settings.sol";


/**
 * @title Validators Registry.
 * This contract keeps track of all the registered validators.
 * Only collectors can call it.
 */
contract ValidatorsRegistry is Initializable {
    // Stores information about the validator.
    struct Validator {
        uint256 depositAmount;
        uint16 maintainerFee;
        bytes32 entityId;
    }

    // Maps validator ID (hash of the public key) to the Validator information.
    mapping(bytes32 => Validator) public validators;

    // Address of the Pools contract.
    Pools private pools;

    // Address of the Settings contract.
    Settings private settings;

    /**
    * Event for tracking registered validators.
    * @param entityId - ID of the collector's entity the deposit was collected in.
    * @param pubKey - Validator's public key.
    * @param withdrawalCredentials - The withdrawal credentials used to perform withdrawal for this validator.
    * @param depositAmount - Validator's deposit amount.
    * @param maintainerFee - Fee to pay to the maintainer after withdrawal.
    */
    event ValidatorRegistered(
        bytes32 indexed entityId,
        bytes pubKey,
        bytes withdrawalCredentials,
        uint256 depositAmount,
        uint16 maintainerFee
    );

    /**
    * Constructor for initializing the ValidatorsRegistry contract.
    * @param _pools - Address of the Pols contract.
    * @param _settings - Address of the Settings contract.
    */
    function initialize(Pools _pools, Settings _settings) public initializer {
        pools = _pools;
        settings = _settings;
    }

    /**
    * Function for registering validators.
    * Can only be called by collectors.
    * _pubKey - BLS public key of the validator, generated by the operator.
    * _entityId - ID of the collector's entity the deposit was accumulated in.
    */
    function register(bytes calldata _pubKey, bytes32 _entityId) external {
        require(msg.sender == address(pools), "Permission denied.");

        bytes32 validatorId = keccak256(abi.encodePacked(_pubKey));
        require(validators[validatorId].entityId[0] == 0, "Public key has been already used.");

        Validator memory validator = Validator(
            settings.validatorDepositAmount(),
            settings.maintainerFee(),
            _entityId
        );
        validators[validatorId] = validator;
        emit ValidatorRegistered(
            validator.entityId,
            _pubKey,
            settings.withdrawalCredentials(),
            validator.depositAmount,
            validator.maintainerFee
        );
    }
}
