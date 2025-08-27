m@MacBook-Pro contracts % slither .
'forge clean' running (wd: /Users/m/Tokenization Platform Mock/contracts)
'forge config --json' running
'forge build --build-info --skip */test/** */script/** --force' running (wd: /Users/m/Tokenization Platform Mock/contracts)
INFO:Detectors:
ERC1400Token.removeDocument(bytes32) (src/contracts/ERC1400Token.sol#132-136) uses timestamp for comparisons
        Dangerous comparisons:
        - require(bool,string)(bytes(_documents[docName].uri).length > 0,Document not found) (src/contracts/ERC1400Token.sol#133)
ERC1400Token.getDocument(bytes32) (src/contracts/ERC1400Token.sol#143-147) uses timestamp for comparisons
        Dangerous comparisons:
        - require(bool,string)(bytes(doc.uri).length > 0,Document not found) (src/contracts/ERC1400Token.sol#145)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#block-timestamp
INFO:Detectors:
5 different versions of Solidity are used:
        - Version constraint ^0.8.20 is used by:
                -^0.8.20 (lib/openzeppelin-contracts/contracts/access/AccessControl.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Context.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#4)
                -^0.8.20 (lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol#4)
        - Version constraint >=0.8.4 is used by:
                ->=0.8.4 (lib/openzeppelin-contracts/contracts/access/IAccessControl.sol#4)
                ->=0.8.4 (lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#3)
        - Version constraint >=0.4.16 is used by:
                ->=0.4.16 (lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#4)
                ->=0.4.16 (lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#4)
        - Version constraint >=0.6.2 is used by:
                ->=0.6.2 (lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol#4)
        - Version constraint ^0.8.25 is used by:
                -^0.8.25 (src/Counter.sol#2)
                -^0.8.25 (src/contracts/ERC1400Token.sol#2)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#different-pragma-directives-are-used
INFO:Detectors:
Version constraint ^0.8.20 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
        - VerbatimInvalidDeduplication
        - FullInlinerNonExpressionSplitArgumentEvaluationOrder
        - MissingSideEffectsOnSelectorAccess.
It is used by:
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/access/AccessControl.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/Context.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol#4)
        - ^0.8.20 (lib/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol#4)
Version constraint >=0.8.4 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
        - FullInlinerNonExpressionSplitArgumentEvaluationOrder
        - MissingSideEffectsOnSelectorAccess
        - AbiReencodingHeadOverflowWithStaticArrayCleanup
        - DirtyBytesArrayToStorage
        - DataLocationChangeInInternalOverride
        - NestedCalldataArrayAbiReencodingSizeValidation
        - SignedImmutables.
It is used by:
        - >=0.8.4 (lib/openzeppelin-contracts/contracts/access/IAccessControl.sol#4)
        - >=0.8.4 (lib/openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol#3)
Version constraint >=0.4.16 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
        - DirtyBytesArrayToStorage
        - ABIDecodeTwoDimensionalArrayMemory
        - KeccakCaching
        - EmptyByteArrayCopy
        - DynamicArrayCleanup
        - ImplicitConstructorCallvalueCheck
        - TupleAssignmentMultiStackSlotComponents
        - MemoryArrayCreationOverflow
        - privateCanBeOverridden
        - SignedArrayStorageCopy
        - ABIEncoderV2StorageArrayWithMultiSlotElement
        - DynamicConstructorArgumentsClippedABIV2
        - UninitializedFunctionPointerInConstructor_0.4.x
        - IncorrectEventSignatureInLibraries_0.4.x
        - ExpExponentCleanup
        - NestedArrayFunctionCallDecoder
        - ZeroFunctionSelector.
It is used by:
        - >=0.4.16 (lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol#4)
        - >=0.4.16 (lib/openzeppelin-contracts/contracts/utils/introspection/IERC165.sol#4)
Version constraint >=0.6.2 contains known severe issues (https://solidity.readthedocs.io/en/latest/bugs.html)
        - MissingSideEffectsOnSelectorAccess
        - AbiReencodingHeadOverflowWithStaticArrayCleanup
        - DirtyBytesArrayToStorage
        - NestedCalldataArrayAbiReencodingSizeValidation
        - ABIDecodeTwoDimensionalArrayMemory
        - KeccakCaching
        - EmptyByteArrayCopy
        - DynamicArrayCleanup
        - MissingEscapingInFormatting
        - ArraySliceDynamicallyEncodedBaseType
        - ImplicitConstructorCallvalueCheck
        - TupleAssignmentMultiStackSlotComponents
        - MemoryArrayCreationOverflow.
It is used by:
        - >=0.6.2 (lib/openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Metadata.sol#4)
Reference: https://github.com/crytic/slither/wiki/Detector-Documentation#incorrect-versions-of-solidity
INFO:Slither:. analyzed (14 contracts with 100 detectors), 7 result(s) found
m@MacBook-Pro contracts % 