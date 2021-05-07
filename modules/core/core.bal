
import semtype.bdd;

// Inherently immutable
public const BT_NIL = 0;
public const BT_BOOLEAN = 1;
public const BT_INT = 2;
public const BT_FLOAT = 3;
public const BT_DECIMAL = 4;
public const BT_STRING = 5;
public const BT_ERROR = 6;
public const BT_FUNCTION = 7;
public const BT_TYPEDESC = 8;
public const BT_HANDLE = 9;

// Selectively immutable; immutable half
public const BT_XML_RO = 10;
public const BT_LIST_RO = 11;
public const BT_MAPPING_RO = 12;
public const BT_TABLE_RO = 13;
public const BT_OBJECT_RO = 14;

// Selectively immutable; mutable half
public const BT_XML_RW = 15;
public const BT_LIST_RW = 16;
public const BT_MAPPING_RW = 17;
public const BT_TABLE_RW = 18;
public const BT_OBJECT_RW = 19;

// Inherently mutable
public const BT_STREAM = 20;
public const BT_FUTURE = 21;

public const BT_COUNT = 22;

public const int BT_MASK = (1 << BT_COUNT) - 1;

public const int BT_COUNT_RO = BT_OBJECT_RO + 1;
public const int BT_READONLY = (1 << BT_COUNT_RO) - 1;

// It would be easier to use ~ here, but slalpha5 doesn't support
public const int BT_RW_MASK = ((1 << (BT_COUNT - BT_COUNT_RO)) - 1) << BT_COUNT_RO;

public const int BT_SOME = 1 | (1 << BT_COUNT);

public type BasicTypeCode
    BT_NIL|BT_BOOLEAN|BT_INT|BT_FLOAT|BT_DECIMAL
    |BT_STRING|BT_ERROR|BT_FUNCTION|BT_TYPEDESC|BT_HANDLE
    |BT_XML_RO|BT_LIST_RO|BT_MAPPING_RO|BT_TABLE_RO|BT_OBJECT_RO
    |BT_XML_RW|BT_LIST_RW|BT_MAPPING_RW|BT_TABLE_RW|BT_OBJECT_RW
    |BT_STREAM|BT_FUTURE;

public type Env record {|
    ListSubtype[] listDefs = [];
    MappingSubtype[] mappingDefs = [];
    FunctionSubtype[] functionDefs = [];
|};

public type BddMemo record {|
    readonly bdd:Bdd bdd;
    boolean? isEmpty = ();
|};

type BddMemoTable table<BddMemo> key(bdd);

public type TypeCheckContext record {|
    readonly ListSubtype[] listDefs;
    readonly MappingSubtype[] mappingDefs;
    readonly FunctionSubtype[] functionDefs;
    BddMemoTable listMemo = table [];
    BddMemoTable mappingMemo = table [];
    BddMemoTable functionMemo = table [];
|};

// true means everything and false means nothing (as with Bdd)
type SubtypeData StringSubtype|IntSubtype|BooleanSubtype|bdd:Bdd;

type BasicTypeSubtype readonly & [BasicTypeCode, SubtypeData];

type BinOp function(SubtypeData t1, SubtypeData t2) returns SubtypeData;
type UnaryOp function(SubtypeData t) returns SubtypeData;
type UnaryTypeCheckOp function(TypeCheckContext tc, SubtypeData t) returns boolean;

function binOpPanic(SubtypeData t1, SubtypeData t2) returns SubtypeData {
    panic error("binary operation should not be called");
}

function unaryOpPanic(SubtypeData t) returns SubtypeData {
    panic error("unary operation should not be called");
}

function unaryTypeCheckOpPanic(TypeCheckContext tc, SubtypeData t) returns boolean {
    panic error("unary boolean operation should not be called");
}

type BasicTypeOps readonly & record {|
    BinOp union = binOpPanic;
    BinOp intersect = binOpPanic;
    BinOp diff = binOpPanic;
    UnaryOp complement = unaryOpPanic;
    UnaryTypeCheckOp isEmpty = unaryTypeCheckOpPanic;
|};

final readonly & (BasicTypeSubtype[]) EMPTY_SUBTYPES = [];

public readonly class SemType {
    // For a basic type with code b,
    // bits & (1 << b) is non-zero iff this type contains all of the basic type
    // bits & (1 << (b + BT_COUNT)) is non-zero iff this type contains some but not all of the basic type
    int bits;
    BasicTypeSubtype[] subtypes;
    function init(int bits,  BasicTypeSubtype[] subtypes = EMPTY_SUBTYPES) {
        self.bits = bits;
        self.subtypes = subtypes.cloneReadOnly();
    }
    public function includesAll(BasicTypeCode code) returns boolean {
        int c = code; // work around bug in slalpha4
        return (self.bits & (1 << c)) != 0;
    }
    public function includesNone(BasicTypeCode code) returns boolean {
        int c = code; // work around bug in slalpha4
        return (self.bits & (BT_SOME << c)) == 0;
    }
}

