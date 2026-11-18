! SPDX-License-Identifier: MIT
module fi_ir
    use, intrinsic :: iso_fortran_env, only: int64, real32, real64, host_output_unit => output_unit
    use fi_limits, only: max_symbols, max_procedures, max_generics
    implicit none
    private
    public :: is_bounds_inquiry, valid_bounds_inquiry
    public :: valid_component_initializer, valid_component_defaults, max_derived_character_bytes
    public :: valid_matrix_intrinsic
    public :: valid_character_len_variable, bare_character_gather_input, bare_numeric_gather_input, bare_gather_input
    public :: module_actual_conflict, module_symbol_visible, module_write_target
    public :: op_pointer_assign, op_nullify, op_random_seed, valid_saved_local
    public :: valid_allocation_group, valid_allocation_output, valid_allocation_message, max_allocation_objects
    public :: valid_internal_procedure, host_symbol_visible, internal_call_visible
    public :: valid_automatic_bound, valid_dummy_bound, shape_size, bound_constant_expression
    public :: component_value_t, record_value_t, value_t, expr_t, symbol_t, instruction_t, program_t, diagnostic_t, procedure_t
    public :: ty_integer, ty_real, ty_logical, ty_character
    public :: ty_derived_base, is_derived_type, derived_type_t, operator_t, max_types, max_operators
    public :: ex_record, ex_component, op_write_internal, op_write_defined, op_stop
    public :: ex_substring, ex_gather_rows
    public :: ex_literal, ex_variable, ex_unary, ex_binary, ex_call, ex_element, ex_section, ex_user_call, ex_constructor
    public :: op_select, op_case, op_exit, op_cycle, op_allocate, op_deallocate, op_forall, op_where, op_elsewhere
    public :: op_assign, op_print, op_branch, op_jump, op_do, op_next, op_call, op_return, op_error_stop, op_random_number
    public :: max_symbols, max_expressions, max_instructions, max_array_elements, max_procedures, max_modules, fail, lower
    public :: constructor_length_item_supported, valid_constructor_character_metadata
    public :: valid_constructor_tree, valid_constructor_do, valid_constructor_index, ex_constructor_do, ex_constructor_index, max_constructor_do_depth
    public :: valid_output_do, ex_output_do, max_output_do_depth
    public :: valid_timing_query, op_timing_query
    public :: valid_move_alloc, op_move_alloc
    public :: valid_process_query, op_process_query
    public :: valid_internal_read, op_read_internal, valid_external_read, op_read_external
    public :: valid_external_read_element, valid_internal_read_element
    public :: valid_backspace, op_backspace, valid_inquire_name, op_inquire_name
    public :: valid_stdout_unit, processor_output_unit, valid_runtime_output_unit, valid_internal_write_element, valid_internal_write_values
    public :: valid_intrinsic_import, valid_character_length_dummy, valid_scalar_character_allocatable
    public :: is_degree_trig, is_erf_bessel
    public :: is_numeric_model_inquiry, exponent_inquiry_operand_supported
    public :: is_bit_intrinsic, valid_bit_intrinsic, valid_bit_variable
    public :: is_lexical_intrinsic, is_character_intrinsic, is_character_search_intrinsic
    public :: is_location_reduction, is_logical_reduction, is_array_reduction, is_array_transform, generic_t, max_generics
    integer, parameter :: processor_output_unit=host_output_unit
    integer, parameter :: ty_derived_base=100, max_types=16, max_operators=64
    integer, parameter :: ex_record=10, ex_component=11, op_write_internal=13, op_stop=14, op_write_defined=15
    integer, parameter :: ty_integer=1, ty_real=2, ty_logical=3, ty_character=4
    integer, parameter :: ex_literal=1, ex_variable=2, ex_unary=3, ex_binary=4, ex_call=5, &
        ex_element=6, ex_section=7, ex_user_call=8, &
        ex_constructor=9, ex_substring=12, ex_gather_rows=13
    integer, parameter :: op_assign=1, op_print=2, op_branch=3, op_jump=4, op_do=5, op_next=6, op_call=7, &
        op_return=8, op_error_stop=9, &
        op_random_number=10, op_select=11, op_case=12, op_exit=16, op_cycle=17, op_allocate=18, op_deallocate=19, op_forall=20, op_where=21, op_elsewhere=22
    integer, parameter :: op_pointer_assign=23, op_nullify=24, op_random_seed=25, op_read_internal=26, op_process_query=27, op_read_external=28, op_backspace=30
    integer, parameter :: op_timing_query=31, op_inquire_name=32
    integer, parameter :: op_move_alloc=29
    integer, parameter :: ex_constructor_do=15, ex_constructor_index=16, max_constructor_do_depth=8
    integer, parameter :: ex_output_do=14, max_output_do_depth=8
    integer, parameter :: max_allocation_objects=64
    integer, parameter :: max_expressions=10000, max_instructions=4000
    ! Rebuild after changing this single array-storage/result/actual cap.
    ! 1e6 is the measured default; 1e7 is an opt-in high-memory configuration.
    ! See docs/ARRAY-LIMITS.md for live-region/copy costs and work budgets.
    ! Keep below HUGE(default INTEGER); runtime offsets use default INTEGER.
    integer, parameter :: max_array_elements=1000000
    ! Conservative reservation cap, not exact heap usage. Rebuild to adjust.
    integer(int64), parameter :: max_derived_character_bytes=16_int64*1024_int64*1024_int64
    integer, parameter :: max_modules=16
    integer, parameter :: max_module_uses=max_modules*(max_modules+1)/2
    ! Components are deliberately nonrecursive: this release admits intrinsic scalar fields only.
    type :: component_value_t
        integer :: tag=0,real_kind=4
        integer(int64) :: i=0_int64
        real(real64) :: r=0.0_real64
        logical :: l=.false.
        character(:), allocatable :: s
    end type
    ! Scalar allocatable indirection keeps derived-only array descriptors out of
    ! every numeric/logical/CHARACTER element. Intrinsic assignment deep-copies
    ! the optional payload, preserving value semantics for derived objects.
    type :: record_value_t
        type(component_value_t), allocatable :: components(:)
        logical, allocatable :: component_defined(:)
    end type
    type :: value_t
        integer :: tag=0, real_kind=4
        integer(int64) :: i=0_int64
        real(real64) :: r=0.0_real64
        logical :: l=.false.
        character(:), allocatable :: s
        type(record_value_t), allocatable :: record
    end type
    type :: expr_t
        integer :: kind=0, typ=0, line=0, column=0, scope=0, real_kind=4
        integer :: rank=0, character_len=-1, length_expr=0, generic_id=0
        ! Explicit numeric empty-constructor KIND selector, independently bound to source.
        integer :: constructor_kind_expr=0
        ! Lexical owner identity only; never a recursive expression-tree edge.
        integer :: constructor_owner=0
        logical :: parenthesized=.false.
        integer :: bound_type=0, bound_binding=0
        ! CSHIFT uses ARRAY/SHIFT/DIM bits 0/1/2.
        ! Optional intrinsic slots, packed in formal order: SELECTED_REAL_KIND P/R/RADIX;
        ! logical reductions MASK/DIM/KIND (KIND only for COUNT); RESHAPE SOURCE/SHAPE/PAD/ORDER.
        integer :: intrinsic_mask=0
        integer(int64) :: extent=0_int64, dims(3)=0_int64
        integer :: left=0, right=0, symbol=0, stride=0
        integer :: left2=0, right2=0, stride2=0
        integer :: left3=0, right3=0, stride3=0, third=0
        logical :: triplet(3)=[.true.,.false.,.false.]
        character(32) :: op=''
        integer, allocatable :: args(:)
        ! ex_substring: third>0 names an ex_element base; otherwise
        ! symbol>0 selects a scalar variable; symbol=0 stores
        ! the immutable literal CHARACTER base in value (bounds remain left/right).
        type(value_t) :: value
    end type
    type :: symbol_t
        character(63) :: name=''
        ! Remote ISO_FORTRAN_ENV entity; local NAME may be an ONLY-list alias.
        character(63) :: intrinsic_import=''
        integer :: typ=0, line=0, column=0, real_kind=4
        integer :: rank=0, lower_expr=0, upper_expr=0, lower_expr2=0, upper_expr2=0, lower_expr3=0, upper_expr3=0
        integer(int64) :: lower_bound=1_int64, upper_bound=1_int64
        integer(int64) :: lower_bound2=1_int64, upper_bound2=1_int64
        integer(int64) :: lower_bound3=1_int64, upper_bound3=1_int64
        integer :: scope=0, dummy_intent=0
        logical :: assumed_shape=.false., is_optional=.false., is_automatic=.false., is_allocatable=.false.
        logical :: is_dummy=.false., is_public=.true., is_intrinsic=.false., is_class=.false.
        logical :: is_target=.false., is_pointer=.false.
        logical :: is_parameter=.false., parameter_ready=.false., deferred_character=.false., is_saved=.false.
        integer :: initializer_expr=0, kind_expr=0, character_len=-1, length_expr=0
        type(value_t) :: constant_value
        type(value_t), allocatable :: constant_values(:)
    end type
    ! OP_DO/OP_NEXT D=0: counted; D=1: bare, with SYMBOL and controls zero.
    ! Multi-object ALLOCATE/DEALLOCATE: adjacent object instructions have C=count,
    ! D=one-based ordinal, TARGET=first+count. Single objects retain zero fields.
    type :: instruction_t
        character(63) :: construct_name=""
        integer :: op=0, line=0, column=0, scope=0
        integer :: symbol=0, a=0, b=0, c=0, d=0, target=0, component=0, generic_id=0, third=0
        integer :: bound_type=0, bound_binding=0
        integer, allocatable :: items(:)
        character(:), allocatable :: format
        integer :: format_expr=0, advance_mode=0 ! 0: advancing; 1: nonadvancing stdout WRITE
    end type
    type :: procedure_t
        character(63) :: name='', module_name=''
        logical :: is_subroutine=.false., is_pure=.false., is_simple=.false., is_public=.true.
        logical :: has_pure_prefix=.false., has_impure_prefix=.false., is_elemental=.false., is_recursive=.false.
        integer :: module_id=0, parent_procedure=0, result_symbol=0, first=0, last=0
        integer :: line=0, column=0, end_line=0, end_column=0
        integer, allocatable :: args(:)
    end type
    type :: derived_type_t
        character(63) :: name=""
        integer :: module_id=0,line=0,column=0,end_line=0,end_column=0,ncomponents=0
        logical :: is_public=.true.
        character(63) :: component_names(16)=""
        integer :: component_types(16)=0,component_kinds(16)=4
        integer :: component_lines(16)=0,component_columns(16)=0
        integer :: component_initializers(16)=0
        integer :: component_lengths(16)=-1,component_length_exprs(16)=0
        integer :: nbindings=0, binding_procedures(16)=0, binding_lines(16)=0, binding_columns(16)=0
        character(63) :: binding_names(16)="", binding_targets(16)=""
        logical :: binding_public(16)=.true.
        character(63) :: write_binding=""
        integer :: write_procedure=0, write_line=0, write_column=0
    end type
    type :: operator_t
        character(16) :: op=""
        integer :: module_id=0,line=0,column=0,nprocedures=0
        logical :: is_public=.true.
        character(63) :: procedure_names(16)=""
        integer :: procedures(16)=0
    end type
    type :: generic_t
        character(63) :: name=''
        integer :: module_id=0, line=0, column=0, nprocedures=0
        logical :: is_public=.true.
        character(63) :: procedure_names(16)=''
        integer :: procedures(16)=0
    end type
    type :: program_t
        character(63) :: name=''
        integer :: end_line=0, end_column=0
        type(symbol_t), allocatable :: symbols(:)
        type(expr_t), allocatable :: expressions(:)
        type(instruction_t), allocatable :: code(:)
        integer :: ns=0, ne=0, nc=0
        type(derived_type_t) :: derived_types(max_types)
        type(operator_t) :: operators(max_operators)
        type(generic_t), allocatable :: generics(:)
        integer :: nt=0,no=0,ng=0
        type(procedure_t), allocatable :: procedures(:)
        character(63) :: modules(max_modules)=''
        integer :: uses(max_module_uses)=0, use_lines(max_module_uses)=0
        integer :: use_scopes(max_module_uses)=0
        integer :: np=0, nm=0, nu=0, entry_pc=1
        logical :: module_private(max_modules)=.false.
        logical :: use_only(max_module_uses)=.false.
        character(63), allocatable :: only_names(:,:)
        integer :: n_only(max_module_uses)=0
    end type
    type :: diagnostic_t
        integer :: code=0, line=0, column=0, stop_status=0
        character(:), allocatable :: message
    end type
