# Changelog

## Version 1.0.2 

Readme.md adjusted, because the wrong html br-tag was used

## Version 1.0.3

Calculation of the free available size was wrong.

Before:

    if (totalSizeFromAlreadyStoredBlob > memoryStorage.replaceBufferSize) {

        let freeSizeAvailable : Nat = Nat64.toNat(totalSizeFromAlreadyStoredBlob - memoryStorage.replaceBufferSize);                           
        if (blobToStoreOrUpdateSize <= freeSizeAvailable) {
            updatePossible := true;
        };
    };

 After:

    if (totalSizeFromAlreadyStoredBlob > 16) {

        let freeSizeAvailable : Nat = Nat64.toNat(totalSizeFromAlreadyStoredBlob - 16);                           
        if (blobToStoreOrUpdateSize <= freeSizeAvailable) {
            updatePossible := true;
        };
    };

## Version 1.0.4

- Install-steps now added in readme.md (I forgot to add these...)
- Two wrong comments adjusted

## Version 1.0.5
- The performance enhanced ( == less cycles needed for the operations. approx 30-40 %)
