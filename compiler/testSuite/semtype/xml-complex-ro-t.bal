type X xml;
type RX readonly & X;

type N xml<never>;
type T xml:Text;
type E readonly & xml:Element;
type P readonly & xml:ProcessingInstruction;
type C readonly & xml:Comment;
type XE xml<E>;
type XP xml<P>;
type XC xml<C>;

type ReadOnlyFlat T|E|P|C;

// @type NonEmptyRoSingletons < ReadOnlyFlat
// @type NonEmptyRoSingletons <> T
// @type NonEmptyRoSingletons <> N
// @type E < NonEmptyRoSingletons
// @type P < NonEmptyRoSingletons
// @type C < NonEmptyRoSingletons
type NonEmptyRoSingletons ReadOnlyFlat & !N;

// @type NonEmptyRoSingletons < UX
type UX XE|XP|XC|T;

// @type XNonEmptySingletons = RX
// @type XNonEmptySingletons < X
type XofNonEmptySingletons xml<NonEmptyRoSingletons>;

// @type XUX = RX
type XUX xml<UX>;

type NEVER never;
type RWX X & !readonly;

// @type RX_MINUS_RO = NEVER
type RX_MINUS_RO RX & RWX;

// @type RX_UNION_RO = X
type RX_UNION_RO RX | RWX;

// @type NonReadonlyRoElementSeq = NEVER
type NonReadonlyRoElementSeq xml<E> & !readonly;

// @type NonReadonlyEmptySeq = NEVER
type NonReadonlyEmptySeq N & !readonly;
