import Bench "mo:bench";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import lib "../src/lib";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

module {
    public func init() : Bench.Bench {

        let bench = Bench.Bench();

        bench.name("Adding new items");
        bench.description("Add new items benchmark");

        bench.rows(["memoryHashTable"]);
        bench.cols(["1","10", "100", "1000","10000", "100000"]);

        type OwnType = {
            myNumber : Nat;
            myText : Text;
        };
        

        let ownType1 : OwnType = {
            myNumber : Nat = 2345;
            myText : Text = "Hello World";
        };

        let ownType1Blob : Blob = to_candid (ownType1);
        let memoryItem = lib.get_new_memory_storage(8);
        let mem = lib.MemoryHashTable(memoryItem);


        bench.runner(
            func(row, col) {
                let ?n = Nat.fromText(col);

                // Vector
                if (row == "memoryHashTable") {
                    for (i in Iter.range(1, n)) {
                        let key1 : Blob = lib.Blobify.Text.to_blob("key"#debug_show(i));
                        ignore mem.put(key1, ownType1Blob);
                    };
                };
            }
        );

        bench;
    };
};