contains
    pure logical function is_degree_trig(name)
        character(*),intent(in)::name
        is_degree_trig=name=='acosd'.or.name=='asind'.or.name=='sind'.or.name=='cosd'
    end function
    ! Internal list READ: A is the scalar CHARACTER file expression, B optional
    ! IOSTAT variable expression, ITEMS whole numeric/default CHARACTER variables.
    ! External READ: A is the scalar INTEGER unit expression, B optional IOSTAT,
    ! ITEMS one scalar CHARACTER variable, FORMAT a literal A-only format.
    ! Local unsaved procedure targets keep this operation free of external effects.
    ! Output-only control node, never a scalar value: SYMBOL is the local
    ! counter, LEFT/RIGHT/STRIDE are controls, ARGS are ordered output items.
    ! The neutral INTEGER metadata does not permit use in value expressions.
    logical function valid_constructor_index(prog,root) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root
        integer::o,s
        ok=.false.
        if(.not.allocated(prog%expressions).or..not.allocated(prog%symbols)) return
        if(root<1.or.root>prog%ne.or.prog%ne>size(prog%expressions)) return
        associate(x=>prog%expressions(root))
        if(x%kind/=ex_constructor_index.or.x%typ/=ty_integer.or.x%rank/=0.or.x%extent/=0.or. &
           any(x%dims/=0).or.(x%real_kind/=4.and.x%real_kind/=8).or.x%character_len/=-1.or. &
           x%scope<0.or.x%scope>prog%np.or.x%length_expr/=0.or.x%constructor_kind_expr/=0.or. &
           x%generic_id/=0.or.x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or. &
           x%left/=0.or.x%right/=0.or.x%stride/=0.or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or. &
           x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or.x%third/=0.or.len_trim(x%op)/=0.or. &
           allocated(x%args).or.x%value%tag/=0.or.x%value%i/=0.or.x%value%r/=0.or.x%value%l.or. &
           x%value%real_kind/=4.or.allocated(x%value%s).or.allocated(x%value%record).or. &
           any(x%triplet.neqv.[.true.,.false.,.false.])) return
        o=x%constructor_owner;s=x%symbol
        if(o<1.or.o>prog%ne.or.s<1.or.s>prog%ns.or.s>size(prog%symbols)) return
        if(prog%expressions(o)%kind/=ex_constructor_do.or.prog%expressions(o)%symbol/=s.or. &
           prog%expressions(o)%scope/=x%scope) return
        associate(v=>prog%symbols(s))
        if(v%typ/=ty_integer.or.v%rank/=0.or.v%is_parameter.or.v%is_intrinsic.or. &
           v%real_kind/=x%real_kind) return
        end associate
        end associate
        ok=.true.
    end function
    recursive logical function constructor_length_item_supported(prog,index,depth) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::index
        integer,intent(in),optional::depth
        integer::d,j,a,s
        logical::dynamic
        ok=.false.;d=0
        if(present(depth)) d=depth
        if(d<0.or.d>256.or..not.allocated(prog%expressions).or..not.allocated(prog%symbols)) return
        if(index<1.or.index>prog%ne.or.index>size(prog%expressions)) return
        associate(x=>prog%expressions(index))
        if(x%typ/=ty_character.or.x%real_kind/=4.or.x%rank<0.or.x%rank>1) return
        if(x%character_len>=0.and.x%character_len<=65536) then
            ok=.true.;return
        end if
        if(x%character_len/=-1) return
        select case(x%kind)
        case(ex_variable,ex_element,ex_section)
            s=x%symbol
            if(s<1.or.s>prog%ns.or.s>size(prog%symbols)) return
            associate(v=>prog%symbols(s))
            if(v%typ/=ty_character.or.v%real_kind/=4.or.v%character_len/=-1.or.v%is_pointer.or.v%is_class) return
            if(x%kind==ex_variable.and.x%rank/=v%rank) return
            if(x%kind==ex_element.and.(x%rank/=0.or.v%rank<1)) return
            if(x%kind==ex_section.and.(x%rank/=1.or.v%rank<1)) return
            end associate
        case(ex_binary)
            if(x%op/='//') return
            if(.not.constructor_length_item_supported(prog,x%left,d+1)) return
            if(.not.constructor_length_item_supported(prog,x%right,d+1)) return
            if(prog%expressions(x%left)%character_len>=0.and.prog%expressions(x%right)%character_len>=0) return
        case(ex_constructor,ex_constructor_do)
            if(x%op/=''.or..not.allocated(x%args)) return
            if(size(x%args)<1.or.size(x%args)>max_expressions) return
            dynamic=.false.
            do j=1,size(x%args)
                a=x%args(j)
                if(.not.constructor_length_item_supported(prog,a,d+1)) return
                if(prog%expressions(a)%character_len<0) dynamic=.true.
            end do
            if(.not.dynamic) return
        case default
            ! Data-dependent TRIM, substring bounds, function-result lengths and
            ! other calls remain outside this descriptor-only length contract.
            return
        end select
        end associate
        ok=.true.
    end function
    logical function valid_constructor_character_metadata(prog,index) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::index
        integer::j,a,known,expected
        logical::dynamic
        ok=.false.
        if(.not.allocated(prog%expressions)) return
        if(index<1.or.index>prog%ne.or.index>size(prog%expressions)) return
        associate(x=>prog%expressions(index))
        if(x%kind/=ex_constructor.and.x%kind/=ex_constructor_do) return
        if(x%typ/=ty_character.or.x%real_kind/=4.or..not.allocated(x%args)) return
        if(x%op=='character') then
            ok=x%character_len>=0.and.x%character_len<=65536;return
        end if
        if(x%op/=''.or.x%length_expr/=0.or.size(x%args)<1.or.size(x%args)>max_expressions) return
        known=-1;dynamic=.false.
        do j=1,size(x%args)
            a=x%args(j)
            if(.not.constructor_length_item_supported(prog,a)) return
            expected=prog%expressions(a)%character_len
            if(expected<0) then
                dynamic=.true.
            else
                if(known>=0.and.known/=expected) return
                known=expected
            end if
        end do
        expected=known
        if(dynamic) expected=-1
        ok=x%character_len==expected
        end associate
    end function
    logical function valid_constructor_do(prog,root) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root
        ok=.false.
        if(.not.allocated(prog%expressions)) return
        if(root<1.or.root>prog%ne.or.root>size(prog%expressions)) return
        if(prog%expressions(root)%kind/=ex_constructor_do) return
        ok=valid_constructor_tree(prog,root)
    end function
    logical function valid_constructor_tree(prog,root) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root
        integer::owners(max_constructor_do_depth),symbols(max_constructor_do_depth)
        integer::path(256)
        owners=0;symbols=0;path=0;ok=.false.
        if(.not.allocated(prog%expressions).or..not.allocated(prog%symbols)) return
        if(prog%ne<1.or.prog%ne>size(prog%expressions).or.prog%ns<0.or.prog%ns>size(prog%symbols)) return
        if(root<1.or.root>prog%ne) return
        if(prog%expressions(root)%kind/=ex_constructor_do.and.prog%expressions(root)%kind/=ex_constructor) return
        ok=walk(root,0,1,0,.false.)
    contains
        recursive logical function walk(e,level,depth,control_owner,metadata_only) result(valid)
            integer,intent(in)::e,level,depth,control_owner
            logical,intent(in)::metadata_only
            logical::child_metadata
            integer::s,j,a,lexical_depth,children(12)
            valid=.false.
            if(e<1.or.e>prog%ne.or.depth>size(path)) return
            if(any(path(:depth-1)==e)) return
            path(depth)=e
            associate(x=>prog%expressions(e))
            if(x%scope/=prog%expressions(root)%scope) return
            if(x%kind==ex_constructor_index) then
                if(.not.valid_constructor_index(prog,e)) return
                valid=any(owners(:level)==x%constructor_owner)
                if(metadata_only.and.any(path(:depth-1)==x%constructor_owner)) valid=.true.
                return
            end if
            if(x%constructor_owner/=0.or.x%kind==ex_output_do) return
            if(x%kind==ex_constructor_do) then
                if(level>=max_constructor_do_depth) return
                s=x%symbol
                if(s<1.or.s>prog%ns.or..not.allocated(x%args)) return
                if(any(symbols(:level)==s).or.size(x%args)<1.or.size(x%args)>64) return
                lexical_depth=1
                do j=1,depth-1
                    a=path(j)
                    if(prog%expressions(a)%kind/=ex_constructor_do) cycle
                    lexical_depth=lexical_depth+1
                    if(prog%expressions(a)%symbol==s) return
                end do
                if(lexical_depth>max_constructor_do_depth) return
                if(x%scope<0.or.x%scope>prog%np.or.x%rank/=1.or.x%extent/=-1.or.any(x%dims/=0).or. &
                   x%typ<ty_integer.or.x%typ>ty_character.or. &
                   x%length_expr/=0.or.x%constructor_kind_expr/=0.or.x%generic_id/=0.or. &
                   x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or.x%parenthesized.or. &
                   x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or.x%left3/=0.or.x%right3/=0.or. &
                   x%stride3/=0.or.x%third/=0.or.x%value%tag/=0.or.x%value%i/=0.or.x%value%r/=0.or.x%value%l.or. &
                   x%value%real_kind/=4.or.allocated(x%value%s).or. &
                   allocated(x%value%record).or.any(x%triplet.neqv.[.true.,.false.,.false.])) return
                if((x%typ==ty_integer.or.x%typ==ty_real).and.x%real_kind/=4.and.x%real_kind/=8) return
                if((x%typ==ty_logical.or.x%typ==ty_character).and.x%real_kind/=4) return
                if(x%typ/=ty_character.and.x%character_len/=-1) return
                if(x%typ==ty_character) then
                    if(.not.valid_constructor_character_metadata(prog,e)) return
                end if
                if(x%op/=''.and.x%op/='character') return
                if(x%op=='character'.and.(x%typ/=ty_character.or.x%character_len<0.or.x%character_len>65536)) return
                associate(v=>prog%symbols(s))
                if(v%typ/=ty_integer.or.v%rank/=0.or.(v%real_kind/=4.and.v%real_kind/=8).or. &
                   v%is_parameter.or.v%is_intrinsic) return
                end associate
                children(:3)=[x%left,x%right,x%stride]
                do j=1,3
                    a=children(j)
                    if(j==3.and.a==0) cycle
                    if(a<1.or.a>prog%ne) return
                    if(prog%expressions(a)%typ/=ty_integer.or.prog%expressions(a)%rank/=0.or. &
                       (prog%expressions(a)%real_kind/=4.and.prog%expressions(a)%real_kind/=8)) return
                    if(.not.walk(a,level,depth+1,e,metadata_only)) return
                end do
                owners(level+1)=e;symbols(level+1)=s
                do j=1,size(x%args)
                    a=x%args(j)
                    if(a<1.or.a>prog%ne) return
                    associate(y=>prog%expressions(a))
                    if(y%rank<0.or.y%rank>1.or.y%typ/=x%typ.or.y%real_kind/=x%real_kind) return
                    if(x%typ==ty_character.and.x%op/='character'.and.x%character_len>=0) then
                        if(y%character_len/=x%character_len) return
                    end if
                    end associate
                    if(.not.walk(a,level+1,depth+1,0,metadata_only)) return
                end do
            else
                if(x%kind==ex_constructor.and.x%typ==ty_character) then
                    if(.not.valid_constructor_character_metadata(prog,e)) return
                end if
                ! A reference to the inherited binding is not the statement entity.
                if(x%kind<ex_literal.or.x%kind>ex_gather_rows) return
                if((x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section).and. &
                   any(symbols(:level)==x%symbol)) return
                if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section) then
                    do j=1,depth-1
                        a=path(j)
                        if(prog%expressions(a)%kind==ex_constructor_do.and. &
                           x%symbol==prog%expressions(a)%symbol) return
                    end do
                end if
                child_metadata=metadata_only
                if(x%kind==ex_call.and.allocated(x%args)) then
                    if(size(x%args)==1) then
                        if(x%op=='bit_size'.or.x%op=='kind'.or.x%op=='digits'.or.x%op=='radix'.or.x%op=='huge') child_metadata=.true.
                        if(x%op=='len') then
                            a=x%args(1)
                            if(a>=1.and.a<=prog%ne) then
                                if(prog%expressions(a)%typ==ty_character.and.prog%expressions(a)%character_len>=0) &
                                    child_metadata=.true.
                            end if
                        end if
                    end if
                end if
                children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2, &
                          x%left3,x%right3,x%stride3,x%third,x%length_expr,x%constructor_kind_expr]
                do j=1,size(children)
                    a=children(j);if(a==0) cycle
                    if(.not.walk(a,level,depth+1,control_owner,child_metadata)) return
                end do
                if(allocated(x%args)) then
                    do j=1,size(x%args)
                        if(x%args(j)==0.and.x%kind==ex_user_call) cycle
                        if(.not.walk(x%args(j),level,depth+1,control_owner,child_metadata)) return
                    end do
                end if
            end if
            end associate
            valid=.true.
        end function
    end function
    logical function valid_output_do(prog,root) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root
        integer::counters(max_output_do_depth)
        counters=0
        ok=.false.
        if(.not.allocated(prog%expressions).or..not.allocated(prog%symbols)) return
        if(prog%ne<0.or.prog%ne>size(prog%expressions).or.prog%ns<0.or.prog%ns>size(prog%symbols)) return
        ok=walk(root,1)
    contains
        recursive logical function walk(e,depth) result(valid)
            integer,intent(in)::e,depth
            integer::s,j,a,controls(3)
            valid=.false.
            if(e<1.or.e>prog%ne.or.depth>max_output_do_depth) return
            associate(x=>prog%expressions(e))
            if(x%kind/=ex_output_do.or.x%scope<0.or.x%scope>prog%np.or.x%typ/=ty_integer.or. &
               x%real_kind/=4.or.x%rank/=0.or.x%extent/=0.or.any(x%dims/=0).or. &
               x%character_len/=-1.or.x%length_expr/=0.or.x%constructor_kind_expr/=0.or.x%constructor_owner/=0.or. &
               x%generic_id/=0.or.x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or. &
               x%parenthesized.or.len_trim(x%op)/=0.or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or. &
               x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or.x%third/=0.or. &
               any(x%triplet.neqv.[.true.,.false.,.false.]).or.x%value%tag/=0.or. &
               allocated(x%value%s).or.allocated(x%value%record)) return
            s=x%symbol
            if(s<1.or.s>prog%ns.or..not.allocated(x%args)) return
            if(size(x%args)<1.or.size(x%args)>64) return
            if(any(counters(:depth-1)==s)) return
            counters(depth)=s
            associate(v=>prog%symbols(s))
            if(v%typ/=ty_integer.or.v%rank/=0.or.(v%real_kind/=4.and.v%real_kind/=8).or. &
               v%scope/=x%scope.or.v%is_dummy.or.v%is_optional.or.v%is_parameter.or.v%is_pointer.or. &
               v%is_allocatable.or.v%is_intrinsic.or.v%is_class) return
            if(x%scope>0.and.v%is_saved) return
            end associate
            controls=[x%left,x%right,x%stride]
            do j=1,3
                a=controls(j)
                if(j==3.and.a==0) cycle
                if(a<1.or.a>prog%ne) return
                if(prog%expressions(a)%kind==ex_output_do.or.prog%expressions(a)%typ/=ty_integer.or. &
                   prog%expressions(a)%rank/=0.or.prog%expressions(a)%scope/=x%scope.or. &
                   (prog%expressions(a)%real_kind/=4.and.prog%expressions(a)%real_kind/=8)) return
            end do
            do j=1,size(x%args)
                a=x%args(j)
                if(a<1.or.a>prog%ne) return
                if(prog%expressions(a)%scope/=x%scope) return
                if(prog%expressions(a)%kind==ex_output_do) then
                    if(.not.walk(a,depth+1)) return
                else if(prog%expressions(a)%typ<ty_integer.or.prog%expressions(a)%typ>ty_character) then
                    return
                end if
            end do
            end associate
            valid=.true.
        end function
    end function
    ! D selects GETCWD (1) or GET_COMMAND_ARGUMENT (2). ITEMS retain formal
    ! slots, including zero for absent optional outputs. No input file or unit.
    logical function valid_timing_query(prog,ins) result(ok)
        type(program_t),intent(in)::prog
        type(instruction_t),intent(in)::ins
        integer::j,k,e,s,t,n,integer_kind
        ok=.false.;integer_kind=0
        if(.not.allocated(prog%expressions).or..not.allocated(prog%symbols))return
        if(prog%ne<0.or.prog%ne>size(prog%expressions).or.prog%ne>max_expressions.or. &
           prog%ns<0.or.prog%ns>size(prog%symbols).or.prog%ns>max_symbols)return
        if(ins%op/=op_timing_query.or.ins%scope<0.or.ins%scope>prog%np.or.(ins%d/=1.and.ins%d/=2))return
        if(ins%symbol/=0.or.ins%a/=0.or.ins%b/=0.or.ins%c/=0.or.ins%third/=0.or.ins%target/=0.or. &
           ins%component/=0.or.ins%generic_id/=0.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
           len_trim(ins%construct_name)/=0.or.allocated(ins%format).or.ins%format_expr/=0.or.ins%advance_mode/=0)return
        if(.not.allocated(ins%items))return
        n=3;if(ins%d==2)n=1
        if(size(ins%items)/=n)return
        do j=1,n
            e=ins%items(j)
            if(e==0.and.ins%d==1)cycle
            if(e<1.or.e>prog%ne)return
            associate(x=>prog%expressions(e))
            s=x%symbol
            if(s<1.or.s>prog%ns)return
            if(x%kind/=ex_variable.or.x%scope/=ins%scope.or.x%parenthesized.or.x%rank/=0.or. &
               x%extent/=0.or.any(x%dims/=0).or.x%character_len/=-1.or. &
               x%left/=0.or.x%right/=0.or.x%stride/=0.or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or. &
               x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or.x%third/=0.or.allocated(x%args).or. &
               x%length_expr/=0.or.x%constructor_kind_expr/=0.or.x%constructor_owner/=0.or.x%generic_id/=0.or. &
               x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or.len_trim(x%op)/=0.or. &
               any(x%triplet.neqv.[.true.,.false.,.false.]).or.x%value%tag/=0.or.x%value%i/=0.or. &
               x%value%r/=0.or.x%value%l.or.x%value%real_kind/=4.or.allocated(x%value%s).or. &
               allocated(x%value%record))return
            associate(v=>prog%symbols(s))
            if(v%rank/=0.or.v%is_allocatable.or.v%is_pointer.or.v%is_parameter.or.v%dummy_intent==1.or. &
               v%is_class.or.v%is_intrinsic.or.v%deferred_character.or.v%character_len/=-1.or. &
               x%typ/=v%typ.or.x%real_kind/=v%real_kind.or.(v%real_kind/=4.and.v%real_kind/=8))return
            if(v%scope< -prog%nm.or.v%scope>prog%np.or.v%assumed_shape.or.v%is_automatic.or. &
               v%lower_expr/=0.or.v%upper_expr/=0.or.v%lower_expr2/=0.or.v%upper_expr2/=0.or. &
               v%lower_expr3/=0.or.v%upper_expr3/=0.or.v%length_expr/=0.or. &
               v%dummy_intent<0.or.v%dummy_intent>3)return
            if(v%is_dummy)then
                if(v%scope<=0.or.v%is_saved)return
            else
                if(v%is_optional.or.v%dummy_intent/=0)return
            end if
            if(ins%d==2)then
                if(v%typ/=ty_real)return
            else if(j/=2)then
                if(v%typ/=ty_integer)return
            else
                if(v%typ/=ty_integer.and.v%typ/=ty_real)return
            end if
            if(v%typ==ty_integer)then
                ! F2023 requires all supplied INTEGER arguments to agree.
                if(integer_kind/=0.and.integer_kind/=v%real_kind)return
                integer_kind=v%real_kind
            end if
            end associate
            end associate
            do k=1,j-1
                if(ins%items(k)==0)cycle
                t=prog%expressions(ins%items(k))%symbol
                if(s==t)return
            end do
        end do
        ok=.true.
    end function
    logical function valid_move_alloc(prog,ins) result(ok)
        type(program_t),intent(in)::prog
        type(instruction_t),intent(in)::ins
        integer::j,e,s,from,to
        ok=.false.
        if(.not.allocated(prog%expressions).or..not.allocated(prog%symbols)) return
        if(prog%ne<0.or.prog%ne>size(prog%expressions).or.prog%ne>max_expressions.or.prog%ns<0.or.prog%ns>size(prog%symbols).or.prog%ns>max_symbols) return
        if(ins%op/=op_move_alloc.or.ins%scope<0.or.ins%scope>prog%np) return
        if(ins%symbol/=0.or.ins%a/=0.or.ins%b/=0.or.ins%c/=0.or.ins%d/=0.or.ins%third/=0.or.ins%target/=0.or. &
           ins%component/=0.or.ins%generic_id/=0.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
           len_trim(ins%construct_name)/=0.or.allocated(ins%format).or.ins%format_expr/=0.or.ins%advance_mode/=0) return
        if(.not.allocated(ins%items)) return
        if(size(ins%items)/=2) return
        do j=1,2
            e=ins%items(j)
            if(e<1.or.e>prog%ne) return
            associate(x=>prog%expressions(e))
            s=x%symbol
            if(s<1.or.s>prog%ns) return
            if(x%kind/=ex_variable.or.x%scope/=ins%scope.or.x%parenthesized.or. &
               x%left/=0.or.x%right/=0.or.x%stride/=0.or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or. &
               x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or.x%third/=0.or.allocated(x%args).or. &
               x%length_expr/=0.or.x%constructor_kind_expr/=0.or.x%constructor_owner/=0.or.x%generic_id/=0.or. &
               x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or.len_trim(x%op)/=0.or. &
               any(x%triplet.neqv.[.true.,.false.,.false.]).or.x%value%tag/=0.or.x%value%i/=0.or. &
               x%value%r/=0.or.x%value%l.or.x%value%real_kind/=4.or.allocated(x%value%s).or. &
               allocated(x%value%record)) return
            associate(v=>prog%symbols(s))
            if(.not.v%is_allocatable.or.v%is_pointer.or.v%is_parameter.or.v%dummy_intent==1.or. &
               v%is_class.or.v%is_intrinsic.or.v%rank<0.or.v%rank>3.or. &
               x%typ/=v%typ.or.x%real_kind/=v%real_kind.or.x%rank/=v%rank.or. &
               x%character_len/=v%character_len) return
            if(v%typ/=ty_integer.and.v%typ/=ty_real.and.v%typ/=ty_logical.and.v%typ/=ty_character) return
            if(v%typ==ty_integer.or.v%typ==ty_real) then
                if(v%real_kind/=4.and.v%real_kind/=8) return
            else
                if(v%real_kind/=4) return
            end if
            if(v%rank==0) then
                if(v%typ/=ty_character.or.x%extent/=0.or.any(x%dims/=0)) return
            else
                if(x%extent/=-1_int64) return
                if(v%rank==1) then
                    if(any(x%dims/=0)) return
                else
                    if(any(x%dims/=-1_int64)) return
                end if
            end if
            if(v%typ/=ty_character.and.v%character_len/=-1) return
            if(v%typ==ty_character) then
                if(v%character_len < -1.or.v%character_len>65536) return
                if(v%deferred_character.and.v%character_len/=-1) return
            end if
            end associate
            end associate
        end do
        from=prog%expressions(ins%items(1))%symbol;to=prog%expressions(ins%items(2))%symbol
        if(from==to) return
        associate(f=>prog%symbols(from),t=>prog%symbols(to))
        if(f%typ/=t%typ.or.f%real_kind/=t%real_kind.or.f%rank/=t%rank) return
        if(f%typ==ty_character.and..not.t%deferred_character.and..not.f%deferred_character) then
            if(f%character_len>=0.and.t%character_len>=0.and.f%character_len/=t%character_len) return
        end if
        end associate
        ok=.true.
    end function
    logical function valid_process_query(prog,ins) result(ok)
        type(program_t),intent(in)::prog
        type(instruction_t),intent(in)::ins
        integer::j,k,e,s,t,first,n,typ
        ok=.false.
        if(.not.allocated(prog%expressions).or..not.allocated(prog%symbols)) return
        if(prog%ne<0.or.prog%ne>size(prog%expressions).or.prog%ns<0.or.prog%ns>size(prog%symbols)) return
        if(ins%op/=op_process_query.or.ins%scope<0.or.ins%scope>prog%np.or.(ins%d/=1.and.ins%d/=2)) return
        if(ins%symbol/=0.or.ins%a/=0.or.ins%b/=0.or.ins%c/=0.or.ins%third/=0.or.ins%target/=0.or. &
           ins%component/=0.or.ins%generic_id/=0.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
           len_trim(ins%construct_name)/=0.or.allocated(ins%format).or.ins%format_expr/=0.or.ins%advance_mode/=0) return
        if(.not.allocated(ins%items)) return
        n=2;first=1
        if(ins%d==2) then
            n=4;first=2
        end if
        if(size(ins%items)/=n) return
        e=ins%items(1)
        if(e<1.or.e>prog%ne) return
        if(ins%d==2) then
            associate(x=>prog%expressions(e))
            if(x%typ/=ty_integer.or.x%real_kind/=4.or.x%rank/=0.or.x%extent/=0.or. &
               any(x%dims/=0).or.x%scope/=ins%scope.or.x%kind==ex_output_do) return
            end associate
        end if
        do j=first,n
            e=ins%items(j)
            if(e==0.and.(ins%d==2.or.j==2)) cycle
            typ=ty_integer
            if(j==first) typ=ty_character
            if(.not.output_variable(e,typ)) return
            s=prog%expressions(e)%symbol
            do k=first,j-1
                if(ins%items(k)==0) cycle
                t=prog%expressions(ins%items(k))%symbol
                if(s==t) return
            end do
            if(ins%d==2) then
                associate(number=>prog%expressions(ins%items(1)))
                if(number%kind==ex_variable.and..not.number%parenthesized.and.number%symbol==s) return
                end associate
            end if
        end do
        ok=.true.
    contains
        logical function output_variable(e,typ) result(valid)
            integer,intent(in)::e,typ
            integer::s
            valid=.false.
            if(e<1.or.e>prog%ne) return
            associate(x=>prog%expressions(e))
            s=x%symbol
            if(s<1.or.s>prog%ns) return
            if(x%kind/=ex_variable.or.x%scope/=ins%scope.or.x%parenthesized.or.x%typ/=typ.or. &
               x%real_kind/=4.or.x%rank/=0.or.x%extent/=0.or.any(x%dims/=0).or. &
               x%left/=0.or.x%right/=0.or.x%stride/=0.or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or. &
               x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or.x%third/=0.or.allocated(x%args).or. &
               x%length_expr/=0.or.x%constructor_kind_expr/=0.or.x%constructor_owner/=0.or.x%generic_id/=0.or. &
               x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or.len_trim(x%op)/=0.or. &
               any(x%triplet.neqv.[.true.,.false.,.false.])) return
            associate(v=>prog%symbols(s))
            if(v%typ/=typ.or.v%real_kind/=4.or.v%rank/=0.or.v%scope/=ins%scope.or. &
               x%character_len/=v%character_len.or.v%is_parameter.or.v%is_dummy.or.v%is_optional.or. &
               v%dummy_intent/=0.or.v%is_pointer.or.v%is_class.or.v%is_intrinsic) return
            if(ins%scope>0.and.v%is_saved) return
            if(typ==ty_integer.and.v%is_allocatable) return
            end associate
            end associate
            valid=.true.
        end function
    end function
    logical function valid_internal_read_section(prog,root,scope,stat_symbol,items) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root,scope,stat_symbol,items(:)
        integer::s,j,t,marks(max_expressions),children(3)
        ok=.false.
        if(root<1.or.root>prog%ne.or.size(items)>64)return
        do j=1,size(items)
            if(items(j)<1.or.items(j)>prog%ne)return
        end do
        associate(x=>prog%expressions(root))
        s=x%symbol
        if(s<1.or.s>prog%ns)return
        if(x%kind/=ex_section.or.x%scope/=scope.or.x%rank/=1.or.x%extent/=-1_int64.or. &
           any(x%dims/=0).or.x%parenthesized.or. &
           x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or.x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or. &
           x%third/=0.or.x%length_expr/=0.or.x%generic_id/=0.or.x%bound_type/=0.or.x%bound_binding/=0.or. &
           x%constructor_owner/=0.or.x%constructor_kind_expr/=0.or.x%intrinsic_mask/=0.or.allocated(x%args).or. &
           len_trim(x%op)/=0.or.any(x%triplet.neqv.[.true.,.false.,.false.]))return
        if(.not.empty_value(x%value))return
        associate(v=>prog%symbols(s))
        if(v%rank/=1.or.v%scope/=scope.or.v%is_parameter.or.v%is_pointer.or.v%is_class.or.v%is_intrinsic.or. &
           v%dummy_intent==1.or.v%is_optional)return
        if(scope>0.and.v%is_saved)return
        if(v%typ/=ty_integer.and.v%typ/=ty_real.and.v%typ/=ty_character)return
        if(v%real_kind/=4.and.v%real_kind/=8)return
        if(v%typ==ty_character.and.v%real_kind/=4)return
        if(x%typ/=v%typ.or.x%real_kind/=v%real_kind)return
        if(v%typ==ty_character)then
            if(x%character_len/=v%character_len.or.v%character_len< -1.or.v%character_len>65536)return
        else
            if(x%character_len/=-1)return
        end if
        end associate
        children=[x%left,x%right,x%stride]
        end associate
        marks=0
        do j=1,3
            if(children(j)==0)cycle
            if(.not.index_tree(children(j),0))return
        end do
        ok=.true.
    contains
        logical function empty_value(v) result(empty)
            type(value_t),intent(in)::v
            empty=v%tag==0.and.v%real_kind==4.and.v%i==0_int64.and.v%r==0.0_real64.and. &
                .not.v%l.and..not.allocated(v%s).and..not.allocated(v%record)
        end function
        recursive logical function index_tree(e,depth) result(valid)
            integer,intent(in)::e,depth
            integer::v,k
            valid=.false.
            if(e<1.or.e>prog%ne.or.depth>512)return
            if(marks(e)==1)return
            if(marks(e)==2)then
                valid=.true.;return
            end if
            marks(e)=1
            associate(x=>prog%expressions(e))
            if(x%typ/=ty_integer.or.(x%real_kind/=4.and.x%real_kind/=8).or.x%rank/=0.or.x%extent/=0.or. &
               any(x%dims/=0).or.x%character_len/=-1.or.x%scope/=scope.or.x%generic_id/=0.or.x%bound_type/=0.or. &
               x%bound_binding/=0.or.x%intrinsic_mask/=0.or.x%constructor_owner/=0.or.x%constructor_kind_expr/=0.or. &
               x%length_expr/=0.or.allocated(x%args).or.x%stride/=0.or.x%third/=0.or.x%left2/=0.or.x%right2/=0.or. &
               x%stride2/=0.or.x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or. &
               any(x%triplet.neqv.[.true.,.false.,.false.]))return
            if(x%kind==ex_literal)then
                if(x%value%tag/=ty_integer.or.x%value%real_kind/=x%real_kind.or.x%value%r/=0.0_real64.or. &
                   x%value%l.or.allocated(x%value%s).or.allocated(x%value%record))return
                if(x%real_kind==4.and.(x%value%i< -2147483648_int64.or.x%value%i>2147483647_int64))return
            else
                if(.not.empty_value(x%value))return
            end if
            select case(x%kind)
            case(ex_literal)
                if(x%symbol/=0.or.x%left/=0.or.x%right/=0.or.len_trim(x%op)/=0)return
            case(ex_variable)
                v=x%symbol
                if(v<1.or.v>prog%ns.or.x%left/=0.or.x%right/=0.or.len_trim(x%op)/=0)return
                if(v==stat_symbol)return
                do k=1,size(items)
                    if(v==prog%expressions(items(k))%symbol)return
                end do
                associate(d=>prog%symbols(v))
                if(d%scope/=scope.or.d%rank/=0.or.d%typ/=ty_integer.or.d%real_kind/=x%real_kind.or. &
                   d%is_pointer.or.d%is_allocatable.or.d%is_optional.or.d%is_class.or.d%is_automatic.or. &
                   d%assumed_shape.or.d%character_len/=-1.or.d%length_expr/=0.or.d%deferred_character.or. &
                   d%lower_expr/=0.or.d%upper_expr/=0.or.d%lower_expr2/=0.or.d%upper_expr2/=0.or. &
                   d%lower_expr3/=0.or.d%upper_expr3/=0)return
                end associate
            case(ex_unary)
                if(x%symbol/=0.or.x%right/=0.or.(x%op/='+'.and.x%op/='-'))return
                if(.not.index_tree(x%left,depth+1))return
                if(x%real_kind/=prog%expressions(x%left)%real_kind)return
            case(ex_binary)
                if(x%symbol/=0)return
                select case(trim(x%op))
                case('+','-','*','/','**')
                case default;return
                end select
                if(.not.index_tree(x%left,depth+1))return
                if(.not.index_tree(x%right,depth+1))return
                if(x%real_kind/=max(prog%expressions(x%left)%real_kind,prog%expressions(x%right)%real_kind))return
            case default
                return
            end select
            end associate
            marks(e)=2;valid=.true.
        end function
    end function
    logical function valid_internal_read(prog,ins) result(ok)
        type(program_t),intent(in)::prog
        type(instruction_t),intent(in)::ins
        ok=valid_read(prog,ins,.false.)
    end function
    logical function valid_external_read(prog,ins) result(ok)
        type(program_t),intent(in)::prog
        type(instruction_t),intent(in)::ins
        ok=valid_read(prog,ins,.true.)
    end function
    ! Bounded INQUIRE is metadata-only over the caller's input allow-list.
    ! Reuse the exact external READ unit/target ownership and effect contract.
    ! A formatted external input item may be one complete local CHARACTER
    ! element. It is an address, not an initialized value to be evaluated.
    ! Restrict index expression effects before freezing the destination: no
    ! user calls (including PURE), derived components or implied-DO indices.
    logical function valid_external_read_element(prog,root,s,scope,stat_symbol) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root,s,scope,stat_symbol
        integer::marks(max_expressions),j,children(3)
        ok=.false.
        if(.not.valid_internal_write_element(prog,root,s,scope))return
        if(stat_symbol<0.or.stat_symbol>prog%ns)return
        if(prog%symbols(s)%scope/=scope)return
        if(scope>0.and.prog%symbols(s)%is_saved)return
        marks=0
        associate(e=>prog%expressions(root))
        children=[e%left,e%right,e%third]
        end associate
        do j=1,prog%symbols(s)%rank
            if(.not.index_tree(children(j),0))return
        end do
        ok=.true.
    contains
        recursive logical function index_tree(e,depth) result(valid)
            integer,intent(in)::e,depth
            integer::q,edges(12)
            valid=.false.
            if(e<1.or.e>prog%ne.or.depth>512)return
            if(marks(e)==1)return
            if(marks(e)==2)then
                valid=.true.;return
            end if
            marks(e)=1
            associate(x=>prog%expressions(e))
            if(x%scope/=scope.or.x%constructor_owner/=0)return
            if(.not.index_metadata(e))return
            ! IOSTAT may be defined before input-item address evaluation by a
            ! processor. Do not promise a snapshot for dependent indices.
            if(stat_symbol>0.and.x%symbol==stat_symbol)then
                if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section.or.x%kind==ex_gather_rows)return
            end if
            select case(x%kind)
            case(ex_literal,ex_variable,ex_unary,ex_binary,ex_call,ex_element,ex_section,ex_gather_rows,ex_constructor)
            case default
                return
            end select
            edges=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third, &
                   x%length_expr,x%constructor_kind_expr]
            do q=1,size(edges)
                if(edges(q)==0)cycle
                if(.not.index_tree(edges(q),depth+1))return
            end do
            if(allocated(x%args))then
                if(size(x%args)>max_expressions)return
                do q=1,size(x%args)
                    if(x%args(q)==0)cycle
                    if(.not.index_tree(x%args(q),depth+1))return
                end do
            end if
            end associate
            marks(e)=2;valid=.true.
        end function
        ! Metadata-only guard scoped to this new writable-element index tree.
        ! Ordinary evaluation is not a substitute: it can coerce a forged leaf
        ! kind or ignore scalar dimension caches before producing the root value.
        logical function index_metadata(e) result(valid)
            integer,intent(in)::e
            integer::v,r
            integer(int64)::lo(3),hi(3),dims(3),extent
            valid=.false.
            associate(x=>prog%expressions(e))
            r=x%rank
            if(r<0.or.r>3.or.x%extent< -1_int64.or.x%extent>max_array_elements.or. &
               any(x%dims< -1_int64).or.any(x%dims>2147483647_int64))return
            if(r<=1.and.any(x%dims/=0))return
            if(r==0.and.x%extent/=0)return
            if(r>=2.and.x%extent>=0)then
                if(any(x%dims<0))return
                if(shape_size(x%dims)/=x%extent)return
            end if
            select case(x%typ)
            case(ty_integer,ty_real)
                if(x%real_kind/=4.and.x%real_kind/=8)return
                if(x%character_len/=-1)return
            case(ty_logical)
                if(x%real_kind/=4.or.x%character_len/=-1)return
            case(ty_character)
                if(x%real_kind/=4.or.x%character_len< -1.or.x%character_len>65536)return
            case default
                return
            end select
            if(x%kind/=ex_constructor.and.(x%length_expr/=0.or.x%constructor_kind_expr/=0))return
            if(x%kind==ex_literal)then
                if(r/=0)return
                if(.not.index_scalar_value(x%value,x%typ,x%real_kind,x%character_len,.true.))return
            else
                if(x%value%tag/=0.or.x%value%i/=0_int64.or.x%value%r/=0.0_real64.or.x%value%l.or. &
                   x%value%real_kind/=4.or.allocated(x%value%s).or.allocated(x%value%record))return
            end if
            select case(x%kind)
            case(ex_variable,ex_element,ex_section,ex_gather_rows)
                v=x%symbol
                if(v<1.or.v>prog%ns)return
                associate(decl=>prog%symbols(v))
                if(x%typ/=decl%typ.or.x%real_kind/=decl%real_kind.or.x%character_len/=decl%character_len)return
                if(x%kind==ex_element)then
                    if(r/=0.or.decl%rank<1.or.decl%rank>3)return
                end if
                if(decl%is_parameter.and.decl%parameter_ready.and.decl%rank==0)then
                    if(allocated(decl%constant_values))return
                    if(.not.index_scalar_value(decl%constant_value,decl%typ,decl%real_kind,decl%character_len,.false.))return
                end if
                if(x%kind==ex_variable)then
                    if(r/=decl%rank)return
                    if(x%typ==ty_character)then
                        if(.not.valid_character_len_variable(prog,e))return
                    else
                        if(.not.valid_bit_variable(prog,e))return
                        extent=0_int64;dims=0_int64
                        if(r>0)then
                            if(decl%is_allocatable.or.decl%is_pointer.or.decl%assumed_shape.or.decl%is_automatic)then
                                extent=-1_int64
                                if(r>=2)dims=-1_int64
                            else
                                lo=[decl%lower_bound,decl%lower_bound2,decl%lower_bound3]
                                hi=[decl%upper_bound,decl%upper_bound2,decl%upper_bound3]
                                if(any(lo(:r)< -2147483648_int64).or.any(lo(:r)>2147483647_int64).or. &
                                   any(hi(:r)< -2147483648_int64).or.any(hi(:r)>2147483647_int64))return
                                dims=1_int64;dims(:r)=max(0_int64,hi(:r)-lo(:r)+1_int64)
                                if(any(dims>2147483647_int64))return
                                extent=shape_size(dims)
                                if(extent>max_array_elements)return
                                if(r==1)dims=0_int64
                            end if
                        end if
                        if(x%extent/=extent.or.any(x%dims/=dims))return
                    end if
                end if
                end associate
            end select
            valid=.true.
            end associate
        end function
        logical function index_scalar_value(value,typ,rkind,n,strict_literal) result(valid)
            use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
            type(value_t),intent(in)::value
            integer,intent(in)::typ,rkind,n
            logical,intent(in)::strict_literal
            valid=.false.
            if(value%tag/=typ.or.value%real_kind/=rkind.or.allocated(value%record))return
            if(typ/=ty_character.and.allocated(value%s))return
            select case(typ)
            case(ty_integer)
                ! convert retains inactive numeric scalar fields in parameter
                ! caches. Only literal caches promise those fields are zero.
                if(value%l)return
                if(strict_literal.and.value%r/=0.0_real64)return
                if(rkind==4)then
                    if(value%i< -2147483648_int64.or.value%i>2147483647_int64)return
                end if
            case(ty_real)
                if(value%l.or..not.ieee_is_finite(value%r))return
                if(strict_literal.and.value%i/=0_int64)return
                if(rkind==4)then
                    if(abs(value%r)>real(huge(0.0_real32),real64))return
                end if
            case(ty_logical)
                if(value%i/=0_int64.or.value%r/=0.0_real64)return
            case(ty_character)
                if(value%i/=0_int64.or.value%r/=0.0_real64.or.value%l)return
                if(.not.allocated(value%s))return
                if(len(value%s)/=n)return
            case default
                return
            end select
            valid=.true.
        end function
    end function
    ! New input-file subset only. Reuse the established element/cache guard,
    ! then impose local fixed-length storage and effect-free integer arithmetic.
    ! This does not relax any existing writable-element or scalar READ policy.
    logical function valid_internal_read_element(prog,root,s,scope,stat_symbol,items) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root,s,scope,stat_symbol,items(:)
        integer::j,t,marks(max_expressions),children(3),lower_nodes(3),upper_nodes(3)
        integer(int64)::lo(3),hi(3),dims(3),constant,decl_values(max_expressions)
        integer::decl_marks(max_expressions)
        ok=.false.
        if(.not.valid_external_read_element(prog,root,s,scope,stat_symbol))return
        if(size(items)>64)return
        do j=1,size(items)
            t=items(j)
            if(t<1.or.t>prog%ne)return
            if(prog%expressions(t)%symbol<1.or.prog%expressions(t)%symbol>prog%ns)return
        end do
        marks=0;decl_marks=0;decl_values=0_int64
        associate(v=>prog%symbols(s))
        if(v%is_dummy.or.v%is_optional.or.v%dummy_intent/=0.or.v%is_saved.or. &
           v%assumed_shape.or.v%is_automatic.or.v%deferred_character.or. &
           v%character_len<0.or.len_trim(v%intrinsic_import)/=0)return
        if(v%length_expr/=0)then
            if(.not.declaration_value(v%length_expr,0,constant))return
            if(constant/=v%character_len)return
        else if(v%character_len/=1)then
            return
        end if
        lower_nodes=[v%lower_expr,v%lower_expr2,v%lower_expr3]
        upper_nodes=[v%upper_expr,v%upper_expr2,v%upper_expr3]
        if(any(lower_nodes(v%rank+1:)/=0).or.any(upper_nodes(v%rank+1:)/=0))return
        if(v%is_allocatable)then
            if(any(lower_nodes/=0).or.any(upper_nodes/=0))return
        end if
        if(.not.v%is_allocatable)then
            lo=[v%lower_bound,v%lower_bound2,v%lower_bound3]
            hi=[v%upper_bound,v%upper_bound2,v%upper_bound3]
            if(any(lo(:v%rank)< -2147483648_int64).or.any(lo(:v%rank)>2147483647_int64).or. &
               any(hi(:v%rank)< -2147483648_int64).or.any(hi(:v%rank)>2147483647_int64))return
            do j=1,v%rank
                if(lower_nodes(j)/=0)then
                    if(.not.declaration_value(lower_nodes(j),0,constant))return
                    if(constant/=lo(j))return
                else if(lo(j)/=1_int64)then
                    return
                end if
                if(upper_nodes(j)==0)return
                if(upper_nodes(j)/=0)then
                    if(.not.declaration_value(upper_nodes(j),0,constant))return
                    if(constant/=hi(j))return
                end if
            end do
            dims=1_int64;dims(:v%rank)=max(0_int64,hi(:v%rank)-lo(:v%rank)+1_int64)
            if(any(dims>2147483647_int64))return
            if(shape_size(dims)>max_array_elements)return
        end if
        end associate
        marks=0
        children=[prog%expressions(root)%left,prog%expressions(root)%right,prog%expressions(root)%third]
        do j=1,prog%symbols(s)%rank
            if(.not.index_tree(children(j),0))return
        end do
        ok=.true.
    contains
        ! Declaration expressions survive parsing even for fixed storage.
        ! Recheck their bounded constant INTEGER value against the cached length
        ! or bound; never treat a nonzero retained expression as automatic storage.
        recursive logical function declaration_value(e,depth,value) result(valid)
            use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
            integer,intent(in)::e,depth
            integer(int64),intent(out)::value
            integer(int64)::left,right
            integer::v,k
            valid=.false.;value=0_int64
            if(e<1.or.e>prog%ne.or.depth>512)return
            if(decl_marks(e)==1)return
            if(decl_marks(e)==2)then
                value=decl_values(e);valid=.true.;return
            end if
            decl_marks(e)=1
            if(.not.index_tree(e,0))return
            associate(x=>prog%expressions(e))
            if(x%kind==ex_literal)then
                if(x%value%tag/=ty_integer.or.x%value%real_kind/=x%real_kind.or. &
                   x%value%r/=0.0_real64.or.x%value%l.or.allocated(x%value%s).or.allocated(x%value%record))return
                value=x%value%i
            else
                if(x%value%tag/=0.or.x%value%i/=0_int64.or.x%value%r/=0.0_real64.or.x%value%l.or. &
                   x%value%real_kind/=4.or.allocated(x%value%s).or.allocated(x%value%record))return
                select case(x%kind)
                case(ex_variable)
                    v=x%symbol
                    associate(d=>prog%symbols(v))
                    if(.not.d%is_parameter.or..not.d%parameter_ready.or.d%rank/=0.or.d%typ/=ty_integer.or. &
                       d%real_kind/=x%real_kind.or.allocated(d%constant_values))return
                    if(d%constant_value%tag/=ty_integer.or.d%constant_value%real_kind/=d%real_kind.or. &
                       d%constant_value%l.or..not.ieee_is_finite(d%constant_value%r).or. &
                       allocated(d%constant_value%s).or.allocated(d%constant_value%record))return
                    value=d%constant_value%i
                    end associate
                case(ex_unary)
                    if(.not.declaration_value(x%left,depth+1,left))return
                    value=left
                    if(x%op=='-')value=-left
                case(ex_binary)
                    if(.not.declaration_value(x%left,depth+1,left))return
                    if(.not.declaration_value(x%right,depth+1,right))return
                    ! Child values are bounded to signed32 below; these sums
                    ! and products cannot overflow signed64 before validation.
                    select case(trim(x%op))
                    case('+');value=left+right
                    case('-');value=left-right
                    case('*');value=left*right
                    case('/')
                        if(right==0_int64)return
                        value=left/right
                    case('**')
                        if(right==0_int64)then
                            value=1_int64
                        else if(left==1_int64)then
                            value=1_int64
                        else if(left==-1_int64)then
                            value=1_int64
                            if(modulo(right,2_int64)/=0_int64)value=-1_int64
                        else if(right<0_int64)then
                            if(left==0_int64)return
                            value=0_int64
                        else if(left==0_int64)then
                            value=0_int64
                        else
                            if(right>31_int64)return
                            value=1_int64
                            do k=1,int(right)
                                value=value*left
                                if(value< -2147483648_int64.or.value>2147483647_int64)return
                            end do
                        end if
                    case default;return
                    end select
                case default;return
                end select
            end if
            if(value< -2147483648_int64.or.value>2147483647_int64)return
            decl_values(e)=value;decl_marks(e)=2
            valid=.true.
            end associate
        end function
        recursive logical function index_tree(e,depth) result(valid)
            integer,intent(in)::e,depth
            integer::k,v
            valid=.false.
            if(e<1.or.e>prog%ne.or.depth>512)return
            if(marks(e)==1)return
            if(marks(e)==2)then
                valid=.true.;return
            end if
            marks(e)=1
            associate(x=>prog%expressions(e))
            if(x%typ/=ty_integer.or.(x%real_kind/=4.and.x%real_kind/=8).or. &
               x%rank/=0.or.x%extent/=0.or.any(x%dims/=0).or. &
               x%character_len/=-1.or.x%scope/=scope.or.x%generic_id/=0.or.x%bound_type/=0.or. &
               x%bound_binding/=0.or.x%intrinsic_mask/=0.or.x%constructor_owner/=0.or. &
               x%constructor_kind_expr/=0.or.x%length_expr/=0.or.allocated(x%args).or. &
               x%stride/=0.or.x%third/=0.or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or. &
               x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or. &
               any(x%triplet.neqv.[.true.,.false.,.false.]))return
            select case(x%kind)
            case(ex_literal)
                if(x%symbol/=0.or.x%left/=0.or.x%right/=0.or.len_trim(x%op)/=0)return
            case(ex_variable)
                v=x%symbol
                if(v<1.or.v>prog%ns.or.x%left/=0.or.x%right/=0.or.len_trim(x%op)/=0)return
                if(v==stat_symbol)return
                do k=1,size(items)
                    if(v==prog%expressions(items(k))%symbol)return
                end do
                associate(decl=>prog%symbols(v))
                if(decl%scope/=scope.or.decl%is_pointer.or.decl%is_dummy.or.decl%is_optional.or. &
                   decl%is_allocatable.or.decl%is_class.or.decl%is_automatic.or.decl%assumed_shape.or. &
                   decl%dummy_intent/=0.or.decl%length_expr/=0.or.decl%deferred_character.or. &
                   decl%lower_expr/=0.or.decl%upper_expr/=0.or.decl%lower_expr2/=0.or.decl%upper_expr2/=0.or. &
                   decl%lower_expr3/=0.or.decl%upper_expr3/=0)return
                end associate
            case(ex_unary)
                if(x%symbol/=0.or.x%right/=0.or.(x%op/='+'.and.x%op/='-'))return
                if(.not.index_tree(x%left,depth+1))return
                if(x%real_kind/=prog%expressions(x%left)%real_kind)return
            case(ex_binary)
                if(x%symbol/=0)return
                select case(trim(x%op))
                case('+','-','*','/','**')
                case default;return
                end select
                if(.not.index_tree(x%left,depth+1))return
                if(.not.index_tree(x%right,depth+1))return
                if(x%real_kind/=max(prog%expressions(x%left)%real_kind,prog%expressions(x%right)%real_kind))return
            case default
                return
            end select
            end associate
            marks(e)=2;valid=.true.
        end function
    end function
    logical function valid_inquire_name(prog,ins) result(ok)
        type(program_t),intent(in)::prog
        type(instruction_t),intent(in)::ins
        type(instruction_t)::read_form
        integer::ios
        ok=.false.
        if(ins%op/=op_inquire_name.or.ins%b==0.or.allocated(ins%items).or.allocated(ins%format))return
        ! NAME remains a whole scalar, independently of formatted READ targets.
        if(.not.allocated(prog%expressions))return
        if(prog%ne<0.or.prog%ne>size(prog%expressions))return
        if(ins%b<1.or.ins%b>prog%ne)return
        associate(name=>prog%expressions(ins%b))
        if(name%kind/=ex_variable.or.name%rank/=0.or.name%typ/=ty_character.or.name%real_kind/=4)return
        end associate
        read_form=ins;read_form%op=op_read_external;read_form%b=0
        allocate(read_form%items(1),stat=ios)
        if(ios/=0)return
        read_form%items(1)=ins%b;read_form%format='(a)'
        ok=valid_external_read(prog,read_form)
    end function
    logical function valid_backspace(prog,ins) result(ok)
        type(program_t),intent(in)::prog
        type(instruction_t),intent(in)::ins
        type(instruction_t)::read_form
        integer::ios
        ok=.false.
        if(ins%op/=op_backspace.or.allocated(ins%items).or.allocated(ins%format)) return
        ! The same whole INTEGER unit/status bindings and effect/neutral-field
        ! restrictions apply. No interpreted path or native unit is introduced.
        read_form=ins;read_form%op=op_read_external
        allocate(read_form%items(0),stat=ios)
        if(ios/=0) return
        ok=valid_read(prog,read_form,.true.)
    end function
    logical function valid_read(prog,ins,external) result(ok)
        type(program_t),intent(in)::prog
        type(instruction_t),intent(in)::ins
        logical,intent(in)::external
        integer::j,k,s,t,file_symbol,n,stat_symbol
        character(3)::fmt
        logical::element_file
        ok=.false.;element_file=.false.
        if(.not.allocated(prog%expressions).or..not.allocated(prog%symbols)) return
        if(prog%ne<0.or.prog%ne>size(prog%expressions).or.prog%ns<0.or.prog%ns>size(prog%symbols)) return
        if(ins%scope<0.or.ins%scope>prog%np) return
        if(ins%scope>0) then
            if(.not.allocated(prog%procedures)) return
            if(ins%scope>size(prog%procedures)) return
        end if
        if(ins%symbol/=0.or.ins%c/=0.or.ins%d/=0.or.ins%third/=0.or.ins%target/=0.or. &
           ins%component/=0.or.ins%generic_id/=0.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
           len_trim(ins%construct_name)/=0.or.ins%format_expr/=0.or.ins%advance_mode/=0) return
        if(external) then
            if(ins%op/=op_read_external) return
            if(allocated(ins%format)) then
            ! No widths, repeated descriptors, slash editing or runtime formats.
            fmt='';n=0
            do j=1,len(ins%format)
                if(ins%format(j:j)==' '.or.ins%format(j:j)==achar(9)) cycle
                n=n+1
                if(n>3) return
                fmt(n:n)=lower(ins%format(j:j))
            end do
            if(n/=3.or.fmt/='(a)') return
            end if
            if(ins%scope>0) then
                associate(proc=>prog%procedures(ins%scope))
                if(proc%is_pure.or.proc%is_simple.or. &
                   (.not.proc%is_subroutine.and..not.proc%has_impure_prefix)) return
                end associate
            end if
        else
            if(ins%op/=op_read_internal.or.allocated(ins%format)) return
        end if
        if(.not.allocated(ins%items)) return
        if(size(ins%items)>64) return
        if(external.and.allocated(ins%format)) then
            if(size(ins%items)/=1) return
        end if
        if(ins%a<1.or.ins%a>prog%ne)return
        element_file=.not.external.and.prog%expressions(ins%a)%kind==ex_element
        if(element_file)then
            file_symbol=prog%expressions(ins%a)%symbol
            if(file_symbol<1.or.file_symbol>prog%ns)return
        else
            if(.not.variable(ins%a,.false.)) return
            file_symbol=prog%expressions(ins%a)%symbol
            associate(v=>prog%symbols(file_symbol))
            if(v%rank/=0) return
            if(external) then
                if(v%typ/=ty_integer) return
            else
                if(v%typ/=ty_character.or.v%real_kind/=4) return
            end if
            end associate
        end if
        stat_symbol=0
        if(ins%b/=0) then
            if(.not.variable(ins%b,.true.)) return
            s=prog%expressions(ins%b)%symbol
            if(prog%symbols(s)%typ/=ty_integer.or.prog%symbols(s)%rank/=0.or.s==file_symbol) return
            stat_symbol=s
        end if
        do j=1,size(ins%items)
            if(ins%items(j)<1.or.ins%items(j)>prog%ne)return
            s=prog%expressions(ins%items(j))%symbol
            if(external.and.allocated(ins%format).and.prog%expressions(ins%items(j))%kind==ex_element)then
                if(.not.valid_external_read_element(prog,ins%items(j),s,ins%scope,stat_symbol))return
            else if(.not.external.and.prog%expressions(ins%items(j))%kind==ex_section)then
                if(.not.valid_internal_read_section(prog,ins%items(j),ins%scope,stat_symbol,ins%items))return
            else
                if(.not.variable(ins%items(j),.true.)) return
            end if
            if(s==file_symbol) return
            if(external.and.allocated(ins%format)) then
                if(prog%symbols(s)%typ/=ty_character.or.prog%expressions(ins%items(j))%rank/=0) return
            else
                if(prog%symbols(s)%typ/=ty_integer.and.prog%symbols(s)%typ/=ty_real.and. &
                   prog%symbols(s)%typ/=ty_character) return
            end if
            if(prog%symbols(s)%typ==ty_character.and.prog%symbols(s)%real_kind/=4) return
            if(ins%b/=0) then
                if(s==prog%expressions(ins%b)%symbol) return
            end if
            do k=1,j-1
                t=prog%expressions(ins%items(k))%symbol
                if(s==t) return
            end do
        end do
        if(element_file)then
            if(.not.valid_internal_read_element(prog,ins%a,file_symbol,ins%scope,stat_symbol,ins%items))return
        end if
        ok=.true.
    contains
        logical function variable(e,writable) result(valid)
            integer,intent(in)::e
            logical,intent(in)::writable
            integer::s,r
            integer(int64)::lo(3),hi(3),dims(3),extent
            valid=.false.
            if(e<1.or.e>prog%ne) return
            associate(x=>prog%expressions(e))
            s=x%symbol
            if(s<1.or.s>prog%ns) return
            if(x%kind/=ex_variable.or.x%scope/=ins%scope.or.x%parenthesized.or. &
               x%left/=0.or.x%right/=0.or.x%stride/=0.or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or. &
               x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or.x%third/=0.or.allocated(x%args).or. &
               x%generic_id/=0.or.x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or. &
               x%constructor_kind_expr/=0.or.x%constructor_owner/=0.or.x%length_expr/=0.or.len_trim(x%op)/=0.or. &
               any(x%triplet.neqv.[.true.,.false.,.false.])) return
            if(x%value%tag/=0.or.x%value%real_kind/=4.or.x%value%i/=0_int64.or.x%value%r/=0.0_real64.or. &
               x%value%l.or.allocated(x%value%s).or.allocated(x%value%record)) return
            associate(v=>prog%symbols(s))
            r=v%rank
            if(x%typ/=v%typ.or.x%real_kind/=v%real_kind.or.x%rank/=r.or.r<0.or.r>3) return
            if(v%is_parameter.or.v%is_pointer.or.v%is_class.or.v%is_intrinsic) return
            if(v%real_kind/=4.and.v%real_kind/=8) return
            if(v%typ==ty_character) then
                if(.not.valid_character_len_variable(prog,e)) return
            else
                if(x%character_len/=-1) return
                extent=0_int64;dims=0_int64
                if(r>0) then
                    if(v%is_allocatable.or.v%assumed_shape.or.v%is_automatic) then
                        extent=-1_int64
                        if(r>=2) dims=-1_int64
                    else
                        lo=[v%lower_bound,v%lower_bound2,v%lower_bound3]
                        hi=[v%upper_bound,v%upper_bound2,v%upper_bound3]
                        if(any(lo(:r)< -2147483648_int64).or.any(lo(:r)>2147483647_int64).or. &
                           any(hi(:r)< -2147483648_int64).or.any(hi(:r)>2147483647_int64)) return
                        dims=1_int64;dims(:r)=max(0_int64,hi(:r)-lo(:r)+1_int64)
                        if(any(dims>2147483647_int64)) return
                        extent=shape_size(dims)
                        if(extent>max_array_elements) return
                        if(r==1) dims=0_int64
                    end if
                end if
                if(x%extent/=extent.or.any(x%dims/=dims)) return
            end if
            if(writable) then
                if(v%scope/=ins%scope.or.v%dummy_intent==1) return
                if(ins%scope>0.and.v%is_saved) return
            end if
            end associate
            end associate
            valid=.true.
        end function
    end function
    logical function valid_component_defaults(prog,t) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::t
        integer::j,root,n,typ,rkind
        ok=.false.
        if(t<1.or.t>prog%nt.or.t>max_types) return
        associate(d=>prog%derived_types(t))
        n=d%ncomponents
        if(n<1.or.n>16.or.d%module_id<1.or.d%module_id>prog%nm) return
        if(any(d%component_initializers(n+1:)/=0).or.any(d%component_lengths(n+1:)/=-1).or. &
           any(d%component_length_exprs(n+1:)/=0)) return
        do j=1,n
            typ=d%component_types(j);rkind=d%component_kinds(j)
            if(typ/=ty_integer.and.typ/=ty_real.and.typ/=ty_logical.and.typ/=ty_character) return
            if(typ==ty_character) then
                if(rkind/=4.or.d%component_lengths(j)<0.or.d%component_lengths(j)>65536) return
                root=d%component_length_exprs(j)
                if(root/=0) then
                    if(.not.valid_component_initializer(prog,root,-d%module_id,0)) return
                    if(prog%expressions(root)%typ/=ty_integer) return
                else if(d%component_lengths(j)/=1) then
                    return
                end if
            else
                if(d%component_lengths(j)/=-1.or.d%component_length_exprs(j)/=0) return
            end if
            root=d%component_initializers(j)
            if(root==0) cycle
            if(rkind/=4.and.rkind/=8) return
            if(typ==ty_logical.and.rkind/=4) return
            if(.not.valid_component_initializer(prog,root,-d%module_id,0)) return
            if(typ==ty_logical.or.typ==ty_character) then
                if(prog%expressions(root)%typ/=typ) return
            else
                if(prog%expressions(root)%typ/=ty_integer.and.prog%expressions(root)%typ/=ty_real) return
            end if
        end do
        end associate
        ok=.true.
    end function
    recursive logical function valid_component_initializer(prog,root,scope,depth) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root,scope,depth
        integer::s,j
        ok=.false.
        if(root<1.or.root>prog%ne.or.depth>64) return
        associate(e=>prog%expressions(root))
        if(e%scope/=scope.or.e%rank/=0.or.e%extent/=0.or.any(e%dims/=0)) return
        if(e%typ<ty_integer.or.e%typ>ty_character) return
        if(e%constructor_owner/=0.or.e%constructor_kind_expr/=0) return
        select case(e%kind)
        case(ex_literal)
            ok=.true.
        case(ex_variable)
            s=e%symbol
            if(s<1.or.s>prog%ns) return
            if(.not.prog%symbols(s)%is_parameter.or..not.prog%symbols(s)%parameter_ready) return
            if(prog%symbols(s)%rank/=0.or.prog%symbols(s)%typ/=e%typ.or. &
               prog%symbols(s)%real_kind/=e%real_kind) return
            if(prog%symbols(s)%scope/=scope) then
                if(.not.module_symbol_visible(prog,s,scope)) return
            end if
            ok=.true.
        case(ex_unary,ex_binary)
            if(.not.valid_component_initializer(prog,e%left,scope,depth+1)) return
            if(e%kind==ex_binary) then
                if(.not.valid_component_initializer(prog,e%right,scope,depth+1)) return
            end if
            ok=.true.
        case(ex_call)
            ! A bounded scalar initialization-expression whitelist. Runtime or
            ! user procedure inquiries cannot acquire initialization semantics.
            select case(trim(e%op))
            case('abs','int','real','kind','min','max','mod','modulo','sign', &
                 'sqrt','exp','log','log10','sin','cos','tan','nint','floor','ceiling', &
                 'len','iachar','ichar','selected_int_kind','selected_real_kind', &
                 'digits','radix','precision','range','huge','tiny','epsilon')
            case default
                return
            end select
            if(.not.allocated(e%args)) return
            if(size(e%args)<1.or.size(e%args)>16) return
            do j=1,size(e%args)
                if(.not.valid_component_initializer(prog,e%args(j),scope,depth+1)) return
            end do
            ok=.true.
        end select
        end associate
    end function
    ! OP_PRINT A>0 names a runtime unit expression; SYMBOL is its exact base.
    ! Only a clean whole scalar INTEGER name is allowed. The runtime separately
    ! reads it once and requires PROCESSOR_OUTPUT_UNIT before any data transfer.
    logical function valid_runtime_output_unit(prog,root,s,scope) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root,s,scope
        ok=.false.
        if(.not.allocated(prog%expressions).or..not.allocated(prog%symbols))return
        if(prog%ne<0.or.prog%ne>size(prog%expressions).or.prog%ne>max_expressions.or. &
           prog%ns<0.or.prog%ns>size(prog%symbols).or.prog%ns>max_symbols)return
        if(root<1.or.root>prog%ne.or.s<1.or.s>prog%ns.or.scope<0.or.scope>prog%np)return
        associate(e=>prog%expressions(root),v=>prog%symbols(s))
        if(e%kind/=ex_variable.or.e%symbol/=s.or.e%scope/=scope.or.e%typ/=ty_integer.or. &
           (e%real_kind/=4.and.e%real_kind/=8).or.e%rank/=0.or.e%extent/=0.or.any(e%dims/=0).or. &
           e%parenthesized.or.e%character_len/=-1.or.e%length_expr/=0.or.e%constructor_owner/=0.or. &
           e%constructor_kind_expr/=0.or.e%generic_id/=0.or.e%bound_type/=0.or.e%bound_binding/=0.or. &
           e%intrinsic_mask/=0.or.e%left/=0.or.e%right/=0.or.e%stride/=0.or.e%third/=0.or. &
           e%left2/=0.or.e%right2/=0.or.e%stride2/=0.or.e%left3/=0.or.e%right3/=0.or.e%stride3/=0.or. &
           len_trim(e%op)/=0.or.allocated(e%args).or.any(e%triplet.neqv.[.true.,.false.,.false.]))return
        if(e%value%tag/=0.or.e%value%i/=0.or.e%value%r/=0.or.e%value%l.or.e%value%real_kind/=4.or. &
           allocated(e%value%s).or.allocated(e%value%record))return
        if(v%typ/=ty_integer.or.v%real_kind/=e%real_kind.or.v%rank/=0.or. &
           v%is_allocatable.or.v%is_pointer.or.v%is_class.or.v%is_intrinsic.or. &
           len_trim(v%intrinsic_import)/=0.or.v%deferred_character.or.v%character_len/=-1.or. &
           v%length_expr/=0.or.v%assumed_shape.or.v%is_automatic.or.v%scope< -prog%nm.or.v%scope>prog%np.or. &
           v%lower_expr/=0.or.v%upper_expr/=0.or.v%lower_expr2/=0.or.v%upper_expr2/=0.or. &
           v%lower_expr3/=0.or.v%upper_expr3/=0.or.v%dummy_intent<0.or.v%dummy_intent>3)return
        if(v%is_dummy)then
            if(v%scope<=0.or.v%is_saved.or.v%is_parameter)return
        else
            if(v%is_optional.or.v%dummy_intent/=0)return
        end if
        ok=.true.
        end associate
    end function
    ! An internal file may be one complete element, never a section, substring
    ! or pointer. A is a scalar element designator, not a value to be read.
    logical function valid_internal_write_element(prog,root,s,scope) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root,s,scope
        integer::r,j,a,children(3)
        ok=.false.
        if(.not.allocated(prog%expressions).or..not.allocated(prog%symbols))return
        if(prog%ne<0.or.prog%ne>size(prog%expressions).or.prog%ne>max_expressions.or. &
           prog%ns<0.or.prog%ns>size(prog%symbols).or.prog%ns>max_symbols)return
        if(root<1.or.root>prog%ne.or.s<1.or.s>prog%ns.or.scope<0.or.scope>prog%np)return
        associate(e=>prog%expressions(root),v=>prog%symbols(s))
        r=v%rank
        if(v%typ/=ty_character.or.v%real_kind/=4.or.r<1.or.r>3.or.v%is_parameter.or. &
           v%dummy_intent==1.or.v%is_pointer.or.v%is_class.or.v%is_intrinsic.or. &
           v%character_len< -1.or.v%character_len>65536)return
        if(e%kind/=ex_element.or.e%symbol/=s.or.e%scope/=scope.or.e%typ/=ty_character.or. &
           e%real_kind/=4.or.e%rank/=0.or.e%extent/=0.or.any(e%dims/=0).or. &
           e%character_len/=v%character_len.or.e%parenthesized.or.e%length_expr/=0.or. &
           e%constructor_owner/=0.or.e%constructor_kind_expr/=0.or.e%generic_id/=0.or. &
           e%bound_type/=0.or.e%bound_binding/=0.or.e%intrinsic_mask/=0.or. &
           e%stride/=0.or.e%left2/=0.or.e%right2/=0.or.e%stride2/=0.or.e%left3/=0.or. &
           e%right3/=0.or.e%stride3/=0.or.len_trim(e%op)/=0.or.allocated(e%args).or. &
           any(e%triplet.neqv.[.true.,.false.,.false.]))return
        if(e%value%tag/=0.or.e%value%i/=0.or.e%value%r/=0.or.e%value%l.or.e%value%real_kind/=4.or. &
           allocated(e%value%s).or.allocated(e%value%record))return
        children=[e%left,e%right,e%third]
        if(any(children(:r)<1).or.any(children(:r)>prog%ne).or.any(children(r+1:)/=0))return
        do j=1,r
            a=children(j)
            associate(index=>prog%expressions(a))
            if(index%rank/=0.or.index%extent/=0.or.any(index%dims/=0).or.index%typ/=ty_integer.or. &
               (index%real_kind/=4.and.index%real_kind/=8))return
            if(index%kind==ex_literal)then
                if(index%value%tag/=ty_integer.or.index%value%real_kind/=index%real_kind)return
            end if
            end associate
        end do
        ok=.true.
        end associate
    end function
    ! Bounded internal-element output forbids IMPURE function references in
    ! index/format/items, so evaluation cannot invalidate the frozen file view.
    logical function valid_internal_write_values(prog,ins) result(ok)
        type(program_t),intent(in)::prog
        type(instruction_t),intent(in)::ins
        integer,allocatable::marks(:)
        integer::j
        ok=.false.
        if(.not.allocated(prog%expressions).or..not.allocated(prog%procedures))return
        if(prog%ne<0.or.prog%ne>size(prog%expressions).or.prog%ne>max_expressions.or. &
           prog%np<0.or.prog%np>size(prog%procedures))return
        if(.not.allocated(ins%items))return
        allocate(marks(prog%ne));marks=0
        if(.not.walk(ins%a,0))return
        if(ins%format_expr/=0)then
            if(.not.walk(ins%format_expr,0))return
        end if
        do j=1,size(ins%items)
            if(ins%items(j)<1.or.ins%items(j)>prog%ne)return
            if(is_derived_type(prog%expressions(ins%items(j))%typ))return
            if(.not.walk(ins%items(j),0))return
        end do
        ok=.true.
    contains
        recursive logical function walk(root,depth) result(valid)
            integer,intent(in)::root,depth
            integer::children(10),q,f
            valid=.false.
            if(root<1.or.root>prog%ne.or.depth>512)return
            if(marks(root)==1)return
            if(marks(root)==2)then
                valid=.true.;return
            end if
            marks(root)=1
            associate(e=>prog%expressions(root))
            if(e%kind==ex_user_call)then
                f=e%symbol
                if(f<1.or.f>prog%np)return
                if(prog%procedures(f)%has_impure_prefix.or.prog%procedures(f)%is_subroutine)return
            end if
            children=[e%left,e%right,e%stride,e%left2,e%right2,e%stride2,e%left3,e%right3,e%stride3,e%third]
            do q=1,size(children)
                if(children(q)==0)cycle
                if(.not.walk(children(q),depth+1))return
            end do
            if(allocated(e%args))then
                do q=1,size(e%args)
                    if(e%args(q)==0)cycle
                    if(.not.walk(e%args(q),depth+1))return
                end do
            end if
            end associate
            marks(root)=2;valid=.true.
        end function
    end function
    logical function valid_stdout_unit(prog,s,scope) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::s,scope
        ok=.false.
        if(s<1.or.s>prog%ns.or.scope<0.or.scope>prog%np) return
        if(.not.valid_intrinsic_import(prog%symbols(s))) return
        if(prog%symbols(s)%intrinsic_import/='output_unit') return
        if(prog%symbols(s)%scope==scope) then
            ok=.true.
        else if(prog%symbols(s)%scope<0) then
            ok=module_symbol_visible(prog,s,scope)
        else if(host_symbol_visible(prog,s,scope)) then
            ok=.true.
        else if(prog%symbols(s)%scope==0.and.scope>0) then
            ok=prog%procedures(scope)%module_id==0
        end if
    end function
    logical function valid_intrinsic_import(v) result(ok)
        type(symbol_t),intent(in)::v
        integer(int64)::expected
        integer::j
        logical::kind_vector
        ok=.false.;kind_vector=.false.;expected=0_int64
        select case(v%intrinsic_import)
        case('real32','int32');expected=4_int64
        case('real64','int64');expected=8_int64
        ! Negative availability sentinels, never aliases for supported kinds.
        case('real128','int8','int16');expected=-1_int64
        case('integer_kinds');kind_vector=.true.
        case('output_unit');expected=int(processor_output_unit,int64)
        case default;return
        end select
        if(.not.v%is_intrinsic.or..not.v%is_parameter.or..not.v%parameter_ready.or. &
           v%typ/=ty_integer.or.v%real_kind/=4) return
        if(v%is_dummy.or.v%is_optional.or.v%dummy_intent/=0.or.v%is_class.or. &
           v%is_allocatable.or.v%is_pointer.or.v%is_target.or.v%is_saved.or. &
           v%is_automatic.or.v%assumed_shape.or.v%deferred_character.or. &
           v%initializer_expr/=0.or.v%kind_expr/=0.or.v%length_expr/=0.or.v%character_len/=-1) return
        if(v%lower_expr/=0.or.v%upper_expr/=0.or.v%lower_expr2/=0.or.v%upper_expr2/=0.or. &
           v%lower_expr3/=0.or.v%upper_expr3/=0.or. &
           v%lower_bound/=1.or.v%lower_bound2/=1.or.v%upper_bound2/=1.or. &
           v%lower_bound3/=1.or.v%upper_bound3/=1) return
        if(kind_vector)then
            if(v%rank/=1.or.v%upper_bound/=2.or..not.allocated(v%constant_values))return
            if(size(v%constant_values)/=2)return
            ! The scalar cache is inactive and must remain canonical/empty.
            if(v%constant_value%tag/=0.or.v%constant_value%real_kind/=4.or.v%constant_value%i/=0.or. &
               v%constant_value%r/=0.0_real64.or.v%constant_value%l.or. &
               allocated(v%constant_value%s).or.allocated(v%constant_value%record))return
            do j=1,2
                associate(x=>v%constant_values(j))
                if(x%tag/=ty_integer.or.x%real_kind/=4.or.x%i/=int(4*j,int64).or. &
                   x%r/=0.0_real64.or.x%l.or.allocated(x%s).or.allocated(x%record))return
                end associate
            end do
        else
            if(v%rank/=0.or.v%upper_bound/=1.or.v%constant_value%tag/=ty_integer.or. &
               v%constant_value%real_kind/=4.or.v%constant_value%i/=expected.or. &
               allocated(v%constant_values).or.allocated(v%constant_value%s).or. &
               allocated(v%constant_value%record))return
        end if
        ok=.true.
    end function
    pure logical function is_erf_bessel(name) result(found)
        character(*),intent(in)::name
        select case(name)
        case('erf','bessel_j0','bessel_j1','bessel_jn','bessel_y0','bessel_y1','bessel_yn')
            found=.true.
        case default
            found=.false.
        end select
    end function
    logical function is_numeric_model_inquiry(name) result(found)
        character(*),intent(in)::name
        found=name=='bit_size'.or.name=='digits'.or.name=='epsilon'.or.name=='radix'.or.name=='tiny'.or.name=='huge'.or. &
              name=='minexponent'.or.name=='maxexponent'
    end function
    ! Bounded TRANSPOSE/NORM2 public-IR result and operand metadata.
    pure logical function is_bounds_inquiry(name) result(ok)
        character(*),intent(in)::name
        ok=name=='lbound'.or.name=='ubound'
    end function
    logical function valid_bounds_inquiry(prog,index) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::index
        integer::a,b,j,n,r,sym
        ok=.false.
        if(.not.allocated(prog%expressions))return
        if(index<1.or.index>prog%ne.or.prog%ne>size(prog%expressions))return
        associate(e=>prog%expressions(index))
        if(e%kind/=ex_call.or..not.is_bounds_inquiry(e%op).or..not.allocated(e%args))return
        n=size(e%args)
        if(n<1.or.n>3.or.e%intrinsic_mask<1.or.e%intrinsic_mask>7)return
        if(.not.btest(e%intrinsic_mask,0).or.popcnt(e%intrinsic_mask)/=n)return
        if(any(e%args<1).or.any(e%args>prog%ne).or.any(e%args==index))return
        a=e%args(1);r=prog%expressions(a)%rank
        if(r<1.or.r>3.or.prog%expressions(a)%typ<ty_integer.or.prog%expressions(a)%typ>ty_character)return
        if(prog%expressions(a)%kind==ex_variable)then
            associate(x=>prog%expressions(a))
            sym=x%symbol
            if(.not.allocated(prog%symbols).or.sym<1.or.sym>prog%ns)return
            if(sym>size(prog%symbols))return
            associate(v=>prog%symbols(sym))
            if(x%typ/=v%typ.or.x%real_kind/=v%real_kind.or.x%rank/=v%rank.or. &
               x%character_len/=v%character_len.or.x%left/=0.or.x%right/=0.or.x%stride/=0.or. &
               x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or.x%left3/=0.or.x%right3/=0.or. &
               x%stride3/=0.or.x%third/=0.or.x%length_expr/=0.or.x%generic_id/=0.or. &
               x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or. &
               x%constructor_kind_expr/=0.or.x%constructor_owner/=0.or.len_trim(x%op)/=0.or.allocated(x%args).or. &
               any(x%triplet.neqv.[.true.,.false.,.false.]))return
            end associate
            end associate
        end if
        do j=2,n
            b=e%args(j)
            associate(x=>prog%expressions(b))
            if(x%typ/=ty_integer.or.(x%real_kind/=4.and.x%real_kind/=8).or. &
               x%rank/=0.or.x%extent/=0.or.any(x%dims/=0))return
            end associate
        end do
        if(e%typ/=ty_integer.or.(e%real_kind/=4.and.e%real_kind/=8).or.any(e%dims/=0))return
        if(btest(e%intrinsic_mask,1))then
            if(e%rank/=0.or.e%extent/=0)return
        else
            if(e%rank/=1.or.e%extent/=int(r,int64))return
        end if
        if(.not.btest(e%intrinsic_mask,2).and.e%real_kind/=4)return
        if(e%symbol/=0.or.e%left/=0.or.e%right/=0.or.e%stride/=0.or.e%left2/=0.or.e%right2/=0.or. &
           e%stride2/=0.or.e%left3/=0.or.e%right3/=0.or.e%stride3/=0.or.e%third/=0.or. &
           e%length_expr/=0.or.e%generic_id/=0.or.e%bound_type/=0.or.e%bound_binding/=0.or. &
           e%character_len/=-1.or.e%constructor_kind_expr/=0.or.e%constructor_owner/=0.or.any(e%triplet.neqv.[.true.,.false.,.false.]))return
        ok=.true.
        end associate
    end function
    logical function valid_matrix_intrinsic(prog,index) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::index
        integer::a,b,n,r,k,t
        integer(int64)::extent,dims(3)
        ok=.false.
        if(.not.allocated(prog%expressions))return
        if(index<1.or.index>prog%ne.or.prog%ne>size(prog%expressions))return
        associate(e=>prog%expressions(index))
        if(e%kind/=ex_call.or.(e%op/='transpose'.and.e%op/='norm2').or..not.allocated(e%args))return
        n=size(e%args)
        if(n<1.or.n>2.or.(e%op=='transpose'.and.n/=1))return
        if(any(e%args<1).or.any(e%args>prog%ne).or.any(e%args==index))return
        a=e%args(1);r=prog%expressions(a)%rank;k=prog%expressions(a)%real_kind;t=prog%expressions(a)%typ
        if(k/=4.and.k/=8)return
        if(prog%expressions(a)%kind==ex_variable)then
            if(.not.valid_matrix_variable(prog,a))return
        end if
        if(e%op=='transpose')then
            if(r/=2.or.(t/=ty_integer.and.t/=ty_real))return
        else
            if(r<1.or.r>3.or.t/=ty_real)return
            r=0
            if(n==2)then
                b=e%args(2)
                if(prog%expressions(b)%kind==ex_variable)then
                    if(.not.valid_matrix_variable(prog,b))return
                end if
                if(prog%expressions(b)%typ/=ty_integer.or.prog%expressions(b)%rank/=0.or. &
                   prog%expressions(b)%extent/=0.or.any(prog%expressions(b)%dims/=0).or. &
                   (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8))return
                r=prog%expressions(a)%rank-1
            end if
        end if
        extent=0_int64;dims=0_int64
        if(r>0)extent=-1_int64
        if(r>=2)dims=-1_int64
        if(e%typ/=t.or.e%real_kind/=k.or.e%rank/=r.or.e%extent/=extent.or.any(e%dims/=dims).or. &
           e%intrinsic_mask/=0.or.e%symbol/=0.or.e%left/=0.or.e%right/=0.or.e%stride/=0.or. &
           e%left2/=0.or.e%right2/=0.or.e%stride2/=0.or.e%left3/=0.or.e%right3/=0.or. &
           e%stride3/=0.or.e%third/=0.or.e%length_expr/=0.or.e%generic_id/=0.or. &
           e%bound_type/=0.or.e%bound_binding/=0.or.e%character_len/=-1.or. &
           e%constructor_kind_expr/=0.or.e%constructor_owner/=0.or.any(e%triplet.neqv.[.true.,.false.,.false.]))return
        ok=.true.
        end associate
    end function
    logical function valid_matrix_variable(prog,index) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::index
        integer::s
        ok=.false.
        associate(x=>prog%expressions(index))
        s=x%symbol
        if(.not.allocated(prog%symbols).or.s<1.or.s>prog%ns)return
        if(s>size(prog%symbols))return
        associate(v=>prog%symbols(s))
        if(x%typ/=v%typ.or.x%real_kind/=v%real_kind.or.x%rank/=v%rank.or. &
           x%character_len/=-1.or.x%left/=0.or.x%right/=0.or.x%stride/=0.or. &
           x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or.x%left3/=0.or.x%right3/=0.or. &
           x%stride3/=0.or.x%third/=0.or.x%length_expr/=0.or.x%generic_id/=0.or. &
           x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or. &
           x%constructor_kind_expr/=0.or.x%constructor_owner/=0.or.len_trim(x%op)/=0.or.allocated(x%args).or. &
           any(x%triplet.neqv.[.true.,.false.,.false.]))return
        ok=.true.
        end associate
        end associate
    end function
    logical function valid_character_len_variable(prog,index) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::index
        integer::s,r
        integer(int64)::lo(3),hi(3),dims(3),extent
        ok=.false.
        if(index<1.or.index>prog%ne.or..not.allocated(prog%expressions))return
        if(index>size(prog%expressions))return
        associate(x=>prog%expressions(index))
        s=x%symbol
        if(s<1.or.s>prog%ns.or..not.allocated(prog%symbols))return
        if(s>size(prog%symbols))return
        associate(v=>prog%symbols(s))
        r=v%rank
        if(x%kind/=ex_variable.or.x%typ/=ty_character.or.v%typ/=ty_character.or. &
           x%real_kind/=4.or.v%real_kind/=4.or.r<0.or.r>3.or.x%rank/=r.or. &
           x%character_len/=v%character_len.or.v%character_len< -1.or.v%character_len>65536.or. &
           x%left/=0.or.x%right/=0.or.x%stride/=0.or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or. &
           x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or.x%third/=0.or.x%length_expr/=0.or. &
           x%generic_id/=0.or.x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or. &
           x%constructor_kind_expr/=0.or.x%constructor_owner/=0.or.len_trim(x%op)/=0.or.allocated(x%args).or. &
           any(x%triplet.neqv.[.true.,.false.,.false.]))return
        extent=0_int64;dims=0_int64
        if(r>0)then
            if(v%is_allocatable.or.v%is_pointer.or.v%assumed_shape.or.v%is_automatic)then
                extent=-1_int64
                if(r>=2)dims=-1_int64
            else
                lo=[v%lower_bound,v%lower_bound2,v%lower_bound3]
                hi=[v%upper_bound,v%upper_bound2,v%upper_bound3]
                if(any(lo(:r)< -2147483648_int64).or.any(lo(:r)>2147483647_int64).or. &
                   any(hi(:r)< -2147483648_int64).or.any(hi(:r)>2147483647_int64))return
                dims=1_int64;dims(:r)=max(0_int64,hi(:r)-lo(:r)+1_int64)
                if(any(dims>2147483647_int64))return
                extent=shape_size(dims)
                if(extent>max_array_elements)return
                if(r==1)dims=0_int64
            end if
        end if
        ok=x%extent==extent.and.all(x%dims==dims)
        end associate
        end associate
    end function
    logical function exponent_inquiry_operand_supported(prog,root) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root
        integer,allocatable::marks(:)
        ok=.false.
        if(.not.allocated(prog%expressions)) return
        if(prog%ne<1.or.prog%ne>max_expressions.or.prog%ne>size(prog%expressions)) return
        allocate(marks(prog%ne),source=0)
        ok=walk(root,0)
    contains
        recursive logical function walk(index,depth) result(valid)
            integer,intent(in)::index,depth
            integer::j,children(10)
            valid=.false.
            if(index<1.or.index>prog%ne.or.depth>512) return
            if(marks(index)==1) return
            if(marks(index)==2) then
                valid=.true.;return
            end if
            marks(index)=1
            associate(x=>prog%expressions(index))
            if(x%kind==ex_element.or.x%kind==ex_section.or.x%kind==ex_component.or. &
               x%kind==ex_substring.or.x%kind==ex_gather_rows) return
            children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third]
            do j=1,size(children)
                if(children(j)==0) cycle
                if(.not.walk(children(j),depth+1)) return
            end do
            if(allocated(x%args)) then
                if(size(x%args)>max_expressions) return
                do j=1,size(x%args)
                    if(x%args(j)==0) cycle
                    if(.not.walk(x%args(j),depth+1)) return
                end do
            end if
            end associate
            marks(index)=2;valid=.true.
        end function
    end function
    ! Saturating shape product: no intermediate overflow, including huge empty shapes.
    pure integer(int64) function shape_size(dims) result(n)
        integer(int64),intent(in)::dims(:)
        integer::d
        n=0_int64
        if(any(dims==0_int64)) return
        n=-1_int64
        if(any(dims<0_int64)) return
        n=1_int64
        do d=1,size(dims)
            if(dims(d)>max_array_elements/n) then
                n=int(max_array_elements,int64)+1_int64;return
            end if
            n=n*dims(d)
        end do
    end function
    ! A bare vector section is a nondefinable actual, not an implicitly
    ! parenthesized expression. Admit only the bounded CHARACTER IN case;
    ! the runtime separately retains its base identity for alias checks.
    logical function bare_character_gather_input(prog,index,dummy) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::index,dummy
        ok=.false.
        if(.not.allocated(prog%expressions).or..not.allocated(prog%symbols))return
        if(index<1.or.index>prog%ne.or.index>size(prog%expressions).or. &
           dummy<1.or.dummy>prog%ns.or.dummy>size(prog%symbols))return
        associate(e=>prog%expressions(index),v=>prog%symbols(dummy))
        if(e%kind/=ex_gather_rows.or.e%parenthesized.or.e%typ/=ty_character.or. &
           e%rank/=1.or.e%real_kind/=4)return
        if(.not.v%is_dummy.or.v%dummy_intent/=1.or.v%typ/=ty_character.or. &
           v%rank/=1.or.v%real_kind/=4.or..not.v%assumed_shape.or. &
           v%is_allocatable.or.v%is_pointer.or.v%is_target.or.v%is_class)return
        ok=.true.
        end associate
    end function
    ! Numeric rank-one vector actuals use the same conservative read-only
    ! association policy as CHARACTER, with exact INTEGER/REAL kind agreement.
    logical function bare_numeric_gather_input(prog,index,dummy) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::index,dummy
        ok=.false.
        if(.not.allocated(prog%expressions).or..not.allocated(prog%symbols))return
        if(index<1.or.index>prog%ne.or.index>size(prog%expressions).or. &
           dummy<1.or.dummy>prog%ns.or.dummy>size(prog%symbols))return
        associate(e=>prog%expressions(index),v=>prog%symbols(dummy))
        if(e%kind/=ex_gather_rows.or.e%parenthesized.or.e%rank/=1.or. &
           (e%typ/=ty_integer.and.e%typ/=ty_real).or.(e%real_kind/=4.and.e%real_kind/=8))return
        if(.not.v%is_dummy.or.v%dummy_intent/=1.or.v%typ/=e%typ.or. &
           v%rank/=1.or.v%real_kind/=e%real_kind.or..not.v%assumed_shape.or. &
           v%is_allocatable.or.v%is_pointer.or.v%is_target.or.v%is_class)return
        ok=.true.
        end associate
    end function
    logical function bare_gather_input(prog,index,dummy) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::index,dummy
        ok=bare_character_gather_input(prog,index,dummy).or.bare_numeric_gather_input(prog,index,dummy)
    end function
    ! Shared module/SAVE data and live host captures must not be accessed both
    ! through value-result actual association and a transitive host/USE path.
    ! Ordinary recursive host re-entry starts a distinct activation.
    logical function module_actual_conflict(prog,proc,items) result(conflict)
        type(program_t),intent(in)::prog
        integer,intent(in)::proc,items(:)
        logical,allocatable::reachable(:),actual(:)
        integer,allocatable::pending(:)
        integer::j,e,s,f,c,q,top,t
        conflict=host_actual_conflict(prog,proc,items)
        if(conflict) return
        allocate(actual(prog%ns),reachable(prog%np),pending(prog%np))
        actual=.false.;reachable=.false.;top=0
        do j=1,size(items)
            e=items(j)
            if(e<1.or.e>prog%ne) cycle
            associate(x=>prog%expressions(e))
            if(x%parenthesized) cycle
            if(x%kind/=ex_variable.and.x%kind/=ex_element.and.x%kind/=ex_section.and.x%kind/=ex_substring)then
                if(x%kind/=ex_gather_rows.or.x%rank/=1.or. &
                   (x%typ/=ty_character.and.x%typ/=ty_integer.and.x%typ/=ty_real))cycle
            end if
            s=x%symbol
            if(s<1.or.s>prog%ns) cycle
            if((prog%symbols(s)%scope<0.or.prog%symbols(s)%is_saved).and. &
               .not.prog%symbols(s)%is_parameter) actual(s)=.true.
            end associate
        end do
        if(.not.any(actual)) return
        if(proc<1.or.proc>prog%np) then
            conflict=.true.;return
        end if
        top=1;pending(top)=proc;reachable(proc)=.true.
        do while(top>0)
            f=pending(top);top=top-1
            do e=1,prog%ne
                associate(x=>prog%expressions(e))
                if(x%scope/=f) cycle
                if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section.or.x%kind==ex_substring.or.x%kind==ex_gather_rows) then
                    s=x%symbol
                    if(s>=1.and.s<=prog%ns) then
                        if(actual(s)) then
                            conflict=.true.;return
                        end if
                    end if
                else if(x%kind==ex_user_call) then
                    q=x%symbol
                    if(q>=1.and.q<=prog%np) then
                        if(.not.reachable(q)) then
                            reachable(q)=.true.;top=top+1;pending(top)=q
                        end if
                    end if
                end if
                end associate
            end do
            do c=1,prog%nc
                if(prog%code(c)%scope/=f) cycle
                s=module_write_target(prog%code(c))
                if(s>=1.and.s<=prog%ns) then
                    if(actual(s)) then
                        conflict=.true.;return
                    end if
                end if
                ! Defined formatted WRITE callbacks are implicit procedure
                ! edges, and can access module state just like ordinary calls.
                if(prog%code(c)%op==op_print.or.prog%code(c)%op==op_write_internal.or. &
                   prog%code(c)%op==op_write_defined) then
                    if(allocated(prog%code(c)%items)) then
                        do j=1,size(prog%code(c)%items)
                            e=prog%code(c)%items(j)
                            if(e<1.or.e>prog%ne) cycle
                            t=prog%expressions(e)%typ-ty_derived_base
                            if(t<1.or.t>prog%nt) cycle
                            q=prog%derived_types(t)%write_procedure
                            if(q<1.or.q>prog%np) cycle
                            if(.not.reachable(q)) then
                                reachable(q)=.true.;top=top+1;pending(top)=q
                            end if
                        end do
                    end if
                end if
                if(prog%code(c)%op/=op_call) cycle
                q=prog%code(c)%symbol
                if(q>=1.and.q<=prog%np) then
                    if(.not.reachable(q)) then
                        reachable(q)=.true.;top=top+1;pending(top)=q
                    end if
                end if
            end do
        end do
    end function
    logical function valid_internal_procedure(prog,f) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::f
        integer::h
        ok=.false.
        if(f<1.or.f>prog%np) return
        h=prog%procedures(f)%parent_procedure
        if(h==0) then
            ok=.true.;return
        end if
        if(h<1.or.h>=f) return
        if(prog%procedures(h)%parent_procedure/=0.or.prog%procedures(h)%module_id<=0.or. &
           prog%procedures(h)%module_id>prog%nm.or. &
           prog%procedures(h)%is_elemental.or.prog%procedures(f)%is_public) return
        if(prog%procedures(f)%module_id/=prog%procedures(h)%module_id) return
        if(prog%procedures(f)%line<=prog%procedures(h)%line.or. &
           prog%procedures(f)%end_line>=prog%procedures(h)%end_line) return
        ok=.true.
    end function
    logical function internal_call_visible(prog,caller,callee) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::caller,callee
        integer::h
        ok=.false.
        if(callee<1.or.callee>prog%np) return
        h=prog%procedures(callee)%parent_procedure
        if(h==0) then
            ok=.true.;return
        end if
        if(caller<1.or.caller>prog%np) return
        ok=caller==h.or.prog%procedures(caller)%parent_procedure==h
    end function
    logical function host_symbol_visible(prog,s,scope) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::s,scope
        integer::h
        ok=.false.
        if(s<1.or.s>prog%ns.or.scope<1.or.scope>prog%np) return
        h=prog%procedures(scope)%parent_procedure
        if(h<=0.or.h>=scope) return
        associate(v=>prog%symbols(s))
        if(v%scope/=h) return
        if(v%is_parameter) then
            ok=.true.;return
        end if
        if(v%typ<ty_integer.or.v%typ>ty_character.or.v%is_optional.or.v%is_pointer.or. &
           v%is_target.or.v%is_allocatable.or.v%is_class.or.v%deferred_character) return
        if(v%rank<0.or.v%rank>3.or.(v%typ==ty_character.and.v%character_len<0)) return
        if(prog%procedures(h)%result_symbol==s) return
        if(prog%procedures(scope)%is_simple) return
        ok=.true.
        end associate
    end function
    logical function host_actual_conflict(prog,proc,items) result(conflict)
        type(program_t),intent(in)::prog
        integer,intent(in)::proc,items(:)
        logical::seen(prog%np)
        integer::pending(prog%np),j,e,s,h,f,c,q,top
        conflict=.false.
        if(proc<1.or.proc>prog%np) return
        do j=1,size(items)
            e=items(j)
            if(e<1.or.e>prog%ne) cycle
            associate(x=>prog%expressions(e))
            if(x%parenthesized) cycle
            if(x%kind/=ex_variable.and.x%kind/=ex_element.and.x%kind/=ex_section.and.x%kind/=ex_substring)then
                if(x%kind/=ex_gather_rows.or.x%rank/=1.or. &
                   (x%typ/=ty_character.and.x%typ/=ty_integer.and.x%typ/=ty_real))cycle
            end if
            s=x%symbol
            if(s<1.or.s>prog%ns) cycle
            h=prog%symbols(s)%scope
            if(h<=0.or.h>prog%np.or.prog%symbols(s)%is_parameter.or.prog%symbols(s)%is_saved) cycle
            if(prog%procedures(h)%parent_procedure/=0) cycle
            if(.not.any(prog%procedures(:prog%np)%parent_procedure==h)) cycle
            end associate
            seen=.false.;top=1;pending(top)=proc;seen(proc)=.true.
            do while(top>0)
                f=pending(top);top=top-1
                ! A call into the defining host starts a new activation. Its
                ! locals and its contained procedures do not alias this actual.
                if(f==h) cycle
                do e=1,prog%ne
                    associate(x=>prog%expressions(e))
                    if(x%scope/=f) cycle
                    if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section.or.x%kind==ex_substring.or.x%kind==ex_gather_rows) then
                        if(x%symbol==s) then
                            conflict=.true.;return
                        end if
                    else if(x%kind==ex_user_call) then
                        q=x%symbol
                        if(q<1.or.q>prog%np) cycle
                        if(.not.seen(q)) then
                            seen(q)=.true.;top=top+1;pending(top)=q
                        end if
                    end if
                    end associate
                end do
                do c=1,prog%nc
                    if(prog%code(c)%scope/=f) cycle
                    if(module_write_target(prog%code(c))==s) then
                        conflict=.true.;return
                    end if
                    if(prog%code(c)%op/=op_call) cycle
                    q=prog%code(c)%symbol
                    if(q<1.or.q>prog%np) cycle
                    if(.not.seen(q)) then
                        seen(q)=.true.;top=top+1;pending(top)=q
                    end if
                end do
            end do
        end do
    end function
    ! Specification-length allocatable dummies retain a nondeferred length.
    ! Their actual descriptor must agree with the entry-time specification value.
    logical function valid_scalar_character_allocatable(prog,s) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::s
        integer::owner
        ok=.false.
        if(s<1.or.s>prog%ns) return
        associate(v=>prog%symbols(s))
        owner=v%scope
        if(v%rank/=0.or.v%typ/=ty_character.or.v%real_kind/=4.or..not.v%is_allocatable.or. &
           v%is_parameter.or.v%is_pointer.or.v%is_saved.or.v%is_automatic.or.v%assumed_shape.or. &
           v%is_class.or.v%is_intrinsic.or.v%initializer_expr/=0.or.v%kind_expr/=0.or. &
           v%parameter_ready.or.allocated(v%constant_values).or. &
           v%character_len< -1.or.v%character_len>65536.or.v%length_expr<0.or.v%length_expr>prog%ne) return
        if(owner < -prog%nm.or.owner>prog%np) return
        if(v%lower_expr/=0.or.v%upper_expr/=0.or.v%lower_expr2/=0.or.v%upper_expr2/=0.or. &
           v%lower_expr3/=0.or.v%upper_expr3/=0.or. &
           v%lower_bound/=1.or.v%upper_bound/=1.or.v%lower_bound2/=1.or.v%upper_bound2/=1.or. &
           v%lower_bound3/=1.or.v%upper_bound3/=1) return
        if(v%deferred_character) then
            if(v%character_len/=-1.or.v%length_expr/=0) return
        else if(v%character_len==-1.and.v%length_expr==0.and..not.v%is_dummy) then
            return
        end if
        if(v%is_dummy) then
            if(owner<1.or.v%dummy_intent<1.or.v%dummy_intent>3) return
            if(prog%procedures(owner)%is_elemental.or..not.allocated(prog%procedures(owner)%args)) return
            if(count(prog%procedures(owner)%args==s)/=1) return
            ! Runtime specification-length scalar dummies are a separate extension.
            if(v%character_len<0.and.v%length_expr/=0) return
        else
            if(v%is_optional.or.v%dummy_intent/=0) return
        end if
        ok=.true.
        end associate
    end function
    logical function valid_character_length_dummy(prog,s) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::s
        integer::owner,e
        ok=.false.
        if(s<1.or.s>prog%ns) return
        associate(v=>prog%symbols(s))
        owner=v%scope;e=v%length_expr
        if(owner<1.or.owner>prog%np.or.e<1.or.e>prog%ne) return
        if(v%typ/=ty_character.or.v%real_kind/=4.or.v%character_len/=-1.or. &
           .not.v%is_dummy.or..not.v%is_allocatable.or.v%is_optional.or.v%deferred_character.or. &
           v%rank<1.or.v%rank>3.or.v%dummy_intent<1.or.v%dummy_intent>3.or. &
           v%is_pointer.or.v%is_parameter.or.v%is_saved.or.v%is_class.or.v%is_intrinsic.or. &
           v%is_automatic.or.v%assumed_shape.or.v%initializer_expr/=0.or.v%kind_expr/=0.or. &
           v%parameter_ready.or.allocated(v%constant_values)) return
        if(prog%procedures(owner)%is_elemental.or..not.allocated(prog%procedures(owner)%args)) return
        if(count(prog%procedures(owner)%args==s)/=1) return
        if(prog%expressions(e)%real_kind/=4.and.prog%expressions(e)%real_kind/=8) return
        ok=valid_automatic_bound(prog,e,owner)
        end associate
    end function
    logical function valid_saved_local(prog,s) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::s
        integer::owner,e
        ok=.false.
        if(s<1.or.s>prog%ns) return
        associate(v=>prog%symbols(s))
        owner=v%scope;e=v%initializer_expr
        if(.not.v%is_saved.or.owner<1.or.owner>prog%np.or.e<1.or.e>prog%ne) return
        if(prog%procedures(owner)%is_pure.or.prog%procedures(owner)%is_simple.or. &
           prog%procedures(owner)%result_symbol==s) return
        if(v%rank/=0.or.v%typ<ty_integer.or.v%typ>ty_character.or.v%is_dummy.or.v%is_parameter.or. &
           v%is_optional.or.v%dummy_intent/=0.or.v%is_allocatable.or.v%is_pointer.or.v%is_target.or. &
           v%is_class.or.v%is_intrinsic.or.v%is_automatic.or.v%assumed_shape.or.v%deferred_character) return
        if(v%real_kind/=4.and.v%real_kind/=8) return
        if(v%typ>=ty_logical.and.v%real_kind/=4) return
        if(v%lower_expr/=0.or.v%upper_expr/=0.or.v%lower_expr2/=0.or.v%upper_expr2/=0.or. &
           v%lower_expr3/=0.or.v%upper_expr3/=0.or.v%lower_bound/=1.or.v%upper_bound/=1.or. &
           v%lower_bound2/=1.or.v%upper_bound2/=1.or.v%lower_bound3/=1.or.v%upper_bound3/=1) return
        if(v%typ==ty_character) then
            if(v%character_len<0.or.v%character_len>65536) return
            if(v%length_expr/=0) then
                if(v%length_expr<1.or.v%length_expr>prog%ne) return
                if(prog%expressions(v%length_expr)%typ/=ty_integer.or.prog%expressions(v%length_expr)%rank/=0) return
                if(.not.bound_constant_expression(prog,v%length_expr,0)) return
            end if
        else if(v%character_len/=-1.or.v%length_expr/=0) then
            return
        end if
        if(.not.v%parameter_ready.or.v%constant_value%tag/=v%typ.or. &
           v%constant_value%real_kind/=v%real_kind.or.allocated(v%constant_values)) return
        if(prog%expressions(e)%rank/=0.or.prog%expressions(e)%scope/=owner) return
        if(.not.bound_constant_expression(prog,e,0)) return
        ok=.true.
        end associate
    end function
    logical function valid_allocation_output(prog,root,typ,scope) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root,typ,scope
        integer::sym
        ok=.false.
        if(.not.allocated(prog%expressions).or..not.allocated(prog%symbols))return
        if(prog%ne<0.or.prog%ne>size(prog%expressions).or.prog%ne>max_expressions.or.prog%ns<0.or.prog%ns>size(prog%symbols).or.prog%ns>max_symbols)return
        if(scope<0.or.scope>prog%np)return
        if(root<1.or.root>prog%ne.or.(typ/=ty_integer.and.typ/=ty_character))return
        associate(e=>prog%expressions(root))
        sym=e%symbol
        if(sym<1.or.sym>prog%ns)return
        associate(v=>prog%symbols(sym))
        if(e%kind/=ex_variable.or.e%parenthesized.or.e%scope/=scope.or.e%typ/=typ.or.e%rank/=0.or. &
           e%extent/=0.or.any(e%dims/=0).or.e%real_kind/=v%real_kind.or.e%character_len/=v%character_len.or. &
           e%left/=0.or.e%right/=0.or.e%stride/=0.or.e%left2/=0.or.e%right2/=0.or.e%stride2/=0.or. &
           e%left3/=0.or.e%right3/=0.or.e%stride3/=0.or.e%third/=0.or.e%length_expr/=0.or. &
           e%generic_id/=0.or.e%bound_type/=0.or.e%bound_binding/=0.or.e%intrinsic_mask/=0.or. &
           e%constructor_kind_expr/=0.or.e%constructor_owner/=0.or.len_trim(e%op)/=0.or.allocated(e%args).or. &
           any(e%triplet.neqv.[.true.,.false.,.false.]).or.e%value%tag/=0.or.e%value%i/=0.or. &
           e%value%r/=0.or.e%value%l.or.e%value%real_kind/=4.or.allocated(e%value%s).or. &
           allocated(e%value%record))return
        if(v%typ/=typ.or.v%rank/=0.or.v%scope/=scope.or.v%is_parameter.or.v%is_pointer.or.v%dummy_intent==1.or.v%is_class.or.v%is_intrinsic)return
        if(typ==ty_integer)then
            if(v%real_kind/=4.and.v%real_kind/=8)return
            if(v%is_allocatable)return
        else
            ! F2023 changed deferred-length ERRMSG assignment semantics; keep
            ! this first slice to fixed/assumed lengths common to F2018/F2023.
            if(v%real_kind/=4.or.v%deferred_character.or.v%character_len< -1.or.v%character_len>65536)return
        end if
        ok=.true.
        end associate
        end associate
    end function
    logical function valid_allocation_message(prog,ins) result(ok)
        type(program_t),intent(in)::prog
        type(instruction_t),intent(in)::ins
        integer::j,stat_symbol,errmsg_symbol
        integer,allocatable::marks(:)
        ok=.false.
        if(ins%third==0)then
            ok=.true.;return
        end if
        if(.not.valid_allocation_output(prog,ins%third,ty_character,ins%scope))return
        errmsg_symbol=prog%expressions(ins%third)%symbol;stat_symbol=0
        if(ins%symbol==errmsg_symbol)return
        if(ins%a/=0)then
            if(.not.valid_allocation_output(prog,ins%a,ty_integer,ins%scope))return
            stat_symbol=prog%expressions(ins%a)%symbol
            if(stat_symbol==errmsg_symbol.or.stat_symbol==ins%symbol)return
        end if
        if(.not.allocated(ins%items))return
        if(size(ins%items)>6)return
        allocate(marks(prog%ne),source=0)
        if(ins%b/=0)then
            if(.not.walk(ins%b,0))return
        end if
        do j=1,size(ins%items)
            if(ins%items(j)==0.and.mod(j,2)==1)cycle
            if(.not.walk(ins%items(j),0))return
        end do
        ok=.true.
    contains
        recursive logical function walk(root,depth) result(valid)
            integer,intent(in)::root,depth
            integer::k,children(10)
            valid=.false.
            if(root<1.or.root>prog%ne.or.depth>512)return
            if(marks(root)==1)return
            if(marks(root)==2)then
                valid=.true.;return
            end if
            marks(root)=1
            associate(x=>prog%expressions(root))
            ! Bounds with ERRMSG are side-effect-free and independent of both
            ! outputs. This also covers metadata inquiries such as LEN(ERRMSG).
            if(x%kind==ex_user_call)return
            if(x%symbol==errmsg_symbol.or.(stat_symbol>0.and.x%symbol==stat_symbol))return
            children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third]
            do k=1,size(children)
                if(children(k)==0)cycle
                if(.not.walk(children(k),depth+1))return
            end do
            if(allocated(x%args))then
                if(size(x%args)>max_expressions)return
                do k=1,size(x%args)
                    if(x%args(k)==0)cycle
                    if(.not.walk(x%args(k),depth+1))return
                end do
            end if
            end associate
            marks(root)=2;valid=.true.
        end function
    end function
    logical function valid_allocation_group(prog,first) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::first
        integer::n,j,k,s,stat_symbol,errmsg_symbol,root,targets(max_allocation_objects)
        integer,allocatable::marks(:)
        ok=.false.;targets=0;stat_symbol=0;errmsg_symbol=0
        if(.not.allocated(prog%code).or..not.allocated(prog%symbols).or. &
           .not.allocated(prog%expressions)) return
        if(prog%nc<1.or.prog%nc>size(prog%code).or.prog%nc>max_instructions.or. &
           prog%ns<1.or.prog%ns>size(prog%symbols).or.prog%ns>max_symbols.or. &
           prog%ne<0.or.prog%ne>size(prog%expressions).or.prog%ne>max_expressions) return
        if(first<1.or.first>prog%nc) return
        associate(head=>prog%code(first))
        n=head%c
        if(n<2.or.n>max_allocation_objects.or.n>prog%nc-first+1.or.head%d/=1) return
        if(head%op/=op_allocate.and.head%op/=op_deallocate) return
        if(head%target/=first+n) return
        if(head%a/=0) then
            if(.not.valid_allocation_output(prog,head%a,ty_integer,head%scope))return
            stat_symbol=prog%expressions(head%a)%symbol
            if(stat_symbol<1.or.stat_symbol>prog%ns) return
        end if
        if(head%third/=0)then
            if(.not.valid_allocation_output(prog,head%third,ty_character,head%scope))return
            errmsg_symbol=prog%expressions(head%third)%symbol
            if(errmsg_symbol==stat_symbol)return
        end if
        do j=1,n
            associate(ins=>prog%code(first+j-1))
            if(ins%op/=head%op.or.ins%c/=n.or.ins%d/=j.or.ins%target/=first+n.or. &
               ins%scope/=head%scope.or.ins%line/=head%line.or.ins%column/=head%column.or. &
               ins%a/=head%a.or.ins%b/=head%b.or.ins%component/=0.or.ins%generic_id/=0.or. &
               ins%third/=head%third.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
               len_trim(ins%construct_name)/=0.or.allocated(ins%format).or.ins%format_expr/=0.or.ins%advance_mode/=0) return
            s=ins%symbol
            if(s<1.or.s>prog%ns.or.s==stat_symbol.or.s==errmsg_symbol) return
            if(any(targets(:j-1)==s)) return
            targets(j)=s
            if(.not.prog%symbols(s)%is_allocatable.or.prog%symbols(s)%rank<0.or. &
               (prog%symbols(s)%rank==0.and.prog%symbols(s)%typ/=ty_character).or. &
               prog%symbols(s)%rank>3.or.prog%symbols(s)%dummy_intent==1.or. &
               prog%symbols(s)%is_parameter.or.prog%symbols(s)%is_pointer) return
            if(.not.allocated(ins%items)) return
            if(ins%op==op_allocate) then
                if(size(ins%items)/=2*prog%symbols(s)%rank) return
                if((ins%b/=0).neqv.prog%symbols(s)%deferred_character) return
            else
                if(size(ins%items)/=0.or.ins%b/=0) return
            end if
            end associate
        end do
        allocate(marks(prog%ne),source=0)
        if(head%b/=0) then
            if(.not.walk(head%b,0)) return
        end if
        do j=1,n
            do k=1,size(prog%code(first+j-1)%items)
                root=prog%code(first+j-1)%items(k)
                if(root==0.and.mod(k,2)==1) cycle
                if(.not.walk(root,0)) return
            end do
        end do
        end associate
        ok=.true.
    contains
        recursive logical function walk(e,depth) result(valid)
            integer,intent(in)::e,depth
            integer::q,children(10)
            valid=.false.
            if(e<1.or.e>prog%ne.or.depth>512) return
            if(marks(e)==1) return
            if(marks(e)==2) then
                valid=.true.;return
            end if
            marks(e)=1
            associate(x=>prog%expressions(e))
            ! Multi-object bounds are side-effect-free in this bounded subset.
            if(x%kind==ex_user_call) return
            if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section.or. &
               x%kind==ex_component.or.x%kind==ex_substring.or.x%kind==ex_gather_rows) then
                if(any(targets(:n)==x%symbol).or.(stat_symbol>0.and.x%symbol==stat_symbol).or. &
                   (errmsg_symbol>0.and.x%symbol==errmsg_symbol)) return
            end if
            children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third]
            do q=1,size(children)
                if(children(q)==0) cycle
                if(.not.walk(children(q),depth+1)) return
            end do
            if(allocated(x%args)) then
                if(size(x%args)>max_expressions) return
                do q=1,size(x%args)
                    if(x%args(q)==0) cycle
                    if(.not.walk(x%args(q),depth+1)) return
                end do
            end if
            end associate
            marks(e)=2;valid=.true.
        end function
    end function
    integer function module_write_target(ins) result(s)
        type(instruction_t),intent(in)::ins
        s=0
        select case(ins%op)
        case(op_assign,op_do,op_write_internal,op_random_number,op_allocate,op_deallocate)
            s=ins%symbol
        end select
    end function
    logical function module_symbol_visible(prog,s,scope) result(visible)
        type(program_t),intent(in)::prog
        integer,intent(in)::s,scope
        integer::host,u,m
        visible=.false.
        if(s<1.or.s>prog%ns) return
        if(prog%symbols(s)%scope>=0) return
        host=scope
        if(scope>0) then
            if(scope>prog%np) return
            host=-prog%procedures(scope)%module_id
        end if
        if(prog%symbols(s)%scope==host) then
            visible=.true.;return
        end if
        if(.not.prog%symbols(s)%is_public) return
        m=-prog%symbols(s)%scope
        do u=1,prog%nu
            if(prog%uses(u)/=m.or.prog%use_scopes(u)/=host) cycle
            if(prog%use_only(u)) then
                if(.not.any(prog%only_names(:prog%n_only(u),u)==prog%symbols(s)%name)) cycle
            end if
            visible=.true.;return
        end do
    end function
    ! Bounded specification expressions are evaluated after dummy association
    ! and before local allocation. Eligible PURE module calls use ordinary frames.
    recursive logical function valid_automatic_bound(prog,root,scope,depth) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root,scope
        integer,intent(in),optional::depth
        integer::level,s,j,a,f,result_symbol,dummy
        ok=.false.;level=0
        if(present(depth)) level=depth
        if(level>512.or.scope<1.or.scope>prog%np) return
        if(root<1.or.root>prog%ne) return
        associate(e=>prog%expressions(root))
        if(e%scope/=scope.or.e%rank/=0.or.e%typ/=ty_integer) return
        select case(e%kind)
        case(ex_literal)
            ok=e%value%tag==ty_integer
        case(ex_variable)
            s=e%symbol
            if(s<1.or.s>prog%ns) return
            associate(v=>prog%symbols(s))
            if(v%typ/=ty_integer.or.v%rank/=0) return
            ok=v%is_parameter.and.v%parameter_ready
            if(v%is_dummy.and.(v%scope==scope.or.host_symbol_visible(prog,s,scope)).and..not.v%is_optional) &
                ok=v%dummy_intent==1.or.v%dummy_intent==3
            end associate
        case(ex_unary,ex_binary)
            if(e%kind==ex_unary) then
                if(e%op/='+'.and.e%op/='-') return
            else
                if(e%op/='+'.and.e%op/='-'.and.e%op/='*'.and.e%op/='/'.and.e%op/='**') return
            end if
            ok=valid_automatic_bound(prog,e%left,scope,level+1)
            if(ok.and.e%kind==ex_binary) ok=valid_automatic_bound(prog,e%right,scope,level+1)
        case(ex_user_call)
            ! Specification calls are not constant expressions. Keep this small:
            ! nonrecursive PURE module functions with mandatory scalar INTEGER
            ! input dummies and a scalar INTEGER result, all of kind 4 or 8.
            f=e%symbol
            if(f<1.or.f>prog%np.or..not.allocated(e%args)) return
            associate(proc=>prog%procedures(f))
            if(proc%module_id<1.or.proc%module_id>prog%nm.or.proc%parent_procedure/=0.or.proc%is_subroutine.or. &
               .not.proc%is_pure.or.proc%has_impure_prefix.or.proc%is_recursive) return
            if(.not.(proc%has_pure_prefix.or.proc%is_simple.or.proc%is_elemental)) return
            if(.not.allocated(proc%args)) return
            if(size(e%args)/=size(proc%args)) return
            if(e%generic_id/=0.or.e%bound_type/=0.or.e%bound_binding/=0.or.len_trim(e%op)/=0) return
            result_symbol=proc%result_symbol
            if(result_symbol<1.or.result_symbol>prog%ns) return
            associate(v=>prog%symbols(result_symbol))
            if(v%scope/=f.or.v%typ/=ty_integer.or.v%rank/=0.or.v%is_dummy.or. &
               v%is_parameter.or.v%is_allocatable.or.e%real_kind/=v%real_kind) return
            if(v%real_kind/=4.and.v%real_kind/=8) return
            end associate
            do j=1,size(proc%args)
                dummy=proc%args(j);a=e%args(j)
                if(dummy<1.or.dummy>prog%ns.or.a<1.or.a>prog%ne) return
                associate(v=>prog%symbols(dummy))
                if(v%scope/=f.or..not.v%is_dummy.or.v%dummy_intent/=1.or.v%is_optional.or. &
                   v%is_allocatable.or.v%typ/=ty_integer.or.v%rank/=0) return
                if(v%real_kind/=4.and.v%real_kind/=8) return
                if(prog%expressions(a)%real_kind/=v%real_kind) return
                end associate
                if(.not.valid_automatic_bound(prog,a,scope,level+1)) return
            end do
            end associate
            ok=.true.
        case(ex_call)
            if(.not.allocated(e%args)) return
            if(e%op=='count') then
                if(size(e%args)<1.or.size(e%args)>3) return
                if(e%intrinsic_mask<1.or.e%intrinsic_mask>7) return
                if(.not.btest(e%intrinsic_mask,0).or.popcnt(e%intrinsic_mask)/=size(e%args)) return
                a=e%args(1)
                if(a<1.or.a>prog%ne) return
                if(prog%expressions(a)%typ/=ty_logical.or.prog%expressions(a)%rank<1.or. &
                   prog%expressions(a)%rank>2) return
                if(btest(e%intrinsic_mask,1).and.prog%expressions(a)%rank/=1) return
                ok=valid_bound_mask_value(prog,a,scope,level+1)
                if(btest(e%intrinsic_mask,1)) then
                    if(.not.valid_automatic_bound(prog,e%args(2),scope,level+1)) ok=.false.
                end if
                if(btest(e%intrinsic_mask,2)) then
                    if(.not.bound_constant_expression(prog,e%args(size(e%args)),level+1)) ok=.false.
                end if
            else if(e%op=='len_trim'.or.e%op=='sum') then
                ! Value-based CHARACTER specification expressions are bounded
                ! to LEN_TRIM of a nonoptional dummy/PARAMETER, optionally SUM.
                a=root
                if(e%op=='sum') then
                    if(size(e%args)/=1) return
                    a=e%args(1)
                    if(a<1.or.a>prog%ne) return
                    if(prog%expressions(a)%kind/=ex_call.or.prog%expressions(a)%op/='len_trim'.or. &
                       prog%expressions(a)%rank<1.or.prog%expressions(a)%rank>2) return
                end if
                if(.not.allocated(prog%expressions(a)%args)) return
                if(size(prog%expressions(a)%args)<1.or.size(prog%expressions(a)%args)>2) return
                if(size(prog%expressions(a)%args)==2) then
                    if(.not.bound_constant_expression(prog,prog%expressions(a)%args(2),level+1)) return
                end if
                a=prog%expressions(a)%args(1)
                if(a<1.or.a>prog%ne) return
                if(prog%expressions(a)%kind/=ex_variable.or.prog%expressions(a)%typ/=ty_character) return
                s=prog%expressions(a)%symbol
                if(s<1.or.s>prog%ns) return
                associate(v=>prog%symbols(s))
                ok=v%is_parameter.and.v%parameter_ready
                if(v%scope==scope.and.v%is_dummy.and..not.v%is_optional) &
                    ok=v%dummy_intent==1.or.v%dummy_intent==3
                end associate
            else if(e%op=='len') then
                if(size(e%args)/=1) return
                a=e%args(1)
                if(a<1.or.a>prog%ne) return
                if(prog%expressions(a)%typ/=ty_character) return
                if(prog%expressions(a)%kind/=ex_variable.and.prog%expressions(a)%kind/=ex_element) return
                s=prog%expressions(a)%symbol
                if(s<1.or.s>prog%ns) return
                associate(v=>prog%symbols(s),item=>prog%expressions(a))
                if(v%typ/=ty_character.or.item%character_len/=v%character_len.or.item%scope/=scope) return
                ok=v%is_parameter.and.v%parameter_ready
                if(v%scope==scope.and.v%is_dummy.and..not.v%is_optional) ok=.true.
                if(.not.ok) return
                if(item%kind==ex_variable) then
                    ok=item%rank==v%rank
                else
                    ! LEN reads the element-length descriptor, not array data
                    ! or subscript values. Validate the bounded subscript tree
                    ! nevertheless; an empty array never bypasses IR checks.
                    ok=item%rank==0.and.v%rank>=1.and.v%rank<=3
                    if(.not.ok) return
                    if(.not.valid_automatic_bound(prog,item%left,scope,level+1)) ok=.false.
                    if(v%rank>=2) then
                        if(.not.valid_automatic_bound(prog,item%right,scope,level+1)) ok=.false.
                    else if(item%right/=0) then
                        ok=.false.
                    end if
                    if(v%rank==3) then
                        if(.not.valid_automatic_bound(prog,item%third,scope,level+1)) ok=.false.
                    else if(item%third/=0) then
                        ok=.false.
                    end if
                    if(item%stride/=0.or.item%left2/=0.or.item%right2/=0.or.item%stride2/=0.or. &
                       item%left3/=0.or.item%right3/=0.or.item%stride3/=0) ok=.false.
                end if
                end associate
            else if(e%op=='size'.or.e%op=='lbound'.or.e%op=='ubound') then
                if(size(e%args)<1.or.size(e%args)>3) return
                if(e%op=='size'.and.size(e%args)>2)return
                if(is_bounds_inquiry(e%op))then
                    if(.not.valid_bounds_inquiry(prog,root).or..not.btest(e%intrinsic_mask,1))return
                    if(btest(e%intrinsic_mask,2))then
                        if(.not.bound_constant_expression(prog,e%args(size(e%args)),level+1))return
                    end if
                end if
                a=e%args(1)
                if(a<1.or.a>prog%ne) return
                if(prog%expressions(a)%kind/=ex_variable) return
                s=prog%expressions(a)%symbol
                if(s<1.or.s>prog%ns) return
                associate(v=>prog%symbols(s))
                if(v%rank<1.or.v%rank>3.or.v%is_optional.or.v%is_pointer) return
                ok=v%is_parameter.and.v%parameter_ready
                if(v%scope==scope.and.v%is_dummy) then
                    if(.not.v%is_allocatable) then
                        ok=.true.
                    else
                        ! Descriptor-only inquiries are frozen after association.
                        ! OUT allocatables enter unallocated; OPTIONAL objects do
                        ! not qualify. No array element value is needed here.
                        ok=(v%dummy_intent==1.or.v%dummy_intent==3).and..not.v%is_pointer.and. &
                           .not.v%assumed_shape.and..not.v%is_automatic
                    end if
                end if
                end associate
                if(ok.and.size(e%args)>=2) ok=valid_automatic_bound(prog,e%args(2),scope,level+1)
            else
                if(e%op/='abs'.and.e%op/='min'.and.e%op/='max'.and.e%op/='mod'.and.e%op/='modulo') return
                ok=.true.
                do j=1,size(e%args)
                    if(.not.valid_automatic_bound(prog,e%args(j),scope,level+1)) ok=.false.
                end do
            end if
        end select
        end associate
    end function
    ! Explicit-shape dummy bounds are frozen before any array data is copied.
    ! Restrict dependencies to scalar input dummies and parameters: this avoids
    ! ordering/cycles between descriptors and never reads an OUT array.
    recursive logical function valid_dummy_bound(prog,root,scope,depth) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root,scope
        integer,intent(in),optional::depth
        integer::level,j
        ok=.false.;level=0
        if(present(depth)) level=depth
        if(level>512.or.root<1.or.root>prog%ne) return
        if(.not.valid_automatic_bound(prog,root,scope)) return
        associate(e=>prog%expressions(root))
        select case(e%kind)
        case(ex_literal,ex_variable)
            ok=.true.
        case(ex_unary,ex_binary)
            ok=valid_dummy_bound(prog,e%left,scope,level+1)
            if(ok.and.e%kind==ex_binary) ok=valid_dummy_bound(prog,e%right,scope,level+1)
        case(ex_call)
            if(e%op/='abs'.and.e%op/='min'.and.e%op/='max'.and.e%op/='mod'.and.e%op/='modulo') return
            ok=.true.
            do j=1,size(e%args)
                if(.not.valid_dummy_bound(prog,e%args(j),scope,level+1)) ok=.false.
            end do
        end select
        end associate
    end function
    ! COUNT's KIND is an ordinary constant selector, including KIND inquiries
    ! and parameter expressions. It must never become a runtime dummy value.
    recursive logical function bound_constant_expression(prog,root,depth) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root,depth
        integer::s,j,children(10)
        ok=.false.
        if(depth>512.or.root<1.or.root>prog%ne) return
        associate(e=>prog%expressions(root))
        select case(e%kind)
        case(ex_literal)
            ok=.true.
        case(ex_variable,ex_element,ex_section,ex_substring)
            s=e%symbol
            if(.not.(e%kind==ex_substring.and.s==0)) then
                if(s<1.or.s>prog%ns) return
                if(.not.prog%symbols(s)%is_parameter.or..not.prog%symbols(s)%parameter_ready) return
            end if
            ok=.true.
            if(e%kind==ex_variable) return
            children=[e%left,e%right,e%stride,e%left2,e%right2,e%stride2, &
                        e%left3,e%right3,e%stride3,e%third]
            do j=1,size(children)
                if(children(j)==0) cycle
                if(.not.bound_constant_expression(prog,children(j),depth+1)) ok=.false.
            end do
        case(ex_unary,ex_binary)
            ok=bound_constant_expression(prog,e%left,depth+1)
            if(ok.and.e%kind==ex_binary) ok=bound_constant_expression(prog,e%right,depth+1)
        case(ex_call,ex_constructor)
            if(.not.allocated(e%args)) return
            if(e%kind==ex_call.and.(e%op=='kind'.or.e%op=='new_line'.or.is_numeric_model_inquiry(e%op))) then
                ok=size(e%args)==1
                if(ok) ok=e%args(1)>=1.and.e%args(1)<=prog%ne
                if(ok.and.(e%op=='minexponent'.or.e%op=='maxexponent')) then
                    j=e%args(1)
                    if(prog%expressions(j)%kind/=ex_variable.or.prog%expressions(j)%parenthesized) &
                        ok=bound_constant_expression(prog,j,depth+1)
                end if
                return
            end if
            if(e%kind==ex_call.and.is_bounds_inquiry(e%op))then
                if(.not.valid_bounds_inquiry(prog,root))return
                j=e%args(1)
                if(prog%expressions(j)%kind==ex_variable)then
                    s=prog%expressions(j)%symbol
                    associate(v=>prog%symbols(s))
                    if(.not.v%is_allocatable.and..not.v%is_pointer.and..not.v%assumed_shape.and. &
                       .not.v%is_automatic.and..not.v%is_dummy)then
                        ok=.true.
                        do j=2,size(e%args)
                            if(.not.bound_constant_expression(prog,e%args(j),depth+1))ok=.false.
                        end do
                        return
                    end if
                    end associate
                end if
            end if
            ok=.true.
            do j=1,size(e%args)
                if(.not.bound_constant_expression(prog,e%args(j),depth+1)) ok=.false.
            end do
        end select
        end associate
    end function
    ! COUNT must read its mask, unlike a descriptor-only SIZE inquiry. Admit
    ! only values already associated at entry: constants and nonoptional IN or
    ! INOUT dummies. No local storage, OUT values, user calls or side effects.
    recursive logical function valid_bound_mask_value(prog,root,scope,depth) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::root,scope,depth
        integer::s,j
        ok=.false.
        if(depth>512.or.root<1.or.root>prog%ne) return
        associate(e=>prog%expressions(root))
        if(e%typ/=ty_integer.and.e%typ/=ty_real.and.e%typ/=ty_logical) return
        if(e%rank<0.or.e%rank>2) return
        select case(e%kind)
        case(ex_literal)
            ok=e%rank==0.and.e%value%tag==e%typ
        case(ex_variable)
            s=e%symbol
            if(s<1.or.s>prog%ns) return
            associate(v=>prog%symbols(s))
            if(e%typ/=v%typ.or.e%rank/=v%rank) return
            ok=v%is_parameter.and.v%parameter_ready
            if(v%is_dummy.and.v%scope==scope.and..not.v%is_optional) then
                ok=v%dummy_intent==1.or.v%dummy_intent==3
                if(v%rank>0.and..not.v%assumed_shape) ok=.false.
            end if
            end associate
        case(ex_unary)
            if(e%op/='+'.and.e%op/='-'.and.e%op/='.not.') return
            ok=valid_bound_mask_value(prog,e%left,scope,depth+1)
        case(ex_binary)
            select case(e%op)
            case('+','-','*','/','**','==','/=','<','<=','>','>=', &
                 '.eq.','.ne.','.lt.','.le.','.gt.','.ge.','.and.','.or.','.eqv.','.neqv.')
                ok=valid_bound_mask_value(prog,e%left,scope,depth+1)
                if(ok) ok=valid_bound_mask_value(prog,e%right,scope,depth+1)
            end select
        case(ex_call)
            if(.not.allocated(e%args)) return
            select case(e%op)
            case('size','lbound','ubound','count')
                ok=valid_automatic_bound(prog,root,scope,depth+1)
            case('abs','min','max','mod','modulo','int','real','dble','merge')
                ok=.true.
                do j=1,size(e%args)
                    if(.not.valid_bound_mask_value(prog,e%args(j),scope,depth+1)) ok=.false.
                end do
            end select
        end select
        end associate
    end function
    pure logical function is_derived_type(typ) result(ok)
        integer,intent(in)::typ
        ok=typ>ty_derived_base.and.typ<=ty_derived_base+max_types
    end function
    pure logical function is_logical_reduction(name) result(ok)
        character(*),intent(in)::name
        ok=name=='all'.or.name=='any'.or.name=='count'.or.name=='parity'
    end function
    pure logical function is_array_reduction(name) result(ok)
        character(*),intent(in)::name
        ok=name=='sum'.or.name=='product'.or.name=='minval'.or.name=='maxval'.or.is_logical_reduction(name)
    end function
    pure logical function is_character_search_intrinsic(name) result(ok)
        character(*),intent(in)::name
        ok=name=='index'.or.name=='scan'.or.name=='verify'
    end function
    logical function valid_bit_variable(prog,index) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::index
        integer::s
        ok=.false.
        associate(x=>prog%expressions(index))
        s=x%symbol
        if(.not.allocated(prog%symbols).or.s<1.or.s>prog%ns)return
        if(s>size(prog%symbols))return
        associate(v=>prog%symbols(s))
        if(x%typ/=v%typ.or.x%real_kind/=v%real_kind.or.x%rank/=v%rank.or. &
           x%character_len/=-1.or.x%left/=0.or.x%right/=0.or.x%stride/=0.or. &
           x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or.x%left3/=0.or.x%right3/=0.or. &
           x%stride3/=0.or.x%third/=0.or.x%length_expr/=0.or.x%generic_id/=0.or. &
           x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or. &
           x%constructor_kind_expr/=0.or.x%constructor_owner/=0.or.len_trim(x%op)/=0.or.allocated(x%args).or. &
           any(x%triplet.neqv.[.true.,.false.,.false.]))return
        ok=.true.
        end associate
        end associate
    end function
    pure logical function is_bit_intrinsic(name) result(ok)
        character(*),intent(in)::name
        ok=name=='iand'.or.name=='ior'.or.name=='ieor'.or.name=='not'.or.name=='btest'.or.name=='bit_size'.or.(name=='leadz'.or.name=='trailz').or.name=='maskl'.or.name=='maskr'.or.name=='shiftr'
    end function
    ! Width and elemental shape contract shared by parser-adapted and public IR.
    ! This only examines metadata. In particular BIT_SIZE never reads its I.
    logical function valid_bit_intrinsic(prog,index) result(ok)
        type(program_t),intent(in)::prog
        integer,intent(in)::index
        integer::j,a,n,k,t,r
        integer(int64)::extent,dims(3)
        ok=.false.
        if(.not.allocated(prog%expressions))return
        if(index<1.or.index>prog%ne.or.prog%ne>size(prog%expressions))return
        associate(e=>prog%expressions(index))
        if(e%kind/=ex_call.or..not.is_bit_intrinsic(e%op).or..not.allocated(e%args))return
        n=2
        if(e%op=='not'.or.e%op=='bit_size'.or.(e%op=='leadz'.or.e%op=='trailz'))n=1
        if(e%op=='maskl'.or.e%op=='maskr')then
            n=size(e%args)
            if(n<1.or.n>2)return
        end if
        if(size(e%args)/=n)return
        if(any(e%args<1).or.any(e%args>prog%ne).or.any(e%args==index))return
        if(e%intrinsic_mask/=0.or.e%symbol/=0.or.e%character_len/=-1.or.e%left/=0.or.e%right/=0.or. &
           e%stride/=0.or.e%left2/=0.or.e%right2/=0.or.e%stride2/=0.or.e%left3/=0.or.e%right3/=0.or. &
           e%stride3/=0.or.e%third/=0.or.e%length_expr/=0.or.e%generic_id/=0.or.e%bound_type/=0.or. &
           e%bound_binding/=0.or.e%constructor_kind_expr/=0.or.e%constructor_owner/=0.or. &
           any(e%triplet.neqv.[.true.,.false.,.false.]))return
        k=prog%expressions(e%args(1))%real_kind;t=ty_integer
        if(e%op=='btest')t=ty_logical
        if(e%typ/=t)return
        if(e%op=='maskl'.or.e%op=='maskr')then
            if(e%real_kind/=4.and.e%real_kind/=8)return
            if(n==1.and.e%real_kind/=4)return
        else if(e%op=='btest'.or.(e%op=='leadz'.or.e%op=='trailz'))then
            if(e%real_kind/=4)return
        else
            if(e%real_kind/=k)return
        end if
        r=0;extent=0_int64;dims=0_int64
        do j=1,n
            a=e%args(j)
            associate(x=>prog%expressions(a))
            if(x%typ/=ty_integer.or.(x%real_kind/=4.and.x%real_kind/=8).or. &
               x%rank<0.or.x%rank>3.or.x%character_len/=-1)return
            if(e%op/='btest'.and.e%op/='shiftr'.and.e%op/='maskl'.and.e%op/='maskr'.and.x%real_kind/=k)return
            if((e%op=='maskl'.or.e%op=='maskr').and.j==2.and.x%rank/=0)return
            if(x%extent < -1_int64.or.any(x%dims < -1_int64))return
            if(x%rank<=1.and.any(x%dims/=0))return
            if(x%rank==0.and.x%extent/=0)return
            if(e%op=='bit_size'.or.x%rank==0)cycle
            if(r>0)then
                if(r/=x%rank.or.(extent>=0.and.x%extent>=0.and.extent/=x%extent))return
                if(r>=2)then
                    if(any(dims>=0.and.x%dims>=0.and.dims/=x%dims))return
                    where(dims<0.or.x%dims<0)dims=-1_int64
                end if
                if(extent<0.or.x%extent<0)then
                    extent=-1_int64;cycle
                end if
            end if
            r=x%rank;extent=x%extent;dims=x%dims
            end associate
        end do
        if(e%rank/=r.or.e%extent/=extent.or.any(e%dims/=dims))return
        end associate
        ok=.true.
    end function
    pure logical function is_lexical_intrinsic(name) result(ok)
        character(*),intent(in)::name
        ok=name=='lge'.or.name=='lgt'.or.name=='lle'.or.name=='llt'
    end function
    pure logical function is_character_intrinsic(name) result(ok)
        character(*),intent(in)::name
        ok=is_character_search_intrinsic(name).or.name=='len_trim'.or.name=='adjustl'.or.name=='adjustr'
    end function
    pure logical function is_location_reduction(name) result(ok)
        character(*),intent(in)::name
        ok=name=='minloc'.or.name=='maxloc'.or.name=='findloc'
    end function
    pure logical function is_array_transform(name) result(ok)
        character(*),intent(in)::name
        ok=is_array_reduction(name).or.is_location_reduction(name).or.name=='dot_product'.or.name=='matmul'.or.name=='pack'.or.name=='reshape'.or.name=='shape'.or.name=='cshift'.or.name=='eoshift'.or.name=='transpose'.or.name=='norm2'.or.is_bounds_inquiry(name)
    end function
    subroutine fail(diag, message, line, column, code)
        type(diagnostic_t), intent(inout) :: diag
        character(*), intent(in) :: message
        integer, intent(in), optional :: line, column, code
        if (diag%code /= 0) return
        diag%code=1
        if (present(code)) diag%code=code
        diag%message=message
        if (present(line)) diag%line=line
        if (present(column)) diag%column=column
    end subroutine
    pure function lower(s) result(out)
        character(*), intent(in) :: s
        character(len(s)) :: out
        integer :: i,k
        out=s
        do i=1,len(s)
            k=iachar(s(i:i))
            if (k>=65 .and. k<=90) out(i:i)=achar(k+32)
        end do
    end function
end module
