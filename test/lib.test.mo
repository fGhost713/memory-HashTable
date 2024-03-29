// @testmode wasi
import lib "../src/lib";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat64 "mo:base/Nat64";

import { test; suite } "mo:test";

    type OwnType = {
        myNumber : Nat;
        myText : Text;
    };
    

    let ownType1 : OwnType = {
        myNumber : Nat = 2345;
        myText : Text = "Hello World";
    };
    let ownType2 : OwnType = {
        myNumber : Nat = 79;
        myText : Text = "";
    };
    let ownType3 : OwnType = {
        myNumber : Nat = 0;
        myText : Text = "My test text";
    };

    let ownType1Blob : Blob = to_candid (ownType1);
    let ownType2Blob : Blob = to_candid (ownType2);
    let ownType3Blob : Blob = to_candid (ownType3);

    func ownType_getDefaultType() : OwnType {
        let result : OwnType = {
            myNumber = 0;
            myText = "";
        };
    };

    func ownType_blobs_array_are_equal_check(items1 : [Blob], items2 : [Blob]) {

        assert (items1.size() == items2.size());

        for (index in Iter.range(0, items1.size() -1)) {
            ownType_blobs_are_equal_check(items1[index], items2[index]);
        };
    };

    func ownType_blobs_are_equal_check(item1_blob : Blob, item2_blob : Blob) {

        let item1OrNull : ?OwnType = from_candid (item1_blob);
        let item2OrNull : ?OwnType = from_candid (item2_blob);

        let defType = ownType_getDefaultType();

        let item1 = Option.get(item1OrNull, defType);
        let item2 = Option.get(item2OrNull, { defType with MyNumber = 7 });

        assert (item1 == item2);
    };

    func ownType_blobs_are_not_equal_check(item1_blob : Blob, item2_blob : Blob) {

        let item1OrNull : ?OwnType = from_candid (item1_blob);
        let item2OrNull : ?OwnType = from_candid (item2_blob);

        let defType = ownType_getDefaultType();

        let item1 = Option.get(item1OrNull, defType);
        let item2 = Option.get(item2OrNull, { defType with MyNumber = 7 });

        assert (item1 != item2);
    };

    func ownType_blobs_are_not_null_and_equal_check(item1_blob : ?Blob, item2_blob : ?Blob) {

        assert (Option.isNull(item1_blob) == false and Option.isNull(item2_blob) == false);

        let defType = ownType_getDefaultType();
        let item1OrNull : ?OwnType = from_candid (Option.get(item1_blob, to_candid (defType)));
        let item2OrNull : ?OwnType = from_candid (Option.get(item2_blob, to_candid ({ defType with MyNumber = 3 })));

        let item1 = Option.get(item1OrNull, defType);
        let item2 = Option.get(item2OrNull, { defType with MyNumber = 7 });

        assert (item1 == item2);
    };

    func ownType_blobs_are_not_null_and_not_equal_check(item1_blob : ?Blob, item2_blob : ?Blob) {

        assert (Option.isNull(item1_blob) == false and Option.isNull(item2_blob) == false);

        let defType = ownType_getDefaultType();
        let item1OrNull : ?OwnType = from_candid (Option.get(item1_blob, to_candid (defType)));
        let item2OrNull : ?OwnType = from_candid (Option.get(item2_blob, to_candid ({ defType with MyNumber = 3 })));

        let item1 = Option.get(item1OrNull, defType);
        let item2 = Option.get(item2OrNull, { defType with MyNumber = 7 });

        assert (item1 != item2);
    };

    suite(
        "HashTable tests",
        func() {
            test(
                "put test",
                func() {

                    let memoryItem = lib.get_new_memory_storage(0);
                    let mem = lib.MemoryHashTable(memoryItem);

                    let key1 : Blob = lib.Blobify.Text.to_blob("key1");
                    let key2 : Blob = lib.Blobify.Text.to_blob("key2");

                    ignore mem.put(key1, ownType1Blob);
                    ignore mem.put(key2, ownType3Blob);
                    ignore mem.put(key2, ownType1Blob);

                    var result1 = mem.get(key1);
                    var result2 = mem.get(key2);

                    ownType_blobs_are_not_null_and_equal_check(result1, result2);

                    ignore mem.put(key2, ownType2Blob);
                    result2 := mem.get(key2);

                    ownType_blobs_are_not_null_and_not_equal_check(result1, result2);
                    ownType_blobs_are_not_null_and_equal_check(result2, Option.make(ownType2Blob));
                },

            );

            test(
                "put many items test",
                func() {

                    let memoryItem = lib.get_new_memory_storage(0);
                    let mem = lib.MemoryHashTable(memoryItem);

                    for (i in Iter.range(1, 10000)) {
                        let key1 : Blob = lib.Blobify.Text.to_blob("key"#debug_show(i));
                        ignore mem.put(key1, ownType1Blob);
                    };


                    for (i in Iter.range(1, 10000)) {
                        let key1 : Blob = lib.Blobify.Text.to_blob("key"#debug_show(i));
                        ignore mem.put(key1, ownType2Blob);
                    };


                    for (i in Iter.range(1, 10000)) {
                        let key1 : Blob = lib.Blobify.Text.to_blob("key"#debug_show(i));
                        let value = mem.get(key1);
                        ownType_blobs_are_not_null_and_equal_check(value, Option.make(ownType2Blob));
                    };

                },

            );
                   test(
                "update test",
                func() {

                    let memoryItem = lib.get_new_memory_storage(8);
                    let mem = lib.MemoryHashTable(memoryItem);

                    let key1 : Blob = lib.Blobify.Text.to_blob("key1");
                    let key2 : Blob = lib.Blobify.Text.to_blob("key2");

                    let address1 =  mem.put(key1, ownType1Blob);
                    let address2 = mem.put(key2, ownType3Blob);
                    assert (address1 != address2);

                    var result1 = mem.get(key1);
                    var result2 = mem.get(key2);

                    ownType_blobs_are_not_null_and_equal_check(result1, Option.make(ownType1Blob));
                    ownType_blobs_are_not_null_and_equal_check(result2, Option.make(ownType3Blob));

                    let address3 = mem.put(key1, ownType2Blob);
                    assert ( address3 == address1);
                    
                    result1 := mem.get(key1);
                    ownType_blobs_are_not_null_and_equal_check(result1, Option.make(ownType2Blob));

                    let shouldFitType:OwnType = {
                        myNumber = ownType2.myNumber;
                        myText = "Hello Worldabc";
                    };

                    let blob1:Blob = to_candid(shouldFitType);
                    let address4 = mem.put(key1, blob1);
                    assert ( address4 == address1);

                    result1 := mem.get(key1);
                    ownType_blobs_are_not_null_and_equal_check(result1, Option.make(blob1));


                    let shouldNotFitType:OwnType = {
                        myNumber = ownType2.myNumber;
                        myText = "Hello Worldabcdefghijklmnopqrst";
                    };

                    let blob2 = to_candid(shouldNotFitType);
                    let address5 = mem.put(key1, blob2);
                    assert ( address5 != address1);

                    result1 := mem.get(key1);
                    ownType_blobs_are_not_null_and_equal_check(result1, Option.make(blob2));

                    // Check if value for key2 is still the same, because key2 was untouched
                    result2 := mem.get(key2);
                    ownType_blobs_are_not_null_and_equal_check(result2, Option.make(ownType3Blob)); 
                },

            );
            test(
                "delete test",
                func() {

                    let memoryItem = lib.get_new_memory_storage(8);
                    let mem = lib.MemoryHashTable(memoryItem);

                    let key1 : Blob = lib.Blobify.Text.to_blob("key1");
                    let key2 : Blob = lib.Blobify.Text.to_blob("key2");

                    ignore mem.put(key1, ownType1Blob);
                    ignore mem.put(key2, ownType3Blob);
                    ignore mem.put(key2, ownType2Blob);

                    mem.delete(key2);

                    var result1 = mem.get(key1);
                    var result2 = mem.get(key2);

                    assert (Option.isNull(result1) == false);
                    assert (Option.isNull(result2) == true);

                    ignore mem.put(key2, ownType3Blob);
                    result2 := mem.get(key2);

                    ownType_blobs_are_not_null_and_not_equal_check(result1, result2);
                },

            );
           
        },

    );
