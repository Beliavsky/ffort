module intrinsic_registry
    use, intrinsic :: iso_fortran_env, only: error_unit
    use string_utils_mod, only: to_lower
    use ieee_intrinsic_module, only: is_ieee_function, is_ieee_subroutine, &
        ieee_function_return_type
    implicit none
    private

    ! Public interfaces
    public :: is_intrinsic_function
    public :: is_intrinsic_subroutine
    public :: get_intrinsic_signature
    public :: get_intrinsic_info
    public :: initialize_intrinsic_registry

    ! Intrinsic function signature type
    type, public :: intrinsic_signature_t
        character(len=:), allocatable :: name
        character(len=:), allocatable :: return_type
        character(len=:), allocatable :: arg_types
        character(len=:), allocatable :: description
    end type intrinsic_signature_t

    ! Registry storage
    type(intrinsic_signature_t), allocatable :: intrinsic_functions(:)
    logical :: registry_initialized = .false.
    integer, parameter :: MAX_INTRINSIC_SUBROUTINE_NAME_LEN = 32
    integer, parameter :: NUM_INTRINSIC_SUBROUTINES = 44
    character(len=MAX_INTRINSIC_SUBROUTINE_NAME_LEN), parameter :: &
        intrinsic_subroutine_names(NUM_INTRINSIC_SUBROUTINES) = &
        [character(len=MAX_INTRINSIC_SUBROUTINE_NAME_LEN) :: &
        "c_f_pointer", "c_f_procpointer", &
        "cpu_time", "date_and_time", &
        "execute_command_line", "get_command", &
        "get_command_argument", "getcwd", &
        "get_environment_variable", "move_alloc", &
        "random_init", "random_number", &
        "random_seed", "system_clock", &
        "sync_all", "sync_images", &
        "sync_memory", "lock", "unlock", &
        "event_post", "event_wait", &
        "event_query", "form_team", &
        "change_team", "end_team", &
        "co_broadcast", "co_sum", &
        "co_max", "co_min", "co_reduce", &
        "co_allgather", "co_gather", &
        "co_scatter", "atomic_define", &
        "atomic_ref", "atomic_cas", &
        "atomic_add", "atomic_and", &
        "atomic_or", "atomic_xor", &
        "atomic_fetch_add", &
        "atomic_fetch_and", &
        "atomic_fetch_or", &
        "atomic_fetch_xor"]