public final SemType NEVER = new SemType(0);
public final SemType NIL = new SemType(1 << BT_NIL);
public final SemType BOOLEAN = new SemType(1 << BT_BOOLEAN);
public final SemType INT = new SemType(1 << BT_INT);
public final SemType FLOAT = new SemType(1 << BT_FLOAT);
public final SemType DECIMAL = new SemType(1 << BT_DECIMAL);
public final SemType STRING = new SemType(1 << BT_STRING);
public final SemType ERROR = new SemType(1 << BT_ERROR);

// matches all functions
public final SemType FUNCTION = new SemType(1 << BT_FUNCTION);
public final SemType TYPEDESC = new SemType(1 << BT_TYPEDESC);
public final SemType HANDLE = new SemType(1 << BT_HANDLE);

public final SemType XML = new SemType((1 << BT_XML_RO) | (1 << BT_XML_RW));
public final SemType STREAM = new SemType(1 << BT_STREAM);
public final SemType FUTURE = new SemType(1 << BT_FUTURE);

// this is SubtypeData|error
public final SemType TOP = new SemType(BT_MASK);
public final SemType ANY = new SemType(BT_MASK & ~(1 << BT_ERROR));
public final SemType READONLY = new SemType(BT_READONLY);
public final SemType BYTE = intWidthUnsigned(8);

// Need this type to workaround slalpha4 bug.
// It has to be public to workaround another bug.
public type SubtypePairIterator object {
    public function next() returns record {| [BasicTypeCode, SubtypeData?, SubtypeData?] value; |}?;
};

class SubtypePairIteratorImpl {
    *object:Iterable;
    *SubtypePairIterator;
    private int i1;
    private int i2;
    private final BasicTypeSubtype[] t1;
    private final BasicTypeSubtype[] t2;
    private final int bits;

    function init(BasicTypeSubtype[] t1, BasicTypeSubtype[] t2, int bits) {
        self.i1 = 0;
        self.i2 = 0;
        self.t1 = t1;
        self.t2 = t2;
        self.bits = bits;
    }

    public function iterator() returns SubtypePairIterator {
        return self;
    }

    public function next() returns record {| [BasicTypeCode, SubtypeData?, SubtypeData?] value; |}? {
        while true {
            if self.i1 >= self.t1.length() {
                if self.i2 >= self.t2.length() {
                    break;
                }
                var [code, data2] = self.get2();
                self.i2 += 1;
                if self.include(code) {
                    return { value: [code, (), data2] };
                }
            }
            else if self.i2 >= self.t2.length() {
                var [code, data1] = self.get1();
                self.i1 += 1;
                if self.include(code) {
                    return { value: [code, data1, ()] };
                }
            }
            else {
                var [code1, data1] = self.get1();
                var [code2, data2] = self.get2();
                if code1 == code2 {
                    self.i1 += 1;
                    self.i2 += 1;
                    if self.include(code1) {    
                        return { value: [code1, data1, data2] };
                    }
                }
                else if code1 < code2 {
                    self.i1 += 1;
                    if self.include(code1) {
                        return { value: [code1, data1, ()] };
                    }
                }
                else {
                    self.i2 += 1;
                    if self.include(code2) {
                        return { value: [code2, (), data2] };
                    }
                }

            }
        }
        return ();
    } 

    private function include(BasicTypeCode code) returns boolean {
        int c = code;
        return (self.bits & (1 << c)) != 0;
    }

    private function get1() returns BasicTypeSubtype {
        return self.t1[self.i1];
    }

    private function get2() returns BasicTypeSubtype {
        return self.t2[self.i2];
    }
}


public function union(SemType t1, SemType t2) returns SemType {
    int bits1 = t1.bits;
    int bits2 = t2.bits;
    int all = (t1.bits | t2.bits) & BT_MASK;
    int some = ((t1.bits | t2.bits) >> BT_COUNT) & BT_MASK;
    some &= ~all;
    if some == 0 {
        return new SemType(all);
    }
    int bits = all | (some << BT_COUNT);
    BasicTypeSubtype[] subtypes = [];
    foreach var [code, data1, data2] in new SubtypePairIteratorImpl(t1.subtypes, t2.subtypes, some) {
        SubtypeData data;
        if data1 is () {
            data = <SubtypeData>data2; // if they are both null, something's gone wrong
        }
        else if data2 is () {
            data = data1;
        }
        else {
            var union = ops[code].union;
            data = union(data1, data2);
        }
        if data == true {
            int c = code;
            bits &= ~(1 << (c + BT_COUNT));
            bits |= 1 << c;
        }
        else {
            subtypes.push([code, data]);
        }
    }
    return new SemType(bits, subtypes.cloneReadOnly());
}

