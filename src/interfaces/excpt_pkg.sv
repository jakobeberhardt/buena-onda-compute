package excpt_pkg;

typedef enum logic [2:0] {
    NO_EXCEPTION,
    INVALID_ADDR,
    UNALIGNED_ACCESS,
    OVERFLOW,
    DIVIDE_BY_ZERO
} excpt_t;
endpackage : excpt_pkg