contains

    ! Combined function to get intrinsic information efficiently
    subroutine get_intrinsic_info(name, is_intrinsic, signature)
        character(len=*), intent(in) :: name
        logical, intent(out) :: is_intrinsic
        character(len=:), allocatable, intent(out) :: signature
        integer :: i
        character(len=:), allocatable :: lowered_name

        if (.not. registry_initialized) call initialize_intrinsic_registry()

        is_intrinsic = .false.
        if (allocated(signature)) deallocate (signature)
        if (len_trim(name) == 0) return
        lowered_name = to_lower(trim(name))

        if (is_ieee_function(lowered_name)) then
            is_intrinsic = .true.
            signature = ieee_function_return_type(lowered_name)//"(real)"
            return
        end if

        if (.not. allocated(intrinsic_functions)) return

        do i = 1, size(intrinsic_functions)
            if (intrinsic_functions(i)%name == lowered_name) then
                is_intrinsic = .true.
                signature = intrinsic_functions(i)%return_type//"("// &
                    intrinsic_functions(i)%arg_types//")"
                return
            end if
        end do
    end subroutine get_intrinsic_info

    ! Check if a function name corresponds to an intrinsic function
    function is_intrinsic_function(name) result(is_intrinsic)
        character(len=*), intent(in) :: name
        logical :: is_intrinsic
        character(len=:), allocatable :: signature

        call get_intrinsic_info(name, is_intrinsic, signature)
    end function is_intrinsic_function

    function is_intrinsic_subroutine(name) result(is_intrinsic)
        character(len=*), intent(in) :: name
        logical :: is_intrinsic
        integer :: i

        is_intrinsic = .false.
        if (len_trim(name) == 0) return

        if (is_ieee_subroutine(name)) then
            is_intrinsic = .true.
            return
        end if

        if (len_trim(name) > MAX_INTRINSIC_SUBROUTINE_NAME_LEN) return

        do i = 1, size(intrinsic_subroutine_names)
            if (equals_case_insensitive_trimmed(name, &
                intrinsic_subroutine_names(i))) then
                is_intrinsic = .true.
                return
            end if
        end do
    end function is_intrinsic_subroutine

    pure logical function equals_case_insensitive_trimmed(text, literal) &
            result(is_equal)
        character(len=*), intent(in) :: text
        character(len=*), intent(in) :: literal

        integer :: i
        integer :: left_len, right_len
        integer :: left_code
        integer :: literal_code

        is_equal = .false.
        left_len = len_trim(text)
        right_len = len_trim(literal)
        if (left_len /= right_len) return
        if (left_len == 0) then
            is_equal = .true.
            return
        end if

        do i = 1, left_len
            left_code = iachar(text(i:i))
            if (left_code >= iachar('A') .and. left_code <= iachar('Z')) then
                left_code = left_code + 32
            end if

            literal_code = iachar(literal(i:i))
            if (literal_code /= left_code) return
        end do

        is_equal = .true.
    end function equals_case_insensitive_trimmed

    ! Get signature information for an intrinsic function
    function get_intrinsic_signature(name) result(signature)
        character(len=*), intent(in) :: name
        character(len=:), allocatable :: signature
        logical :: is_intrinsic

        call get_intrinsic_info(name, is_intrinsic, signature)
        if (.not. is_intrinsic) signature = ""
    end function get_intrinsic_signature

    ! Initialize the intrinsic function registry
    subroutine initialize_intrinsic_registry()
        integer, parameter :: NUM_INTRINSICS = 131
        integer :: i

        if (registry_initialized) return

        allocate (intrinsic_functions(NUM_INTRINSICS))
        i = 0

        call register_mathematical_intrinsics(i)
        call register_type_conversion_intrinsics(i)
        call register_array_intrinsics(i)
        call register_string_intrinsics(i)
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="lge", return_type="logical", arg_types="character,character", &
            description="ASCII lexical comparison")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="lgt", return_type="logical", arg_types="character,character", &
            description="ASCII lexical comparison")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="lle", return_type="logical", arg_types="character,character", &
            description="ASCII lexical comparison")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="llt", return_type="logical", arg_types="character,character", &
            description="ASCII lexical comparison")
        call register_variadic_intrinsics(i)
        call register_inquiry_intrinsics(i)
        call register_c_interop_intrinsics(i)
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="dprod", return_type="real", arg_types="real,real", &
            description="Elemental double precision product of default REAL operands")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="tand", return_type="real", arg_types="real", &
            description="Elemental tangent in degrees")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="atan2", return_type="real", arg_types="real,real", &
            description="Elemental quadrant-aware arctangent")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="digits", return_type="integer", arg_types="numeric", &
            description="Significant model digits inquiry")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="new_line", return_type="character", arg_types="character", &
            description="Character newline inquiry")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="rrspacing", return_type="real", arg_types="real", &
            description="Reciprocal relative model spacing")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="dble", return_type="real", arg_types="numeric", &
            description="Convert to double precision real")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="merge", return_type="numeric", arg_types="any,any,logical", &
            description="Elemental selection between matching source types")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="iand", return_type="integer", &
            arg_types="integer,integer", description="Bounded integer bit intrinsic")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="ior", return_type="integer", &
            arg_types="integer,integer", description="Bounded integer bit intrinsic")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="ieor", return_type="integer", &
            arg_types="integer,integer", description="Bounded integer bit intrinsic")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="not", return_type="integer", &
            arg_types="integer", description="Bounded integer bit intrinsic")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="btest", return_type="logical", &
            arg_types="integer,integer", description="Bounded integer bit intrinsic")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="bit_size", return_type="integer", &
            arg_types="integer", description="Bounded integer bit intrinsic")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="leadz", return_type="integer", arg_types="integer", &
            description="Leading zero bits at the declared INTEGER width")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="trailz", return_type="integer", arg_types="integer", &
            description="Trailing zero bits at the declared INTEGER width")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="maskl", return_type="integer", arg_types="integer", &
            description="Bounded width-aware integer masks and logical shift")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="maskr", return_type="integer", arg_types="integer", &
            description="Bounded width-aware integer masks and logical shift")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="shiftr", return_type="integer", arg_types="integer,integer", &
            description="Bounded width-aware integer masks and logical shift")

        if (i /= NUM_INTRINSICS) then
            write (error_unit, '(A)') &
                "ERROR [intrinsic_registry]: Intrinsic function count mismatch"
            write (error_unit, '(A)') "in initialization - registry may be incomplete"
        end if

        registry_initialized = .true.
    end subroutine initialize_intrinsic_registry

    subroutine register_mathematical_intrinsics(i)
        integer, intent(inout) :: i

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="sin", return_type="real", arg_types="real", &
            description="Sine function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="cos", return_type="real", arg_types="real", &
            description="Cosine function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="dcos", return_type="real", arg_types="real", &
            description="Double precision cosine function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="tan", return_type="real", arg_types="real", &
            description="Tangent function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="sqrt", return_type="real", arg_types="real", &
            description="Square root function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="exp", return_type="real", arg_types="real", &
            description="Exponential function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="log10", return_type="real", arg_types="real", &
            description="Base ten logarithm function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="log", return_type="real", arg_types="real", &
            description="Natural logarithm function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="erfc", return_type="real", arg_types="real", &
            description="Complementary error function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="abs", return_type="real", arg_types="real", &
            description="Absolute value function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="asin", return_type="real", arg_types="real", &
            description="Arc sine function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="acosd", return_type="real", arg_types="real", &
            description="Elemental degree trigonometric function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="asind", return_type="real", arg_types="real", &
            description="Elemental degree trigonometric function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="sind", return_type="real", arg_types="real", &
            description="Elemental degree trigonometric function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="cosd", return_type="real", arg_types="real", &
            description="Elemental degree trigonometric function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="acos", return_type="real", arg_types="real", &
            description="Arc cosine function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="atan", return_type="real", arg_types="real", &
            description="Arc tangent function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="sign", return_type="real", &
            arg_types="real,real", &
            description="Sign transfer function")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="dim", return_type="real", arg_types="real,real", &
            description="Elemental positive difference")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="log_gamma", return_type="real", arg_types="real", &
            description="Elemental logarithm of absolute gamma")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t(name="aint", return_type="real", &
            arg_types="real", description="Elemental real rounding/inverse hyperbolic")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t(name="anint", return_type="real", &
            arg_types="real", description="Elemental real rounding/inverse hyperbolic")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t(name="asinh", return_type="real", &
            arg_types="real", description="Elemental real rounding/inverse hyperbolic")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t(name="acosh", return_type="real", &
            arg_types="real", description="Elemental real rounding/inverse hyperbolic")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t(name="fraction", return_type="real", &
            arg_types="real", description="Model fraction")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t(name="exponent", return_type="integer", &
            arg_types="real", description="Model exponent")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t(name="set_exponent", return_type="real", &
            arg_types="real,integer", description="Set model exponent")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t(name="iachar", return_type="integer", &
            arg_types="character", description="ASCII character code")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="spacing", return_type="real", arg_types="real", &
            description="Elemental model spacing")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="nearest", return_type="real", arg_types="real,real", &
            description="Elemental adjacent representable real")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="isnan", return_type="logical", arg_types="real", &
            description="GNU extension: elemental IEEE NaN predicate")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="erfc_scaled", return_type="real", arg_types="real", &
            description="Elemental exponentially scaled complementary error function")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="erf", return_type="real", arg_types="real", &
            description="Elemental error or Bessel function")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="bessel_j0", return_type="real", arg_types="real", &
            description="Elemental error or Bessel function")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="bessel_j1", return_type="real", arg_types="real", &
            description="Elemental error or Bessel function")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="bessel_jn", return_type="real", arg_types="integer,real", &
            description="Elemental error or Bessel function")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="bessel_y0", return_type="real", arg_types="real", &
            description="Elemental error or Bessel function")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="bessel_y1", return_type="real", arg_types="real", &
            description="Elemental error or Bessel function")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="bessel_yn", return_type="real", arg_types="integer,real", &
            description="Elemental error or Bessel function")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="sinh", return_type="real", arg_types="real", &
            description="Elemental real hyperbolic function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="cosh", return_type="real", arg_types="real", &
            description="Elemental real hyperbolic function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="tanh", return_type="real", arg_types="real", &
            description="Elemental real hyperbolic function")

    end subroutine register_mathematical_intrinsics

    subroutine register_type_conversion_intrinsics(i)
        integer, intent(inout) :: i

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="int", return_type="integer", arg_types="real", &
            description="Convert to integer")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="uint", return_type="unsigned_integer", &
            arg_types="integer", &
            description="Convert to unsigned integer")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="real", return_type="real", &
            arg_types="integer", &
            description="Convert to real")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="nint", return_type="integer", &
            arg_types="real", &
            description="Nearest integer")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="floor", return_type="integer", &
            arg_types="real", &
            description="Floor function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="ceiling", return_type="integer", &
            arg_types="real", &
            description="Ceiling function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="cmplx", return_type="complex", &
            arg_types="numeric,numeric", &
            description="Convert to complex")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="aimag", return_type="real", &
            arg_types="complex", &
            description="Imaginary part of complex")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="wrap_add", return_type="unsigned_integer", &
            arg_types="unsigned_integer,unsigned_integer", &
            description="Wraparound unsigned addition")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="wrap_sub", return_type="unsigned_integer", &
            arg_types="unsigned_integer,unsigned_integer", &
            description="Wraparound unsigned subtraction")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="wrap_mul", return_type="unsigned_integer", &
            arg_types="unsigned_integer,unsigned_integer", &
            description="Wraparound unsigned multiplication")
    end subroutine register_type_conversion_intrinsics

    subroutine register_array_intrinsics(i)
        integer, intent(inout) :: i

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="size", return_type="integer", &
            arg_types="array", &
            description="Array size")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="sum", return_type="numeric", &
            arg_types="array", &
            description="Array sum")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="maxval", return_type="numeric", &
            arg_types="array", &
            description="Array maximum value")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="minval", return_type="numeric", &
            arg_types="array", &
            description="Array minimum value")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="shape", return_type="array", &
            arg_types="array", &
            description="Array shape")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="eoshift", return_type="array", &
            arg_types="array,integer,array,integer", &
            description="End-off shift preserving ARRAY type and rank")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="cshift", return_type="array", &
            arg_types="array,integer,integer", &
            description="Circular shift preserving ARRAY type and rank")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="reshape", return_type="array", &
            arg_types="array,integer_array", &
            description="Reshape array to new dimensions")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="dot_product", return_type="numeric", &
            arg_types="array,array", &
            description="Dot product of two vectors")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="matmul", return_type="array", &
            arg_types="array,array", &
            description="Matrix multiplication")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="transpose", return_type="array", &
            arg_types="array", &
            description="Matrix transpose")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="norm2", return_type="real", &
            arg_types="array,integer", &
            description="Euclidean norm of REAL ARRAY, optionally along DIM")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="product", return_type="numeric", &
            arg_types="array", &
            description="Product of array elements")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="any", return_type="logical", &
            arg_types="logical_array", &
            description="True if any element is true")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="all", return_type="logical", &
            arg_types="logical_array", &
            description="True if all elements are true")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="parity", return_type="logical", &
            arg_types="logical_array", &
            description="True for an odd number of true array elements")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="count", return_type="integer", &
            arg_types="logical_array", &
            description="Number of true elements in array")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="minloc", return_type="array", &
            arg_types="array", &
            description="Location of minimum value")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="maxloc", return_type="array", &
            arg_types="array", &
            description="Location of maximum value")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="findloc", return_type="array", &
            arg_types="array,value", &
            description="Location of matching array value")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="pack", return_type="array", &
            arg_types="array,logical_array", &
            description="Pack array into vector")
    end subroutine register_array_intrinsics

    subroutine register_string_intrinsics(i)
        integer, intent(inout) :: i

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="char", return_type="character", arg_types="integer", &
            description="Elemental character from collating-sequence code")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="achar", return_type="character", arg_types="integer", &
            description="Elemental character from ASCII code")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="len", return_type="integer", &
            arg_types="character", &
            description="String length")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="len_trim", return_type="integer", &
            arg_types="character", &
            description="Trimmed string length")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="trim", return_type="character", &
            arg_types="character", &
            description="Remove trailing blanks")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="adjustl", return_type="character", &
            arg_types="character", &
            description="Adjust left")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="adjustr", return_type="character", &
            arg_types="character", &
            description="Adjust right")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="index", return_type="integer", &
            arg_types="character,character", &
            description="Substring position")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="scan", return_type="integer", &
            arg_types="character,character", &
            description="Position of a character in a set")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="verify", return_type="integer", &
            arg_types="character,character", &
            description="Position of a character outside a set")
        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="repeat", return_type="character", &
            arg_types="character,integer", &
            description="Scalar string repetition")
    end subroutine register_string_intrinsics

    subroutine register_variadic_intrinsics(i)
        integer, intent(inout) :: i

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="min", return_type="numeric", &
            arg_types="numeric,numeric,...", &
            description="Minimum value")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="max", return_type="numeric", &
            arg_types="numeric,numeric,...", &
            description="Maximum value")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="mod", return_type="numeric", &
            arg_types="numeric,numeric", &
            description="Modulo function")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="modulo", return_type="numeric", &
            arg_types="numeric,numeric", &
            description="Modulo function")
    end subroutine register_variadic_intrinsics

    subroutine register_inquiry_intrinsics(i)
        integer, intent(inout) :: i

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="present", return_type="logical", &
            arg_types="any", &
            description="Check if optional argument is present")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="precision", return_type="integer", &
            arg_types="real", &
            description="Decimal precision")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="allocated", return_type="logical", &
            arg_types="allocatable", &
            description="Check if allocatable variable is "// &
            "allocated")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="associated", return_type="logical", &
            arg_types="pointer", &
            description="Check if a pointer or procedure pointer is "// &
            "associated")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="huge", return_type="numeric", &
            arg_types="numeric", &
            description="Largest number of the kind")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="epsilon", return_type="real", &
            arg_types="real", &
            description="Machine epsilon")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="tiny", return_type="real", arg_types="real", &
            description="Smallest positive model number of the kind")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="radix", return_type="integer", arg_types="numeric", &
            description="Base of the numeric model")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="minexponent", return_type="integer", arg_types="real", &
            description="Minimum exponent of the real model")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="maxexponent", return_type="integer", arg_types="real", &
            description="Maximum exponent of the real model")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="kind", return_type="integer", &
            arg_types="any", &
            description="Kind type parameter value")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="selected_real_kind", return_type="integer", &
            arg_types="integer", &
            description="Real kind for precision, range and radix")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="selected_int_kind", return_type="integer", &
            arg_types="integer", &
            description="Integer kind for range")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="lbound", return_type="array", &
            arg_types="array", &
            description="Lower bounds of array")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="ubound", return_type="array", &
            arg_types="array", &
            description="Upper bounds of array")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="null", return_type="pointer", &
            arg_types="", &
            description="Disassociated pointer or unallocated "// &
            "allocatable")
    end subroutine register_inquiry_intrinsics

    subroutine register_c_interop_intrinsics(i)
        integer, intent(inout) :: i

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="c_loc", return_type="c_ptr", &
            arg_types="any", &
            description="C address of a target argument")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="c_funloc", return_type="c_funptr", &
            arg_types="any", &
            description="C address of a procedure argument")

        i = i + 1
        intrinsic_functions(i) = intrinsic_signature_t( &
            name="c_associated", return_type="logical", &
            arg_types="c_ptr", &
            description="C pointer association status")
    end subroutine register_c_interop_intrinsics

end module intrinsic_registry