public function intersect(SemType t1, SemType t2) returns SemType {
    int bits1 = t1.bits;
    int bits2 = t2.bits;
    if bits1 == BT_MASK {
        return t2;
    }
    if bits1 == 0 {
        return t1;
    }
    if bits2 == BT_MASK {
        return t1;
    }
    if bits2 == 0 {
        return t2;
    }
    int all = (t1.bits & t2.bits) & BT_MASK;

    // some(t1 & t2) = some(t1) & some(t2)
    int some = ((t1.bits >> BT_COUNT) | t1.bits) & ((t2.bits >> BT_COUNT) | t2.bits) & BT_MASK;
    some &= ~all;
    if some == 0 {
        return new SemType(all);
    }
    int bits = all | (some << BT_COUNT);
    BasicTypeSubtype[] subtypes = [];
    foreach var [code, data1, data2] in new SubtypePairIteratorImpl(t1.subtypes, t2.subtypes, some) {
        SubtypeData data;
        if data1 is () {
            data = <SubtypeData>data2;
        }
        else if data2 is () {
            data = data1;
        }
        else {
            var intersect = ops[code].intersect;
            data = intersect(data1, data2);
        }
        if data == false {
            int c = code;
            bits &= ~(1 << (c + BT_COUNT));
        }
        else {
            subtypes.push([code, data]);
        }
    }
    return new SemType(bits, subtypes.cloneReadOnly());    
}

public function diff(SemType t1, SemType t2) returns SemType {
    int bits1 = t1.bits;
    int bits2 = t2.bits;

    // all(t1 \ t2) = all(t1) & not(all(t2)|some(t2))
    int all = bits1 & ~(bits2 | (bits2 >> BT_COUNT)) & BT_MASK;
    // some(t1 \ t2) = some(t1) & not(all(t2))
    int some = (((t1.bits >> BT_COUNT) | t1.bits) & ~t2.bits) & BT_MASK;
    some &= ~all;

    if some == 0 {
        return new SemType(all);
    }
    int bits = all | (some << BT_COUNT); 
    BasicTypeSubtype[] subtypes = [];
    foreach var [code, data1, data2] in new SubtypePairIteratorImpl(t1.subtypes, t2.subtypes, some) {
        SubtypeData data;
        if data1 is () {
            var complement = ops[code].complement;
            data = complement(<SubtypeData>data2);
        }
        else if data2 is () {
            data = data1;
        }
        else {
            var diff = ops[code].diff;
            data = diff(data1, data2);
        }
         if data == false {
            int c = code;
            bits &= ~(1 << (c + BT_COUNT));
        }
        else {
            subtypes.push([code, data]);
        }
    }
    return new SemType(bits, subtypes.cloneReadOnly());        
}

public function complement(SemType t) returns SemType {
    return diff(TOP, t);
}

public function isNever(SemType t) returns boolean {
    // neither all nor part of any basic type
    return t.bits == 0;
}

public function isEmpty(TypeCheckContext tc, SemType t) returns boolean {
    if isNever(t) {    
        return true;
    }
    if (t.bits & BT_MASK) != 0 {
        // includes all of one or more basic types
        return false;
    }
    foreach var st in t.subtypes {
        var [code, data] = st;
        var isEmpty = ops[code].isEmpty;
        if !isEmpty(tc, data) {
            return false;
        }
    }
    return true;
}
    
public function isSubtype(TypeCheckContext tc, SemType t1, SemType t2) returns boolean { 
    return isEmpty(tc, diff(t1, t2));
}

public function isReadOnly(SemType t) returns boolean {
    return (t.bits & (BT_RW_MASK | (BT_RW_MASK << BT_COUNT))) == 0;
}

public function typeCheckContext(Env env) returns TypeCheckContext {
    return {
        listDefs: env.listDefs.cloneReadOnly(),
        mappingDefs: env.mappingDefs.cloneReadOnly(),
        functionDefs: env.functionDefs.cloneReadOnly()
    };
}

public function createJson(Env env) returns SemType {
    ListDefinition listDef = new;
    MappingDefinition mapDef = new;
    SemType simple = new((1 << BT_NIL) | (1 << BT_BOOLEAN) | (1 << BT_INT)| (1 << BT_FLOAT)| (1 << BT_DECIMAL)| (1 << BT_STRING));
    SemType j = union(simple, union(listDef.getSemType(env), mapDef.getSemType(env)));
    _ = listDef.define(env, [], j);
    _ = mapDef.define(env, [], j);
    return j;
}

final readonly & BasicTypeOps[] ops;

function init() {
    ops = [
        {}, // nil
        booleanOps, // boolean
        intOps, // int
        {}, // float
        {}, // decimal
        stringOps, // string
        {}, // error
        functionOps,  // function
        {}, // typedesc
        {}, // handle
        {}, // RO xml
        listOps, // RO list
        mappingOps, // RO mapping
        {}, // RO table
        {}, // RO object
        {}, // RW xml
        listOps, // RW list
        mappingOps, // RW mapping
        {}, // RW table
        {}, // RW object
        {}, // RW stream
        {} // RW future
   ];
}
