! SPDX-License-Identifier: MIT
module fi_runtime
    use, intrinsic :: iso_fortran_env, only: int32, int64, real32, real64, output_unit
    use, intrinsic :: ieee_arithmetic, only: ieee_is_finite, ieee_is_nan
    use fi_ir
    use fi_clock, only:clock_sample_t,timing_request_kind,sample_processor_clock,timing_sample_values
    implicit none
    private
    public :: execute_program, evaluate_constant_array, evaluate_constant_shape, evaluate_constant, validate_print_format
    public :: input_unit_t, validate_input_units
    integer, parameter :: max_input_units=32, max_input_bytes=1048576, max_total_input_bytes=4194304
    integer, parameter :: max_input_name=4096
    ! Explicit read-only byte records supplied by the embedding caller. Unit
    ! numbers are virtual: they never designate native Fortran units or stdin.
    type :: input_unit_t
        integer :: unit=0, position=1
        logical :: endfile=.false.
        character(:),allocatable :: data
        ! Caller-supplied connected-file identity only; never opened by the runtime.
        character(:),allocatable :: name
    end type
    integer, parameter :: max_print_values=65536, max_format_operations=262144
    integer, parameter :: max_list_output_characters=16*1024*1024
    integer(int64), parameter :: min64=-huge(0_int64)-1_int64, max64=huge(0_int64)
    integer(int64), parameter :: initial_random_state=104729_int64
    integer(int64), parameter :: imin=-2147483648_int64, imax=2147483647_int64
    type :: format_edit_t
        character(2) :: name=''
        character(32) :: spec=''
        character(:),allocatable :: literal
        integer :: repeat=1, width=0, digits=0, matching=0
        logical :: unlimited=.false.
    end type
    type :: array_storage_t
        ! String-byte charge owned only by CHARACTER gather expression caches.
        integer(int64) :: gather_character_bytes=0_int64
        integer :: character_len=-1
        type(value_t), allocatable :: values(:)
        logical, allocatable :: initialized(:)
        type(value_t), pointer :: data(:)=>null()
        logical, pointer :: flags(:)=>null()
        logical :: borrowed=.false., can_alias=.false.
        integer :: owner_depth=-1, owner_symbol=0, pointer_state=0
        integer(int64) :: owner_generation=0_int64
        integer(int64) :: lower_bound=1_int64, upper_bound=0_int64
        integer(int64) :: lower_bound2=1_int64, upper_bound2=1_int64
        integer(int64) :: lower_bound3=1_int64, upper_bound3=1_int64
    end type
    ! Value-result association rejects overlapping actuals and module data
    ! also referenced through the callee's host/use associations. Flags travel with
    ! values, so OUT invalidation and nested forwarding preserve undefinedness.
    type :: module_store_t
        type(value_t), allocatable :: variables(:)
        type(array_storage_t), allocatable :: arrays(:)
        logical, allocatable :: initialized(:), active(:)
    end type
    type :: variable_ref_t
        type(value_t), pointer :: value=>null()
        type(array_storage_t), pointer :: array=>null()
        logical, pointer :: defined=>null(), active=>null()
    end type
    type :: host_frame_t
        integer :: procedure=0
        type(variable_ref_t),pointer :: refs(:)=>null()
    end type
    type :: pointer_context_t
        character(:),allocatable :: process_name
        logical :: process_name_ready=.false.
        integer :: process_name_status=0
        integer :: output_column=0
        character(:),allocatable :: output_tail ! already-written text right of a pending cursor
        integer(int64) :: generation(0:64)=0_int64
        logical :: live(0:64)=.false.
        type(host_frame_t) :: frames(0:64)
    end type
    type :: argument_t
        logical :: is_pointer=.false., shared_target=.false.
        type(array_storage_t) :: view
        logical :: is_present=.true., is_allocatable=.false., is_allocated=.false., deferred_character=.false.
        integer(int64) :: lower_bounds(3)=1_int64, upper_bounds(3)=0_int64
        integer :: typ=0, real_kind=4, rank=0, character_len=-1
        integer(int64) :: dims(3)=0_int64
        type(value_t), allocatable :: values(:)
        logical, allocatable :: initialized(:)
    end type
    type :: actual_binding_t
        integer :: symbol=0
        integer, allocatable :: offsets(:)
        logical :: writable=.false., allocatable_descriptor=.false., pointer_descriptor=.false., shared_target=.false.
        logical :: gathered_input=.false. ! conservative whole-base alias reservation
    end type
contains
    subroutine validate_input_units(inputs,diag)
        type(input_unit_t),intent(in)::inputs(:)
        type(diagnostic_t),intent(inout)::diag
        integer::j,k
        integer(int64)::total
        if(diag%code/=0) return
        if(size(inputs)>max_input_units) then
            call fail(diag,'external input unit limit exceeded (32)',0,0,2);return
        end if
        total=0
        do j=1,size(inputs)
            if(inputs(j)%unit<=0.or..not.allocated(inputs(j)%data)) then
                call fail(diag,'invalid external input unit binding',0,0,2);return
            end if
            if(allocated(inputs(j)%name))then
                if(len(inputs(j)%name)<1.or.len(inputs(j)%name)>max_input_name)then
                    call fail(diag,'invalid external input name metadata',0,0,2);return
                end if
                if(index(inputs(j)%name,achar(0))/=0)then
                    call fail(diag,'invalid external input name metadata',0,0,2);return
                end if
            end if
            if(len(inputs(j)%data)>max_input_bytes) then
                call fail(diag,'invalid external input size or cursor',0,0,2);return
            end if
            if(inputs(j)%position<1.or.inputs(j)%position>len(inputs(j)%data)+1) then
                call fail(diag,'invalid external input size or cursor',0,0,2);return
            end if
            if(inputs(j)%endfile.and.inputs(j)%position/=len(inputs(j)%data)+1) then
                call fail(diag,'invalid external input endfile state',0,0,2);return
            end if
            if(inputs(j)%position>1.and.inputs(j)%position<=len(inputs(j)%data)) then
                if(inputs(j)%data(inputs(j)%position-1:inputs(j)%position-1)/=achar(10)) then
                    call fail(diag,'external input cursor is not at a record boundary',0,0,2);return
                end if
            end if
            total=total+len(inputs(j)%data,kind=int64)
            if(total>max_total_input_bytes) then
                call fail(diag,'external input total byte limit exceeded (4194304)',0,0,2);return
            end if
            do k=1,j-1
                if(inputs(j)%unit==inputs(k)%unit) then
                    call fail(diag,'duplicate external input unit binding',0,0,2);return
                end if
            end do
        end do
    end subroutine
    subroutine next_internal_input(text,at,repeat_left,token,length_token,is_null,slash,quoted,ios)
        character(*),intent(in)::text
        integer,intent(inout)::at,length_token
        integer(int64),intent(inout)::repeat_left
        character(*),intent(inout)::token
        logical,intent(inout)::is_null,slash,quoted
        integer,intent(out)::ios
        integer::first,q,digit
        integer(int64)::repeat_count
        character::quote,ch
        logical::closed
        ios=0
        if(repeat_left>0) then
            repeat_left=repeat_left-1;return
        end if
        is_null=.false.;quoted=.false.;length_token=0
        call blanks()
        if(at>len(text)) then
            ios=-1;return
        end if
        if(text(at:at)=='/') then
            slash=.true.;return
        end if
        if(text(at:at)==',') then
            at=at+1;is_null=.true.;return
        end if
        ! A repetition prefix consists only of decimal digits followed by '*'.
        ! Quoted separators and stars are ordinary character data.
        first=at;q=at
        do while(q<=len(text))
            if(text(q:q)<'0'.or.text(q:q)>'9') exit
            q=q+1
        end do
        if(q<=len(text).and.q>first) then
            if(text(q:q)=='*') then
                repeat_count=0
                do at=first,q-1
                    digit=iachar(text(at:at))-iachar('0')
                    if(repeat_count>(huge(0_int64)-digit)/10_int64) then
                        ios=1;return
                    end if
                    repeat_count=10_int64*repeat_count+digit
                end do
                if(repeat_count<=0) then
                    ios=1;return
                end if
                repeat_left=repeat_count-1;at=q+1
            end if
        end if
        if(at<=len(text)) then
            quote=text(at:at)
            quoted=quote=="'".or.quote=='"'
            if(quoted) then
                at=at+1;closed=.false.
                do while(at<=len(text))
                    ch=text(at:at);at=at+1
                    if(ch==quote) then
                        if(at<=len(text)) then
                            if(text(at:at)==quote) then
                                at=at+1
                            else
                                closed=.true.;exit
                            end if
                        else
                            closed=.true.;exit
                        end if
                    end if
                    call append(ch)
                    if(ios/=0) return
                end do
                if(.not.closed) then
                    ios=1;return
                end if
                if(at<=len(text)) then
                    if(index(' ,/'//achar(9),text(at:at))==0) then
                        ios=1;return
                    end if
                end if
            else
                do while(at<=len(text))
                    ch=text(at:at)
                    if(index(' ,/'//achar(9),ch)/=0) exit
                    if(ch=="'".or.ch=='"') then
                        ios=1;return
                    end if
                    call append(ch);at=at+1
                    if(ios/=0) return
                end do
            end if
        end if
        is_null=length_token==0.and..not.quoted
        call blanks()
        if(at<=len(text)) then
            if(text(at:at)==',') at=at+1
        end if
    contains
        subroutine append(ch)
            character,intent(in)::ch
            if(length_token>=len(token)) then
                ios=1;return
            end if
            length_token=length_token+1;token(length_token:length_token)=ch
        end subroutine
        subroutine blanks()
            do while(at<=len(text))
                if(text(at:at)/=' '.and.text(at:at)/=achar(9)) exit
                at=at+1
            end do
        end subroutine
    end subroutine
    ! The parser checks syntactic constancy first. Reuse the runtime's bounded
    ! arithmetic evaluator so bounds and initializers cannot bypass its checks.
    subroutine evaluate_constant(prog, index, value, diag, typ, real_kind)
        type(program_t), intent(in) :: prog
        integer, intent(in) :: index
        type(value_t), intent(out) :: value
        type(diagnostic_t), intent(inout) :: diag
        integer, intent(in), optional :: typ, real_kind
        call execute_program(prog,diag,constant_index=index,constant_value=value,constant_type=typ, &
                             constant_real_kind=real_kind)
    end subroutine
    subroutine evaluate_constant_array(prog,index,values,diag,typ,real_kind)
        type(program_t),intent(in)::prog
        integer,intent(in)::index
        type(value_t),allocatable,intent(out)::values(:)
        type(diagnostic_t),intent(inout)::diag
        integer,intent(in),optional::typ,real_kind
        call execute_program(prog,diag,constant_index=index,constant_array=values,constant_type=typ, &
                             constant_real_kind=real_kind)
    end subroutine
    ! Callers must establish syntactic constancy before requesting a shape.
    ! Keep expression metadata conservative: validate and prepare the same bounded
    ! runtime descriptor rather than trusting or fabricating cached dimensions.
    subroutine evaluate_constant_shape(prog,index,dims,diag)
        type(program_t),intent(in)::prog
        integer,intent(in)::index
        integer(int64),intent(out)::dims(3)
        type(diagnostic_t),intent(inout)::diag
        dims=0_int64
        call execute_program(prog,diag,constant_index=index,constant_shape=dims)
    end subroutine
    recursive subroutine execute_program(prog, diag, max_steps, constant_index, constant_value, constant_type, &
                                        procedure_index, argument_values, procedure_value, budget_remaining, call_stack, &
                                        constant_real_kind, argument_bindings, io_in_progress, random_state, constant_array, defined_output, procedure_array, module_store, constant_shape, pointer_context, program_name, input_units)
        type(program_t), intent(in) :: prog
        type(module_store_t), target, intent(inout), optional :: module_store
        type(diagnostic_t), intent(inout) :: diag
        integer(int64), intent(in), optional :: max_steps
        integer, intent(in), optional :: constant_index
        integer, intent(in), optional :: constant_type, constant_real_kind
        type(value_t), intent(out), optional :: constant_value
        type(value_t),allocatable,intent(out),optional::constant_array(:)
        integer(int64),intent(out),optional::constant_shape(3)
        integer, intent(in), optional :: procedure_index, call_stack(:)
        type(value_t), intent(in), optional :: argument_values(:)
        type(argument_t), intent(inout), optional :: argument_bindings(:)
        logical, intent(in), optional :: io_in_progress
        character(:),allocatable,intent(inout),optional::defined_output
        type(value_t), intent(out), optional :: procedure_value
        type(array_storage_t), intent(out), optional :: procedure_array
        integer(int64), target, intent(inout), optional :: budget_remaining, random_state
        type(pointer_context_t), target, optional, intent(inout) :: pointer_context
        character(*),intent(in),optional :: program_name
        type(input_unit_t),intent(inout),optional::input_units(:)
        type(pointer_context_t), target :: owned_context
        type(pointer_context_t), pointer :: context
        integer :: frame_depth,status
        if(diag%code/=0) return
        if(present(input_units)) call validate_input_units(input_units,diag)
        if(diag%code/=0) return
        context=>owned_context
        if(present(pointer_context)) context=>pointer_context
        if(present(program_name)) then
            if(len(program_name)>65536) then
                call fail(diag,'process program name exceeds 65536 characters',0,0,2);return
            end if
            if(allocated(context%process_name)) deallocate(context%process_name)
            allocate(character(len(program_name))::context%process_name,stat=status)
            if(status/=0) then
                call fail(diag,'process program name allocation failed',0,0,2);return
            end if
            context%process_name=program_name;context%process_name_ready=.true.;context%process_name_status=0
        end if
        frame_depth=0
        if(present(procedure_index)) then
            frame_depth=1
            if(present(call_stack)) frame_depth=size(call_stack)+1
        end if
        if(frame_depth>64) then
            call fail(diag,'procedure call depth limit exceeded (64)',0,0,2);return
        end if
        if(context%generation(frame_depth)==huge(0_int64)) then
            call fail(diag,'pointer frame generation limit exceeded',0,0,2);return
        end if
        call check_derived_character_budget(prog,frame_depth,diag,argument_values,argument_bindings)
        if(diag%code/=0) return
        context%generation(frame_depth)=context%generation(frame_depth)+1_int64
        context%live(frame_depth)=.true.
        call execute_frame(prog,diag,max_steps,constant_index,constant_value,constant_type, &
            procedure_index,argument_values,procedure_value,budget_remaining,call_stack, &
            constant_real_kind,argument_bindings,io_in_progress,random_state,constant_array, &
            defined_output,procedure_array,module_store,constant_shape,context,frame_depth,input_units)
        ! Every normal/error RETURN in the executor returns through this wrapper.
        ! Escaped views keep a generation token, never a callee descriptor address.
        context%live(frame_depth)=.false.
        context%frames(frame_depth)%procedure=0
        nullify(context%frames(frame_depth)%refs)
        ! Nonadvancing bytes already written remain unterminated on program
        ! completion or failure, matching the ordinary Fortran output stream.
    end subroutine
    subroutine check_derived_character_budget(prog,depth,diag,argument_values,argument_bindings)
        type(program_t),intent(in)::prog
        integer,intent(in)::depth
        type(diagnostic_t),intent(inout)::diag
        type(value_t),intent(in),optional::argument_values(:)
        type(argument_t),intent(in),optional::argument_bindings(:)
        integer(int64)::type_bytes(max_types),reservation,bytes,limit
        integer::t,j,n,k,edges(12),status
        integer,allocatable::marks(:)
        logical::has_character_components
        ! A conservative admission budget for new record-owned strings only.
        ! Reserve all declared record objects/temporaries in every frame, plus
        ! repeated derived operand edges (not just unique DAG nodes). Eight
        ! slots cover staged record copies; type-default tables reserve two.
        ! Ordinary CHARACTER buffers after extraction keep their existing limits.
        type_bytes=0_int64;reservation=0_int64;has_character_components=.false.
        if(prog%nt<0.or.prog%nt>max_types.or.depth<0.or.depth>64) then
            call fail(diag,'invalid derived CHARACTER budget metadata',0,0,2);return
        end if
        limit=max_derived_character_bytes/int(depth+2,int64)
        do t=1,prog%nt
            n=prog%derived_types(t)%ncomponents
            if(n<0.or.n>16) then
                call fail(diag,'invalid derived CHARACTER budget schema',0,0,2);return
            end if
            do j=1,n
                if(prog%derived_types(t)%component_types(j)/=ty_character)cycle
                has_character_components=.true.
                bytes=int(prog%derived_types(t)%component_lengths(j),int64)
                if(bytes<0.or.bytes>65536_int64) then
                    call fail(diag,'invalid derived CHARACTER budget length',0,0,2);return
                end if
                type_bytes(t)=type_bytes(t)+bytes
            end do
            call reserve(2_int64*type_bytes(t));if(diag%code/=0)return
        end do
        if(.not.has_character_components)return
        if(.not.allocated(prog%symbols).or..not.allocated(prog%expressions)) then
            call fail(diag,'missing derived CHARACTER budget tables',0,0,2);return
        end if
        if(prog%ns<0.or.prog%ns>size(prog%symbols).or.prog%ne<0.or.prog%ne>size(prog%expressions).or. &
           prog%ne>max_expressions.or.prog%ns>max_symbols) then
            call fail(diag,'invalid derived CHARACTER budget table bounds',0,0,2);return
        end if
        allocate(marks(prog%ne),source=0,stat=status)
        if(status/=0) then
            call fail(diag,'derived CHARACTER graph validation allocation failed',0,0,2);return
        end if
        do j=1,prog%ne
            call visit(j,0);if(diag%code/=0)return
        end do
        if(present(argument_values))then
            do j=1,size(argument_values)
                call check_record_payload(argument_values(j));if(diag%code/=0)return
            end do
        end if
        if(present(argument_bindings))then
            do j=1,size(argument_bindings)
                if(.not.allocated(argument_bindings(j)%values))cycle
                do k=1,size(argument_bindings(j)%values)
                    call check_record_payload(argument_bindings(j)%values(k));if(diag%code/=0)return
                end do
            end do
        end if
        do j=1,prog%ns
            call reserve_type(prog%symbols(j)%typ,prog%symbols(j)%rank)
            if(diag%code/=0)return
            if(is_derived_type(prog%symbols(j)%constant_value%tag).or. &
               allocated(prog%symbols(j)%constant_value%record))then
                if(prog%symbols(j)%typ/=prog%symbols(j)%constant_value%tag)then
                    call fail(diag,'derived CHARACTER cache type differs',0,0,2);return
                end if
                call check_record_payload(prog%symbols(j)%constant_value);if(diag%code/=0)return
            end if
            if(allocated(prog%symbols(j)%constant_values))then
                do k=1,size(prog%symbols(j)%constant_values)
                    if(is_derived_type(prog%symbols(j)%constant_values(k)%tag).or. &
                       allocated(prog%symbols(j)%constant_values(k)%record))then
                        if(prog%symbols(j)%typ/=prog%symbols(j)%constant_values(k)%tag)then
                            call fail(diag,'derived CHARACTER array cache type differs',0,0,2);return
                        end if
                        call check_record_payload(prog%symbols(j)%constant_values(k));if(diag%code/=0)return
                    end if
                end do
            end if
        end do
        do j=1,prog%ne
            if(allocated(prog%expressions(j)%value%record).or.is_derived_type(prog%expressions(j)%value%tag))then
                call fail(diag,'derived expression value caches are unsupported',0,0,2);return
            end if
            call reserve_expression(j);if(diag%code/=0)return
            associate(e=>prog%expressions(j))
            edges=[e%left,e%right,e%stride,e%left2,e%right2,e%stride2,e%left3,e%right3,e%stride3, &
                e%third,e%length_expr,e%constructor_kind_expr]
            do k=1,size(edges)
                if(edges(k)==0)cycle
                call reserve_expression(edges(k));if(diag%code/=0)return
            end do
            if(allocated(e%args))then
                do k=1,size(e%args)
                    if(e%args(k)==0)cycle
                    call reserve_expression(e%args(k));if(diag%code/=0)return
                end do
            end if
            end associate
        end do
    contains
        subroutine check_record_payload(value)
            type(value_t),intent(in)::value
            integer::t,j,n
            if(.not.is_derived_type(value%tag))then
                if(allocated(value%record))call fail(diag,'intrinsic value has hidden derived record payload',0,0,2)
                return
            end if
            t=value%tag-ty_derived_base
            if(t<1.or.t>prog%nt.or.value%real_kind/=4.or.allocated(value%s).or. &
               .not.allocated(value%record))then
                call fail(diag,'invalid derived CHARACTER reservation value',0,0,2);return
            end if
            if(.not.allocated(value%record%components).or..not.allocated(value%record%component_defined))then
                call fail(diag,'missing derived CHARACTER reservation fields',0,0,2);return
            end if
            n=prog%derived_types(t)%ncomponents
            if(size(value%record%components)/=n.or.size(value%record%component_defined)/=n)then
                call fail(diag,'derived CHARACTER reservation field count differs',0,0,2);return
            end if
            do j=1,n
                associate(c=>value%record%components(j))
                if(c%tag/=prog%derived_types(t)%component_types(j).or. &
                   c%real_kind/=prog%derived_types(t)%component_kinds(j))then
                    call fail(diag,'derived CHARACTER reservation field schema differs',0,0,2);return
                end if
                if(c%tag==ty_character)then
                    if(allocated(c%s))then
                        if(len(c%s)/=prog%derived_types(t)%component_lengths(j))then
                            call fail(diag,'derived CHARACTER reservation field length differs',0,0,2);return
                        end if
                    else if(value%record%component_defined(j))then
                        call fail(diag,'defined CHARACTER reservation field has no payload',0,0,2);return
                    end if
                else if(allocated(c%s))then
                    call fail(diag,'noncharacter reservation field has string payload',0,0,2);return
                end if
                end associate
            end do
        end subroutine
        recursive subroutine visit(index,depth)
            integer,intent(in)::index,depth
            integer::children(12),k
            if(index<1.or.index>prog%ne)then
                call fail(diag,'invalid derived CHARACTER graph reference',0,0,2);return
            end if
            if(depth>512.or.marks(index)==1)then
                call fail(diag,'cyclic or excessive derived CHARACTER expression structure',0,0,2);return
            end if
            if(marks(index)==2)return
            marks(index)=1
            associate(e=>prog%expressions(index))
            children=[e%left,e%right,e%stride,e%left2,e%right2,e%stride2,e%left3,e%right3,e%stride3, &
                e%third,e%length_expr,e%constructor_kind_expr]
            do k=1,size(children)
                if(children(k)==0)cycle
                call visit(children(k),depth+1);if(diag%code/=0)return
            end do
            if(allocated(e%args))then
                do k=1,size(e%args)
                    if(e%args(k)==0)cycle
                    call visit(e%args(k),depth+1);if(diag%code/=0)return
                end do
            end if
            end associate
            marks(index)=2
        end subroutine
        subroutine reserve_expression(index)
            integer,intent(in)::index
            if(index<1.or.index>prog%ne)then
                call fail(diag,'invalid derived CHARACTER reservation expression',0,0,2);return
            end if
            call reserve_type(prog%expressions(index)%typ,prog%expressions(index)%rank)
        end subroutine
        subroutine reserve_type(typ,rank)
            integer,intent(in)::typ,rank
            integer::t
            if(.not.is_derived_type(typ))return
            t=typ-ty_derived_base
            if(t<1.or.t>prog%nt.or.rank/=0)then
                call fail(diag,'invalid derived CHARACTER reservation payload',0,0,2);return
            end if
            call reserve(8_int64*type_bytes(t))
        end subroutine
        subroutine reserve(amount)
            integer(int64),intent(in)::amount
            if(amount<0.or.amount>limit-reservation)then
                call fail(diag,'derived CHARACTER storage reservation limit exceeded; adjust max_derived_character_bytes',0,0,2)
                return
            end if
            reservation=reservation+amount
        end subroutine
    end subroutine
    recursive subroutine execute_frame(prog, diag, max_steps, constant_index, constant_value, constant_type, &
                                        procedure_index, argument_values, procedure_value, budget_remaining, call_stack, &
                                        constant_real_kind, argument_bindings, io_in_progress, random_state, constant_array, defined_output, procedure_array, module_store, constant_shape, context, frame_depth, input_units)
        type(program_t), intent(in) :: prog
        type(module_store_t), target, intent(inout), optional :: module_store
        type(module_store_t), target :: owned_modules
        type(module_store_t), pointer :: modules
        type(variable_ref_t), allocatable, target :: refs(:)
        type(diagnostic_t), intent(inout) :: diag
        integer(int64), intent(in), optional :: max_steps
        integer, intent(in), optional :: constant_index
        integer, intent(in), optional :: constant_type, constant_real_kind
        type(value_t), intent(out), optional :: constant_value
        type(value_t),allocatable,intent(out),optional::constant_array(:)
        integer(int64),intent(out),optional::constant_shape(3)
        integer, intent(in), optional :: procedure_index, call_stack(:)
        type(value_t), intent(in), optional :: argument_values(:)
        type(argument_t), intent(inout), optional :: argument_bindings(:)
        logical, intent(in), optional :: io_in_progress
        character(:),allocatable,intent(inout),optional::defined_output
        type(pointer_context_t), intent(inout) :: context
        integer,intent(in) :: frame_depth
        type(input_unit_t),intent(inout),optional::input_units(:)
        logical :: in_output
        type(value_t), intent(out), optional :: procedure_value
        type(array_storage_t), intent(out), optional :: procedure_array
        integer(int64), target, intent(inout), optional :: budget_remaining
        integer(int64), target, intent(inout), optional :: random_state
        integer(int64), target :: local_random_state
        integer(int64), pointer :: rng
        integer(int64), target :: local_budget
        integer(int64), pointer :: budget
        integer, allocatable :: stack(:)
        integer :: constructor_level, constructor_owners(max_constructor_do_depth)
        integer(int64) :: constructor_values(max_constructor_do_depth)
        integer :: constructor_expansions, constructor_materializations
        integer :: scope, first_pc, last_pc, result_symbol, host_scope, host_depth
        type(value_t), allocatable, target :: variables(:)
        type(value_t), allocatable :: printed(:), assigned(:)
        type(array_storage_t), allocatable, target :: arrays(:)
        type(array_storage_t), allocatable :: expression_cache(:)
        logical, allocatable, target :: initialized(:), active_variable(:)
        logical, allocatable :: active(:), dummy_present(:), captured(:)
        integer(int64), allocatable :: loop_last(:), increments(:)
        integer, allocatable :: shape_state(:), reduction_dim(:), empty_trig_marks(:)
        integer(int64), allocatable :: shape_extent(:), shape_dims(:,:), section_start(:,:), section_step(:,:), section_count(:,:)
        integer(int64) :: first, last, stride, next_value
        integer :: pc, j, k, loop_pc, sym, offset, ios, target_rank, selected,arm,default_arm,list_length,output_cursor
        logical::matches,match_bound
        integer(int64) :: extent, total_elements, target_dims(3), dims(3), cached_elements, cached_gather_character_bytes
        type(value_t) :: a, b, c, converted
        type(component_value_t)::component_defaults(16,max_types),component_assignment
        character(:), allocatable :: line,defined_text,active_format
        character(80) :: buffer
        if (diag%code /= 0) return
        constructor_level=0;constructor_owners=0;constructor_values=0_int64
        constructor_expansions=0;constructor_materializations=0
        in_output=.false.
        if(present(io_in_progress)) in_output=io_in_progress
        if(prog%ns<0.or.prog%ns>max_symbols.or.prog%ne<0.or.prog%ne>max_expressions.or. &
           prog%nc<0.or.prog%nc>max_instructions.or.prog%np<0.or.prog%np>max_procedures.or. &
           prog%nt<0.or.prog%nt>max_types.or.prog%nm<0.or.prog%nm>max_modules) then
            call runtime_error('invalid runtime IR counts',0,0); return
        end if
        if(.not.allocated(prog%symbols).or..not.allocated(prog%expressions).or..not.allocated(prog%code)) then
            call runtime_error('missing runtime IR storage',0,0); return
        end if
        if(size(prog%symbols)<prog%ns.or.size(prog%expressions)<prog%ne.or.size(prog%code)<prog%nc) then
            call runtime_error('insufficient runtime IR storage',0,0); return
        end if
        if(prog%np>0) then
            if(.not.allocated(prog%procedures)) then
                call runtime_error('missing function storage',0,0); return
            end if
            if(size(prog%procedures)<prog%np) then
                call runtime_error('insufficient function storage',0,0); return
            end if
        end if
        if(.not.present(constant_index)) then
            do j=1,prog%np
                if(.not.valid_internal_procedure(prog,j)) then
                    call runtime_error('invalid internal procedure host metadata',0,0);return
                end if
            end do
        end if
        local_random_state=initial_random_state
        rng=>local_random_state
        if(present(random_state)) rng=>random_state
        if(rng<1_int64.or.rng>=2147483647_int64) then
            call runtime_error('invalid random generator state',0,0); return
        end if
        local_budget=1000000_int64
        if (present(max_steps)) local_budget=max_steps
        budget=>local_budget
        if (present(budget_remaining)) budget=>budget_remaining
        scope=0; first_pc=prog%entry_pc; last_pc=prog%nc
        allocate(stack(0))
        if(present(call_stack)) stack=call_stack
        if(present(procedure_index)) then
            scope=procedure_index
            if(scope<1.or.scope>prog%np.or..not.allocated(prog%procedures)) then
                call runtime_error('invalid function reference',0,0); return
            end if
            if(size(stack)>=64) then
                call runtime_error('procedure call depth limit exceeded (64)',0,0); return
            end if
            if(prog%procedures(scope)%is_recursive.and.prog%procedures(scope)%is_elemental) then
                call runtime_error('RECURSIVE ELEMENTAL procedures are unsupported',0,0);return
            end if
            if(any(stack==scope).and..not.prog%procedures(scope)%is_recursive) then
                call runtime_error('recursive invocation requires RECURSIVE',0,0);return
            end if
            stack=[stack,scope]
            first_pc=prog%procedures(scope)%first; last_pc=prog%procedures(scope)%last
            if(.not.present(argument_values).and..not.present(argument_bindings)) then
                call runtime_error('procedure invocation requires arguments',0,0); return
            end if
            if(.not.prog%procedures(scope)%is_subroutine.and. &
               .not.present(procedure_value).and..not.present(procedure_array)) then
                call runtime_error('function invocation requires a result',0,0); return
            end if
            if(.not.allocated(prog%procedures(scope)%args)) then
                call runtime_error('function dummy list is absent',0,0); return
            end if
            if(present(argument_bindings)) then
                if(size(argument_bindings)/=size(prog%procedures(scope)%args)) then
                    call runtime_error('procedure argument count mismatch',0,0); return
                end if
            else
                if(size(argument_values)/=size(prog%procedures(scope)%args)) then
                    call runtime_error('function argument count mismatch',0,0); return
                end if
            end if
        end if
        host_scope=0;host_depth=-1
        if(scope>0) host_scope=prog%procedures(scope)%parent_procedure
        if(host_scope>0) then
            if(size(stack)<2) then
                call runtime_error('internal procedure requires an active host',0,0);return
            end if
            if(.not.internal_call_visible(prog,stack(size(stack)-1),scope)) then
                call runtime_error('internal call outside its lexical host',0,0);return
            end if
            do j=frame_depth-1,1,-1
                if(.not.context%live(j).or.context%frames(j)%procedure/=host_scope) cycle
                if(.not.associated(context%frames(j)%refs)) cycle
                host_depth=j;exit
            end do
            if(host_depth<0) then
                call runtime_error('internal procedure host activation is unavailable',0,0);return
            end if
        end if
        if(first_pc<1.or.last_pc>prog%nc.or.last_pc<first_pc-1) then
            call runtime_error('invalid instruction interval',0,0); return
        end if
        allocate(variables(prog%ns), initialized(prog%ns), active_variable(prog%ns), active(prog%nc), &
                 loop_last(prog%nc), increments(prog%nc))
        allocate(shape_state(prog%ne),reduction_dim(prog%ne),source=0)
        allocate(shape_dims(3,prog%ne),shape_extent(prog%ne),section_start(3,prog%ne),section_step(3,prog%ne),section_count(3,prog%ne))
        shape_dims=0_int64; shape_extent=0_int64; section_start=0_int64; section_step=1_int64; section_count=1_int64
        allocate(dummy_present(prog%ns),source=.true.)
        allocate(captured(prog%ns),source=.false.)
        allocate(arrays(prog%ns),expression_cache(prog%ne),refs(prog%ns))
        modules=>owned_modules
        if(present(module_store)) modules=>module_store
        if(.not.allocated(modules%variables)) then
            allocate(modules%variables(prog%ns),modules%arrays(prog%ns))
            allocate(modules%initialized(prog%ns),modules%active(prog%ns),source=.false.)
        end if
        do sym=1,prog%ns
            if(prog%symbols(sym)%is_intrinsic.or.len_trim(prog%symbols(sym)%intrinsic_import)>0) then
                if(.not.valid_intrinsic_import(prog%symbols(sym)).or. &
                   prog%symbols(sym)%scope < -prog%nm.or.prog%symbols(sym)%scope > prog%np) then
                    call runtime_error('invalid ISO_FORTRAN_ENV import metadata', &
                        prog%symbols(sym)%line,prog%symbols(sym)%column);return
                end if
            end if
            if(prog%symbols(sym)%is_saved) then
                if(.not.valid_saved_local(prog,sym)) then
                    call runtime_error('invalid initialized SAVE local',prog%symbols(sym)%line,prog%symbols(sym)%column);return
                end if
            else if(.not.present(constant_index).and.prog%symbols(sym)%scope>0.and..not.prog%symbols(sym)%is_parameter.and. &
                    prog%symbols(sym)%initializer_expr/=0) then
                call runtime_error('procedure initializer requires SAVE storage',prog%symbols(sym)%line,prog%symbols(sym)%column);return
            end if
            if(prog%symbols(sym)%is_pointer) then
                associate(v=>prog%symbols(sym))
                if(v%rank/=1.or.(v%typ/=ty_integer.and.v%typ/=ty_real).or. &
                   (v%real_kind/=4.and.v%real_kind/=8).or.v%scope<0.or.v%scope>prog%np.or.v%is_allocatable.or. &
                   v%is_target.or.v%is_parameter.or.v%is_automatic.or.v%assumed_shape.or.v%is_class.or. &
                   v%is_intrinsic.or.v%deferred_character.or.v%character_len/=-1.or.v%length_expr/=0.or. &
                   v%parameter_ready.or.allocated(v%constant_values).or. &
                   v%lower_bound2/=1.or.v%upper_bound2/=1.or.v%lower_bound3/=1.or.v%upper_bound3/=1.or. &
                   v%initializer_expr/=0.or.v%lower_bound/=1.or.v%upper_bound/=0.or. &
                   v%lower_expr/=0.or.v%upper_expr/=0.or.v%lower_expr2/=0.or.v%upper_expr2/=0.or. &
                   v%lower_expr3/=0.or.v%upper_expr3/=0) then
                    call runtime_error('invalid bounded POINTER declaration',v%line,v%column);return
                end if
                if(v%is_dummy) then
                    if(v%scope==0.or.v%dummy_intent<1.or.v%dummy_intent>3) then
                        call runtime_error('invalid POINTER dummy declaration',v%line,v%column);return
                    end if
                else if(v%dummy_intent/=0.or.v%is_optional) then
                    call runtime_error('invalid local POINTER declaration',v%line,v%column);return
                end if
                if(v%scope>0) then
                    if(.not.prog%procedures(v%scope)%is_subroutine.or.prog%procedures(v%scope)%is_elemental) then
                        call runtime_error('POINTER declarations in functions or ELEMENTAL procedures are unsupported',v%line,v%column);return
                    end if
                end if
                end associate
            end if
            if(prog%symbols(sym)%is_target) then
                associate(v=>prog%symbols(sym))
                if(v%is_parameter.or.v%is_class.or.v%is_intrinsic.or. &
                   v%typ<ty_integer.or.v%typ>ty_character.or.v%rank<0.or.v%rank>3) then
                    call runtime_error('invalid TARGET declaration',v%line,v%column);return
                end if
                end associate
            end if
            if(.not.present(constant_index).and.prog%symbols(sym)%typ==ty_character.and. &
               prog%symbols(sym)%is_dummy.and.prog%symbols(sym)%length_expr/=0) then
                if(prog%symbols(sym)%character_len<0) then
                    if(.not.valid_character_length_dummy(prog,sym)) then
                        call runtime_error('invalid specification-length ALLOCATABLE CHARACTER dummy', &
                            prog%symbols(sym)%line,prog%symbols(sym)%column);return
                    end if
                else
                    ! A forged positive cache must not hide a dynamic length.
                    ! Fixed lengths are independently rechecked as constants;
                    ! inquiry metadata can be constant without reading data.
                    block
                        type(diagnostic_t)::length_diag
                        call evaluate_constant(prog,prog%symbols(sym)%length_expr,a,length_diag)
                        if(length_diag%code/=0) then
                            call runtime_error('invalid constant CHARACTER dummy length cache', &
                                prog%symbols(sym)%line,prog%symbols(sym)%column);return
                        end if
                    end block
                    if(a%tag/=ty_integer.or.max(0_int64,a%i)/=int(prog%symbols(sym)%character_len,int64)) then
                        call runtime_error('constant CHARACTER dummy length cache differs', &
                            prog%symbols(sym)%line,prog%symbols(sym)%column);return
                    end if
                end if
            end if
            if(prog%symbols(sym)%is_allocatable) then
                if(prog%symbols(sym)%rank==0) then
                    if(.not.valid_scalar_character_allocatable(prog,sym)) then
                        call runtime_error('invalid scalar ALLOCATABLE CHARACTER declaration', &
                            prog%symbols(sym)%line,prog%symbols(sym)%column);return
                    end if
                end if
                associate(v=>prog%symbols(sym))
                if(v%deferred_character.and.(v%typ/=ty_character.or.v%character_len/=-1.or.v%length_expr/=0)) then
                    call runtime_error('invalid deferred CHARACTER declaration',v%line,v%column);return
                end if
                if(v%rank<0.or.v%rank>3.or.(v%rank==0.and.v%typ/=ty_character).or. &
                   v%is_parameter.or.v%assumed_shape.or.v%is_automatic.or. &
                   v%initializer_expr/=0.or.(v%typ/=ty_integer.and.v%typ/=ty_real.and. &
                    v%typ/=ty_logical.and.v%typ/=ty_character).or. &
                   (v%typ==ty_logical.and.v%real_kind/=4).or. &
                   v%lower_expr/=0.or.v%upper_expr/=0.or.v%lower_expr2/=0.or.v%upper_expr2/=0.or. &
                   v%lower_expr3/=0.or.v%upper_expr3/=0.or. &
                   v%lower_bound/=1.or.v%upper_bound/=merge(1,0,v%rank==0)) then
                    call runtime_error('invalid ALLOCATABLE declaration',v%line,v%column);return
                end if
                if(v%rank==0.and.(v%lower_bound2/=1.or.v%upper_bound2/=1.or. &
                   v%lower_bound3/=1.or.v%upper_bound3/=1.or.v%real_kind/=4.or.v%is_class.or. &
                   v%is_pointer.or.v%is_saved.or.v%is_intrinsic.or.v%kind_expr/=0)) then
                    call runtime_error('invalid scalar ALLOCATABLE CHARACTER declaration',v%line,v%column);return
                end if
                if(v%rank>=2.and.(v%lower_bound2/=1.or.v%upper_bound2/=0)) then
                    call runtime_error('invalid ALLOCATABLE second dimension',v%line,v%column);return
                end if
                if(v%rank==3.and.(v%lower_bound3/=1.or.v%upper_bound3/=0)) then
                    call runtime_error('invalid ALLOCATABLE third dimension',v%line,v%column);return
                end if
                end associate
            end if
            refs(sym)%value=>variables(sym);refs(sym)%array=>arrays(sym)
            if(prog%symbols(sym)%is_pointer) refs(sym)%array%borrowed=.true.
            refs(sym)%defined=>initialized(sym);refs(sym)%active=>active_variable(sym)
            if((prog%symbols(sym)%scope<0.or.prog%symbols(sym)%is_saved).and..not.prog%symbols(sym)%is_parameter) then
                refs(sym)%value=>modules%variables(sym);refs(sym)%array=>modules%arrays(sym)
                refs(sym)%defined=>modules%initialized(sym);refs(sym)%active=>modules%active(sym)
            end if
        end do
        if(host_depth>=0) then
            do sym=1,prog%ns
                if(.not.host_symbol_visible(prog,sym,scope).or.prog%symbols(sym)%is_parameter) cycle
                refs(sym)=context%frames(host_depth)%refs(sym)
                captured(sym)=.true.
            end do
        end if
        context%frames(frame_depth)%procedure=scope
        context%frames(frame_depth)%refs=>refs
        initialized=.false.
        do sym=1,prog%ns
            if(captured(sym)) cycle
            if((prog%symbols(sym)%scope<0.or.prog%symbols(sym)%is_saved).and.present(module_store)) cycle
            if(prog%symbols(sym)%scope==scope) then
                if(.not.valid_optional_declaration(sym)) return
            end if
            if(prog%symbols(sym)%typ/=ty_character.or.prog%symbols(sym)%character_len<0) cycle
            if(prog%symbols(sym)%character_len>65536) then
                call runtime_error('CHARACTER length limit exceeded',0,0);return
            end if
            refs(sym)%value%tag=ty_character
            refs(sym)%value%s=repeat(' ',prog%symbols(sym)%character_len)
        end do
        active_variable=.false.
        active=.false.
        loop_last=0_int64
        increments=0_int64
        cached_elements=0_int64;cached_gather_character_bytes=0_int64
        do sym=1,prog%ns
            if(captured(sym)) cycle
            if((prog%symbols(sym)%scope<0.or.prog%symbols(sym)%is_saved).and.present(module_store).and. &
               .not.prog%symbols(sym)%is_parameter) cycle
            refs(sym)%array%lower_bound=prog%symbols(sym)%lower_bound
            refs(sym)%array%upper_bound=prog%symbols(sym)%upper_bound
            refs(sym)%array%lower_bound2=prog%symbols(sym)%lower_bound2
            refs(sym)%array%lower_bound3=prog%symbols(sym)%lower_bound3
            refs(sym)%array%upper_bound2=prog%symbols(sym)%upper_bound2
            refs(sym)%array%upper_bound3=prog%symbols(sym)%upper_bound3
        end do
        do k=1,prog%nt
            if(prog%derived_types(k)%ncomponents<0.or.prog%derived_types(k)%ncomponents>16) then
                call runtime_error('invalid derived component count',0,0);return
            end if
            if(prog%derived_types(k)%ncomponents==0.and..not.present(constant_index)) then
                call runtime_error('invalid derived component count',0,0);return
            end if
            if(.not.any(prog%derived_types(k)%component_initializers/=0).and. &
               .not.any(prog%derived_types(k)%component_types==ty_character).and. &
               .not.any(prog%derived_types(k)%component_lengths/=-1).and. &
               .not.any(prog%derived_types(k)%component_length_exprs/=0)) cycle
            if(.not.valid_component_defaults(prog,k)) then
                call runtime_error('invalid derived component default metadata',0,0);return
            end if
        end do
        if(.not.present(constant_index)) then
            call prepare_component_defaults()
            if(diag%code/=0) return
        end if
        if (present(constant_index)) then
            if(present(constant_shape)) then
                if(.not.valid_expression(constant_index)) return
                if(prog%expressions(constant_index)%rank<1.or.prog%expressions(constant_index)%rank>3) then
                    call runtime_error('constant shape evaluation requires rank-one/two/three array',0,0);return
                end if
                call prepare_expression(constant_index,0)
                if(diag%code==0) constant_shape=shape_dims(:,constant_index)
                return
            end if
            if(present(constant_array)) then
                if(.not.valid_expression(constant_index)) return
                call prepare_expression(constant_index,0)
                if(diag%code/=0) return
                if(prog%expressions(constant_index)%rank==0) then
                    call runtime_error('array constant evaluation requires array expression',0,0);return
                end if
                extent=shape_extent(constant_index)
                allocate(constant_array(int(extent)))
                do j=1,int(extent)
                    a=evaluate(constant_index,0,j)
                    if(diag%code/=0) return
                    if(present(constant_type)) a=convert(a,constant_type, &
                        prog%expressions(constant_index)%line,prog%expressions(constant_index)%column,constant_real_kind)
                    constant_array(j)=a
                end do
                return
            end if
            if (.not.present(constant_value)) then
                call runtime_error('constant evaluation requires a result',0,0)
                return
            end if
            constant_value=evaluate(constant_index,0)
            if(diag%code==0.and.present(constant_type)) then
                converted=convert(constant_value,constant_type, &
                    prog%expressions(constant_index)%line,prog%expressions(constant_index)%column,constant_real_kind)
                constant_value=converted
            end if
            return
        end if
        total_elements=0_int64
        if(.not.present(module_store)) then
            do sym=1,prog%ns
                if((prog%symbols(sym)%scope>=0.and..not.prog%symbols(sym)%is_saved).or.prog%symbols(sym)%is_parameter) cycle
                if(prog%symbols(sym)%is_saved) then
                    call check_saved_initializer(sym)
                    if(diag%code/=0) return
                end if
                if(prog%symbols(sym)%rank>0) then
                    call allocate_frame_array(sym)
                    if(diag%code/=0) return
                end if
                if(prog%symbols(sym)%initializer_expr==0) cycle
                if(.not.prog%symbols(sym)%parameter_ready) then
                    call runtime_error('module initializer cache missing',0,0);return
                end if
                if(prog%symbols(sym)%rank==0) then
                    refs(sym)%value=prog%symbols(sym)%constant_value;refs(sym)%defined=.true.
                else
                    if(.not.allocated(prog%symbols(sym)%constant_values)) then
                        call runtime_error('module array initializer cache missing',0,0);return
                    end if
                    if(size(prog%symbols(sym)%constant_values)/=size(refs(sym)%array%data)) then
                        call runtime_error('module array initializer shape differs',0,0);return
                    end if
                    refs(sym)%array%data=prog%symbols(sym)%constant_values
                    refs(sym)%array%flags=.true.
                end if
            end do
        end if
        total_elements=0_int64
        do sym=1,prog%ns
            if(captured(sym)) cycle
            if((prog%symbols(sym)%scope<0.or.prog%symbols(sym)%is_saved).and.present(module_store).and. &
               .not.prog%symbols(sym)%is_parameter) cycle
            refs(sym)%array%lower_bound=prog%symbols(sym)%lower_bound
            refs(sym)%array%upper_bound=prog%symbols(sym)%upper_bound
            refs(sym)%array%lower_bound2=prog%symbols(sym)%lower_bound2
            refs(sym)%array%lower_bound3=prog%symbols(sym)%lower_bound3
            refs(sym)%array%upper_bound2=prog%symbols(sym)%upper_bound2
            refs(sym)%array%upper_bound3=prog%symbols(sym)%upper_bound3
        end do
        do sym=1,prog%ns
            if(prog%symbols(sym)%scope/=scope.or..not.is_derived_type(prog%symbols(sym)%typ)) cycle
            call initialize_record(refs(sym)%value,prog%symbols(sym)%typ)
            if(diag%code/=0) return
            refs(sym)%defined=.true.
        end do
        if(scope/=0) then
            do j=1,size(prog%procedures(scope)%args)
                sym=prog%procedures(scope)%args(j)
                if(.not.valid_symbol(sym,.true.)) return
                if(.not.prog%symbols(sym)%is_dummy) then
                    call runtime_error('invalid dummy argument',0,0); return
                end if
                if(present(argument_bindings)) then
                    if(.not.argument_bindings(j)%is_present) then
                        if(.not.prog%symbols(sym)%is_optional) then
                            call runtime_error('missing required actual argument',0,0);return
                        end if
                        dummy_present(sym)=.false.
                        cycle
                    end if
                    if(argument_bindings(j)%is_allocatable.neqv.prog%symbols(sym)%is_allocatable) then
                        call runtime_error('allocatable argument descriptor mismatch',0,0);return
                    end if
                    if(argument_bindings(j)%rank/=prog%symbols(sym)%rank.or. &
                       argument_bindings(j)%typ/=prog%symbols(sym)%typ.or. &
                       .not.allocated(argument_bindings(j)%values).or. &
                       .not.allocated(argument_bindings(j)%initialized)) then
                        call runtime_error('procedure argument type or rank mismatch',0,0); return
                    end if
                    if((argument_bindings(j)%typ>=ty_integer.and.argument_bindings(j)%typ<=ty_logical).and. &
                       argument_bindings(j)%real_kind/=prog%symbols(sym)%real_kind) then
                        call runtime_error('procedure REAL argument kind mismatch',0,0); return
                    end if
                    if(argument_bindings(j)%is_pointer.neqv.prog%symbols(sym)%is_pointer) then
                        call runtime_error('POINTER argument descriptor mismatch',0,0);return
                    end if
                    if(argument_bindings(j)%is_pointer) then
                        if(.not.prog%procedures(scope)%is_subroutine.or. &
                           size(argument_bindings(j)%values)/=0.or.size(argument_bindings(j)%initialized)/=0) then
                            call runtime_error('invalid POINTER argument payload',0,0);return
                        end if
                        if(prog%symbols(sym)%dummy_intent==2) then
                            refs(sym)%array%borrowed=.true.;refs(sym)%array%pointer_state=0
                        else
                            call copy_alias_view(refs(sym)%array,argument_bindings(j)%view,0,0)
                            if(diag%code/=0) return
                        end if
                        cycle
                    end if
                    if(argument_bindings(j)%shared_target) then
                        if(.not.prog%symbols(sym)%is_target.or..not.prog%symbols(sym)%assumed_shape.or. &
                           prog%symbols(sym)%is_allocatable.or.prog%symbols(sym)%rank>2.or. &
                           (prog%symbols(sym)%typ/=ty_integer.and.prog%symbols(sym)%typ/=ty_real)) then
                            call runtime_error('invalid shared TARGET dummy',0,0);return
                        end if
                        call copy_alias_view(refs(sym)%array,argument_bindings(j)%view,0,0)
                        if(diag%code/=0) return
                        if(.not.refs(sym)%array%can_alias) then
                            call runtime_error('shared TARGET has no caller backing',0,0);return
                        end if
                        dims=argument_bindings(j)%dims
                        if(any(dims<0).or.any(dims>imax).or.shape_size(dims)/=size(refs(sym)%array%data,kind=int64)) then
                            call runtime_error('shared TARGET shape differs from backing',0,0);return
                        end if
                        do k=1,size(refs(sym)%array%data)
                            if(.not.refs(sym)%array%flags(k)) cycle
                            if(refs(sym)%array%data(k)%tag/=prog%symbols(sym)%typ.or. &
                               refs(sym)%array%data(k)%real_kind/=prog%symbols(sym)%real_kind) then
                                call runtime_error('shared TARGET backing type or kind differs',0,0);return
                            end if
                        end do
                        refs(sym)%array%lower_bound=prog%symbols(sym)%lower_bound
                        refs(sym)%array%upper_bound=refs(sym)%array%lower_bound+dims(1)-1_int64
                        refs(sym)%array%lower_bound2=prog%symbols(sym)%lower_bound2
                        refs(sym)%array%upper_bound2=refs(sym)%array%lower_bound2+dims(2)-1_int64
                        refs(sym)%array%lower_bound3=1;refs(sym)%array%upper_bound3=1
                        if(prog%symbols(sym)%dummy_intent==2) refs(sym)%array%flags=.false.
                        cycle
                    end if
                    extent=size(argument_bindings(j)%values,kind=int64)
                    if(size(argument_bindings(j)%initialized,kind=int64)/=extent.or.extent>max_array_elements) then
                        call runtime_error('invalid argument storage',0,0); return
                    end if
                    do k=1,int(extent)
                        if(.not.argument_bindings(j)%initialized(k)) cycle
                        if(argument_bindings(j)%values(k)%tag/=prog%symbols(sym)%typ) then
                            call runtime_error('procedure argument value type mismatch',0,0); return
                        end if
                        if((prog%symbols(sym)%typ>=ty_integer.and.prog%symbols(sym)%typ<=ty_logical).and. &
                           argument_bindings(j)%values(k)%real_kind/=prog%symbols(sym)%real_kind) then
                            call runtime_error('procedure REAL argument kind mismatch',0,0); return
                        end if
                        if(prog%symbols(sym)%typ==ty_character.and. &
                           .not.allocated(argument_bindings(j)%values(k)%s)) then
                            call runtime_error('invalid CHARACTER argument',0,0); return
                        end if
                        if(prog%symbols(sym)%typ==ty_character) then
                            if(len(argument_bindings(j)%values(k)%s)/=argument_bindings(j)%character_len) then
                                call runtime_error('CHARACTER argument element length differs',0,0);return
                            end if
                        end if
                    end do
                    if(prog%symbols(sym)%typ==ty_character) then
                        k=argument_bindings(j)%character_len
                        if(argument_bindings(j)%deferred_character.neqv.prog%symbols(sym)%deferred_character) then
                            call runtime_error('CHARACTER argument deferred length differs',0,0);return
                        end if
                        if(k==-1.and.prog%symbols(sym)%deferred_character.and..not.argument_bindings(j)%is_allocated) then
                            ! Unallocated deferred objects have no defined length parameter.
                        else if(k<0.or.k>65536) then
                            call runtime_error('invalid CHARACTER argument length descriptor',0,0);return
                        end if
                        if(prog%symbols(sym)%character_len>=0) then
                            if((prog%symbols(sym)%rank>0.or.prog%symbols(sym)%is_allocatable).and.k/=prog%symbols(sym)%character_len) then
                                call runtime_error('CHARACTER array actual length must match fixed-length dummy',0,0);return
                            end if
                            if(k<prog%symbols(sym)%character_len) then
                                call runtime_error('CHARACTER actual shorter than fixed-length dummy',0,0);return
                            end if
                            if(prog%symbols(sym)%dummy_intent>=2.and.k/=prog%symbols(sym)%character_len) then
                                call runtime_error('fixed-length writable CHARACTER requires equal actual length',0,0);return
                            end if
                            k=prog%symbols(sym)%character_len
                        end if
                        refs(sym)%value%tag=ty_character
                        if(k>=0) refs(sym)%value%s=repeat(' ',k)
                        refs(sym)%array%character_len=k
                    end if
                    if(prog%symbols(sym)%is_allocatable) then
                        if(.not.argument_bindings(j)%is_allocated) then
                            if(extent/=0) then
                                call runtime_error('unallocated argument contains storage',0,0);return
                            end if
                            cycle
                        end if
                        if(prog%symbols(sym)%dummy_intent==2) then
                            call runtime_error('allocatable INTENT(OUT) must enter unallocated',0,0);return
                        end if
                        dims=max(0_int64,argument_bindings(j)%upper_bounds-argument_bindings(j)%lower_bounds+1_int64)
                        if(any(argument_bindings(j)%lower_bounds<imin).or.any(argument_bindings(j)%lower_bounds>imax).or. &
                           any(argument_bindings(j)%upper_bounds<imin).or.any(argument_bindings(j)%upper_bounds>imax).or. &
                           any(dims>imax)) then
                            call runtime_error('allocatable argument bounds exceed supported range',0,0);return
                        end if
                        dims(prog%symbols(sym)%rank+1:)=1_int64
                        if(shape_size(dims)/=extent.or.any(dims/=argument_bindings(j)%dims)) then
                            call runtime_error('allocatable argument shape differs from storage',0,0);return
                        end if
                        total_elements=total_elements+extent
                        if(total_elements>max_array_elements) then
                            call runtime_error('total array element limit exceeded',0,0);return
                        end if
                        if(prog%symbols(sym)%typ==ty_character) then
                            if(.not.character_storage_fits(sym,extent,argument_bindings(j)%character_len)) then
                                call runtime_error('CHARACTER allocation byte limit exceeded at argument entry (16777216)',0,0);return
                            end if
                        end if
                        allocate(refs(sym)%array%values(int(extent)),refs(sym)%array%initialized(int(extent)),stat=ios)
                        if(ios/=0) then
                            call runtime_error('allocatable dummy storage allocation failed',0,0);return
                        end if
                        call bind_owned_storage(sym)
                        refs(sym)%array%data=argument_bindings(j)%values
                        refs(sym)%array%flags=argument_bindings(j)%initialized
                        if(prog%symbols(sym)%rank==0) then
                            refs(sym)%value=argument_bindings(j)%values(1)
                            refs(sym)%defined=argument_bindings(j)%initialized(1)
                            if(.not.refs(sym)%defined) then
                                refs(sym)%value%tag=ty_character
                                refs(sym)%value%s=repeat(' ',argument_bindings(j)%character_len)
                            end if
                        end if
                        refs(sym)%array%lower_bound=argument_bindings(j)%lower_bounds(1)
                        refs(sym)%array%upper_bound=argument_bindings(j)%upper_bounds(1)
                        refs(sym)%array%lower_bound2=argument_bindings(j)%lower_bounds(2)
                        refs(sym)%array%lower_bound3=argument_bindings(j)%lower_bounds(3)
                        refs(sym)%array%upper_bound2=argument_bindings(j)%upper_bounds(2)
                        refs(sym)%array%upper_bound3=argument_bindings(j)%upper_bounds(3)
                        cycle
                    end if
                    if(prog%symbols(sym)%rank==0) then
                        if(extent/=1) then
                            call runtime_error('invalid scalar argument storage',0,0); return
                        end if
                        refs(sym)%value=argument_bindings(j)%values(1)
                        if(prog%symbols(sym)%typ==ty_character.and..not.argument_bindings(j)%initialized(1)) then
                            refs(sym)%value%tag=ty_character
                            refs(sym)%value%s=repeat(' ',argument_bindings(j)%character_len)
                        end if
                        if(prog%symbols(sym)%typ==ty_character) then
                            if(.not.allocated(refs(sym)%value%s)) then
                                call runtime_error('CHARACTER dummy has no length',0,0);return
                            end if
                            k=prog%symbols(sym)%character_len
                            if(k>=0) then
                                if(len(refs(sym)%value%s)<k) then
                                    call runtime_error('CHARACTER actual shorter than fixed-length dummy',0,0);return
                                end if
                                if(prog%symbols(sym)%dummy_intent>=2.and.len(refs(sym)%value%s)/=k) then
                                    call runtime_error('fixed-length writable CHARACTER requires equal actual length',0,0);return
                                end if
                                refs(sym)%value%s=refs(sym)%value%s(:k)
                            end if
                        end if
                        refs(sym)%defined=argument_bindings(j)%initialized(1)
                        if(prog%symbols(sym)%dummy_intent==2) then
                            refs(sym)%defined=.false.
                            if(is_derived_type(prog%symbols(sym)%typ)) then
                                call initialize_record(refs(sym)%value,prog%symbols(sym)%typ)
                                refs(sym)%defined=.true.
                            end if
                        end if
                    else
                        dims=argument_bindings(j)%dims
                        if(any(dims<0).or.any(dims>imax)) then
                            call runtime_error('invalid argument dimension extents',0,0); return
                        end if
                        if(prog%symbols(sym)%rank==1) dims=[extent,1_int64,1_int64]
                        if(shape_size(dims)/=extent) then
                            call runtime_error('argument shape differs from storage',0,0); return
                        end if
                        ! Explicit bounds are evaluated only after all scalar
                        ! dummies have been associated, regardless of arg order.
                        if(.not.prog%symbols(sym)%assumed_shape) cycle
                        refs(sym)%array%upper_bound=refs(sym)%array%lower_bound+dims(1)-1_int64
                        if(prog%symbols(sym)%rank>=2) &
                            refs(sym)%array%upper_bound2=refs(sym)%array%lower_bound2+dims(2)-1_int64
                        if(prog%symbols(sym)%rank==3) &
                            refs(sym)%array%upper_bound3=refs(sym)%array%lower_bound3+dims(3)-1_int64
                    end if
                else
                    if(prog%symbols(sym)%rank/=0.or.argument_values(j)%tag/=prog%symbols(sym)%typ) then
                        call runtime_error('function argument type, rank or intent mismatch',0,0); return
                    end if
                    if((argument_values(j)%tag>=ty_integer.and.argument_values(j)%tag<=ty_logical).and. &
                       argument_values(j)%real_kind/=prog%symbols(sym)%real_kind) then
                        call runtime_error('procedure REAL argument kind mismatch',0,0); return
                    end if
                    refs(sym)%value=argument_values(j); refs(sym)%defined=.true.
                    if(prog%symbols(sym)%dummy_intent==2) then
                        refs(sym)%defined=.false.
                        if(is_derived_type(prog%symbols(sym)%typ)) then
                            call initialize_record(refs(sym)%value,prog%symbols(sym)%typ)
                            refs(sym)%defined=.true.
                        end if
                    end if
                end if
            end do
        end if
        ! Freeze explicit-shape dummy descriptors before any local bounds or
        ! array copies. The bounded grammar has no array-valued dependencies.
        if(scope>0) then
            do j=1,size(prog%procedures(scope)%args)
                sym=prog%procedures(scope)%args(j)
                if(prog%symbols(sym)%rank==0.or.prog%symbols(sym)%assumed_shape.or. &
                   prog%symbols(sym)%is_allocatable.or.prog%symbols(sym)%is_pointer) cycle
                if(.not.present(argument_bindings).or.prog%symbols(sym)%is_optional.or. &
                   prog%symbols(sym)%is_parameter.or.prog%symbols(sym)%initializer_expr/=0.or. &
                   prog%symbols(sym)%rank<1.or.prog%symbols(sym)%rank>3) then
                    call runtime_error('invalid explicit-shape dummy declaration',0,0);return
                end if
                if(prog%symbols(sym)%rank<3.and. &
                   (prog%symbols(sym)%lower_expr3/=0.or.prog%symbols(sym)%upper_expr3/=0)) then
                    call runtime_error('unexpected explicit-shape third dimension',0,0);return
                end if
                if(prog%symbols(sym)%rank<2.and. &
                   (prog%symbols(sym)%lower_expr2/=0.or.prog%symbols(sym)%upper_expr2/=0)) then
                    call runtime_error('unexpected explicit-shape second dimension',0,0);return
                end if
                call dummy_bound(prog%symbols(sym)%lower_expr,refs(sym)%array%lower_bound,.true., &
                    prog%symbols(sym)%is_automatic,prog%symbols(sym)%lower_bound)
                call dummy_bound(prog%symbols(sym)%upper_expr,refs(sym)%array%upper_bound,.false., &
                    prog%symbols(sym)%is_automatic,prog%symbols(sym)%upper_bound)
                if(prog%symbols(sym)%rank>=2) then
                    call dummy_bound(prog%symbols(sym)%lower_expr2,refs(sym)%array%lower_bound2,.true., &
                    prog%symbols(sym)%is_automatic,prog%symbols(sym)%lower_bound2)
                    call dummy_bound(prog%symbols(sym)%upper_expr2,refs(sym)%array%upper_bound2,.false., &
                    prog%symbols(sym)%is_automatic,prog%symbols(sym)%upper_bound2)
                end if
                if(prog%symbols(sym)%rank==3) then
                    call dummy_bound(prog%symbols(sym)%lower_expr3,refs(sym)%array%lower_bound3,.true., &
                    prog%symbols(sym)%is_automatic,prog%symbols(sym)%lower_bound3)
                    call dummy_bound(prog%symbols(sym)%upper_expr3,refs(sym)%array%upper_bound3,.false., &
                    prog%symbols(sym)%is_automatic,prog%symbols(sym)%upper_bound3)
                end if
                if(diag%code/=0) return
                dims=storage_dims(sym)
                if(any(dims>imax)) then
                    call runtime_error('explicit-shape dummy extent exceeds supported range',0,0);return
                end if
                if(shape_size(dims)>size(argument_bindings(j)%values,kind=int64)) then
                    call runtime_error('actual argument has fewer elements than explicit-shape dummy',0,0);return
                end if
            end do
        end if
        ! COUNT bounds read dummy values, so associate array data as well as
        ! descriptors before evaluating any specification expression. Include
        ! those copies in the same per-frame cap as the later local storage.
        do sym=1,prog%ns
            if(prog%symbols(sym)%scope/=scope.or..not.prog%symbols(sym)%is_dummy) cycle
            if(prog%symbols(sym)%rank==0) cycle
            call allocate_frame_array(sym)
            if(diag%code/=0) return
        end do
        call freeze_character_dummy_lengths()
        if(diag%code/=0) return
        do sym=1,prog%ns
            if(prog%symbols(sym)%scope/=scope.or.prog%symbols(sym)%typ/=ty_character) cycle
            if(prog%symbols(sym)%character_len>=0.or.prog%symbols(sym)%is_dummy.or.prog%symbols(sym)%deferred_character) cycle
            if(scope<=0.or.prog%symbols(sym)%is_parameter.or.prog%symbols(sym)%length_expr<=0.or. &
               prog%symbols(sym)%initializer_expr/=0) then
                call runtime_error('invalid runtime CHARACTER length declaration',0,0);return
            end if
            if(.not.valid_automatic_bound(prog,prog%symbols(sym)%length_expr,scope)) then
                call runtime_error('unsupported runtime CHARACTER length expression',0,0);return
            end if
            a=evaluate(prog%symbols(sym)%length_expr,0)
            if(diag%code/=0) return
            if(a%tag/=ty_integer.or.a%i>65536_int64) then
                call runtime_error('CHARACTER length limit exceeded (65536)',0,0);return
            end if
            refs(sym)%value%tag=ty_character;refs(sym)%value%s=repeat(' ',int(max(0_int64,a%i)))
        end do
        ! Freeze every automatic bound for this invocation before local storage
        ! is allocated or any procedure-body statement is executed.
        do sym=1,prog%ns
            if(prog%symbols(sym)%scope/=scope.or..not.prog%symbols(sym)%is_automatic) cycle
            if(prog%symbols(sym)%is_dummy.and.scope>0) then
                if(any(prog%procedures(scope)%args==sym)) then
                    if(prog%symbols(sym)%assumed_shape.or.prog%symbols(sym)%is_allocatable.or. &
                       prog%symbols(sym)%is_optional.or.prog%symbols(sym)%is_parameter.or. &
                       prog%symbols(sym)%initializer_expr/=0.or. &
                       prog%symbols(sym)%rank<1.or.prog%symbols(sym)%rank>3) then
                        call runtime_error('invalid explicit-shape dummy declaration',0,0);return
                    end if
                    cycle
                end if
            end if
            if(scope<=0.or.prog%symbols(sym)%is_dummy.or.prog%symbols(sym)%is_parameter.or. &
               prog%symbols(sym)%assumed_shape.or.prog%symbols(sym)%initializer_expr/=0.or. &
               prog%symbols(sym)%rank<1.or.prog%symbols(sym)%rank>3) then
                call runtime_error('invalid automatic array declaration',prog%symbols(sym)%line,prog%symbols(sym)%column);return
            end if
            call automatic_bound(prog%symbols(sym)%lower_expr,refs(sym)%array%lower_bound,.true.)
            call automatic_bound(prog%symbols(sym)%upper_expr,refs(sym)%array%upper_bound,.false.)
            if(prog%symbols(sym)%rank>=2) then
                call automatic_bound(prog%symbols(sym)%lower_expr2,refs(sym)%array%lower_bound2,.true.)
                call automatic_bound(prog%symbols(sym)%upper_expr2,refs(sym)%array%upper_bound2,.false.)
            end if
            if(prog%symbols(sym)%rank==3) then
                call automatic_bound(prog%symbols(sym)%lower_expr3,refs(sym)%array%lower_bound3,.true.)
                call automatic_bound(prog%symbols(sym)%upper_expr3,refs(sym)%array%upper_bound3,.false.)
            end if
            if(diag%code/=0) return
        end do
        shape_state=0
        do sym=1,prog%ns
            if(prog%symbols(sym)%scope/=scope.or.prog%symbols(sym)%is_dummy) cycle
            if(prog%symbols(sym)%rank==0) cycle
            call allocate_frame_array(sym)
            if(diag%code/=0) return
        end do
        pc=first_pc
        do while(pc<=last_pc)
            if (pc<first_pc) then
                call runtime_error('invalid instruction target',0,0)
                return
            end if
            call consume(prog%code(pc)%line,prog%code(pc)%column)
            if (diag%code/=0) return
            ! Section descriptors are evaluated once per statement, before any
            ! write. Loops obtain fresh descriptors on every iteration.
            shape_state=0
            do j=1,prog%ne
                if(allocated(expression_cache(j)%values)) deallocate(expression_cache(j)%values)
                expression_cache(j)%character_len=-1
                expression_cache(j)%gather_character_bytes=0_int64
            end do
            cached_elements=0_int64;cached_gather_character_bytes=0_int64
            associate(ins=>prog%code(pc))
            if(ins%scope/=scope) then
                call runtime_error('instruction is outside the active call frame',ins%line,ins%column); return
            end if
            sym=module_write_target(ins)
            if(sym>0) then
                if(.not.valid_symbol(sym)) return
                if(prog%symbols(sym)%scope<0.or.prog%symbols(sym)%is_saved.or.captured(sym)) call check_external_effect(ins%line,ins%column)
                if(diag%code/=0) return
            end if
            if(ins%format_expr<0.or.ins%format_expr>prog%ne.or.ins%advance_mode<0.or.ins%advance_mode>1) then
                call runtime_error('invalid output control metadata',ins%line,ins%column);return
            end if
            if(ins%format_expr/=0) then
                if((ins%op/=op_print.and.ins%op/=op_write_internal).or.allocated(ins%format)) then
                    call runtime_error('unexpected runtime format metadata',ins%line,ins%column);return
                end if
            end if
            if(ins%advance_mode/=0) then
                if(ins%op/=op_print.or.(.not.allocated(ins%format).and.ins%format_expr==0)) then
                    call runtime_error('invalid nonadvancing output metadata',ins%line,ins%column);return
                end if
            end if
            select case(ins%op)
            case(op_allocate,op_deallocate)
                if(ins%c/=0.or.ins%d/=0.or.ins%target/=0) then
                    call execute_allocation_group(pc)
                    if(diag%code/=0) return
                    pc=pc+ins%c-1
                else
                    call execute_allocation(ins)
                end if
            case(op_select)
                if(.not.valid_expression(ins%a)) return
                if(prog%expressions(ins%a)%rank/=0) then
                    call runtime_error('SELECT CASE selector must be scalar',ins%line,ins%column);return
                end if
                a=evaluate(ins%a,0)
                if(diag%code/=0) return
                if(a%tag/=ty_integer.and.a%tag/=ty_character.and.a%tag/=ty_logical) then
                    call runtime_error('invalid SELECT CASE selector type',ins%line,ins%column);return
                end if
                if(ins%target<=pc.or.ins%target>last_pc+1) then
                    call runtime_error('invalid SELECT CASE target',ins%line,ins%column);return
                end if
                selected=0;default_arm=0;arm=pc+1
                do while(arm<ins%target)
                    call consume(ins%line,ins%column)
                    if(diag%code/=0) return
                    associate(branch=>prog%code(arm))
                    if(branch%op/=op_case.or.branch%a/=pc.or.branch%scope/=scope.or. &
                       branch%target<=arm.or.branch%target>ins%target.or..not.allocated(branch%items)) then
                        call runtime_error('invalid SELECT CASE chain',ins%line,ins%column);return
                    end if
                    if(mod(size(branch%items),2)/=0) then
                        call runtime_error('invalid CASE bound list',branch%line,branch%column);return
                    end if
                    if(size(branch%items)==0) then
                        if(default_arm/=0) then
                            call runtime_error('duplicate CASE DEFAULT',branch%line,branch%column);return
                        end if
                        default_arm=arm+1
                    end if
                    do j=1,size(branch%items),2
                        if(all(branch%items(j:j+1)==0)) then
                            call runtime_error('empty CASE range',branch%line,branch%column);return
                        end if
                        matches=.true.
                        do k=0,1
                            if(branch%items(j+k)==0) cycle
                            b=evaluate(branch%items(j+k),0)
                            if(diag%code/=0) return
                            if(a%tag/=b%tag) then
                                call runtime_error('CASE type differs from selector',branch%line,branch%column);return
                            end if
                            select case(a%tag)
                            case(ty_integer)
                                match_bound=a%i>=b%i
                                if(k==1) match_bound=a%i<=b%i
                            case(ty_character)
                                if(.not.allocated(a%s).or..not.allocated(b%s)) then
                                    call runtime_error('invalid CASE character value',branch%line,branch%column);return
                                end if
                                match_bound=a%s>=b%s
                                if(k==1) match_bound=a%s<=b%s
                            case(ty_logical)
                                if(branch%items(j)/=branch%items(j+1)) then
                                    call runtime_error('LOGICAL CASE ranges are invalid',branch%line,branch%column);return
                                end if
                                match_bound=a%l.eqv.b%l
                            end select
                            matches=matches.and.match_bound
                        end do
                        if(matches.and.selected==0) selected=arm+1
                    end do
                    arm=branch%target
                    end associate
                end do
                if(selected==0) selected=default_arm
                if(selected==0) selected=ins%target
                pc=selected;cycle
            case(op_case)
                call runtime_error('CASE entered outside SELECT dispatch',ins%line,ins%column);return
            case(op_move_alloc)
                call execute_move_alloc(ins)
                if(diag%code/=0) return
            case(op_timing_query)
                call execute_timing_query(ins)
                if(diag%code/=0)return
            case(op_process_query)
                call execute_process_query(ins)
                if(diag%code/=0) return
            case(op_random_seed)
                if(ins%symbol/=0.or.ins%a/=0.or.ins%b/=0.or.ins%c/=0.or.ins%d/=0.or.ins%target/=0.or. &
                   ins%component/=0.or.ins%generic_id/=0.or.ins%third/=0.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
                   allocated(ins%items).or.allocated(ins%format).or.len_trim(ins%construct_name)/=0) then
                    call runtime_error('invalid RANDOM_SEED instruction metadata',ins%line,ins%column);return
                end if
                call check_random_effect(ins%line,ins%column,'RANDOM_SEED')
                if(diag%code/=0) return
                rng=initial_random_state
            case(op_random_number)
                call check_random_effect(ins%line,ins%column,'RANDOM_NUMBER')
                if(diag%code/=0) return
                call fill_random(ins%symbol,ins%a,ins%line,ins%column)
                if(diag%code/=0) return
            case(op_where)
                call execute_where(pc)
                if(diag%code/=0) return
                pc=ins%target;cycle
            case(op_elsewhere)
                call runtime_error('ELSEWHERE entered outside WHERE dispatch',ins%line,ins%column);return
            case(op_forall)
                call execute_forall(pc)
                if(diag%code/=0) return
                pc=ins%target;cycle
            case(op_pointer_assign)
                call pointer_assignment(ins)
                if(diag%code/=0) return
            case(op_nullify)
                if(ins%a/=0.or.ins%b/=0.or.ins%c/=0.or.ins%d/=0.or.ins%third/=0.or.ins%component/=0.or. &
                   ins%target/=0.or.ins%generic_id/=0.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
                   allocated(ins%items).or.allocated(ins%format).or.len_trim(ins%construct_name)/=0) then
                    call runtime_error('invalid NULLIFY operands',ins%line,ins%column);return
                end if
                if(.not.valid_descriptor_symbol(ins%symbol)) return
                if(.not.prog%symbols(ins%symbol)%is_pointer.or.prog%symbols(ins%symbol)%dummy_intent==1) then
                    call runtime_error('NULLIFY requires a writable POINTER descriptor',ins%line,ins%column);return
                end if
                call nullify_view(refs(ins%symbol)%array)
            case(op_assign)
                sym=ins%symbol
                if (.not.valid_symbol(sym)) return
                if (prog%symbols(sym)%is_dummy.and.prog%symbols(sym)%dummy_intent<=1) then
                    call runtime_error('assignment to INTENT(IN) dummy',ins%line,ins%column); return
                end if
                if (prog%symbols(sym)%is_parameter) then
                    call runtime_error('assignment to PARAMETER constant',ins%line,ins%column)
                    return
                end if
                if (refs(sym)%active) then
                    call runtime_error('assignment to active DO variable',ins%line,ins%column)
                    return
                end if
                if (.not.valid_expression(ins%a)) return
                if(ins%component/=0) then
                    k=prog%symbols(sym)%typ-ty_derived_base
                    if(.not.is_derived_type(prog%symbols(sym)%typ).or.k>prog%nt) then
                        call runtime_error('component target is not a derived object',ins%line,ins%column);return
                    end if
                    if(ins%component<1.or.ins%component>prog%derived_types(k)%ncomponents.or. &
                       ins%b/=0.or.ins%c/=0.or.ins%d/=0.or.ins%third/=0.or.prog%expressions(ins%a)%rank/=0) then
                        call runtime_error('invalid component assignment',ins%line,ins%column);return
                    end if
                    a=evaluate(ins%a,0);if(diag%code/=0) return
                    converted=convert(a,prog%derived_types(k)%component_types(ins%component),ins%line,ins%column, &
                                      prog%derived_types(k)%component_kinds(ins%component))
                    if(diag%code/=0) return
                    if(.not.allocated(refs(sym)%value%record)) call initialize_record(refs(sym)%value,prog%symbols(sym)%typ)
                    if(diag%code/=0) return
                    component_assignment=pack_component(converted,k,ins%component)
                    if(diag%code/=0) return
                    refs(sym)%value%record%components(ins%component)=component_assignment
                    refs(sym)%value%record%component_defined(ins%component)=.true.;refs(sym)%defined=.true.
                    pc=pc+1;cycle
                end if
                if (ins%c/=0) then
                    if (.not.valid_expression(ins%c)) return
                    if(prog%expressions(ins%c)%kind==ex_substring) then
                        if(ins%b/=0.or.ins%d/=0.or.ins%third/=0.or.prog%expressions(ins%c)%symbol/=sym.or. &
                           prog%expressions(ins%a)%rank/=0.or.prog%expressions(ins%a)%typ/=ty_character) then
                            call runtime_error('invalid substring assignment target',ins%line,ins%column);return
                        end if
                        call assign_substring(sym,ins%c,ins%a,ins%line,ins%column)
                        if(diag%code/=0) return
                        pc=pc+1;cycle
                    end if
                    if (prog%symbols(sym)%rank<1.or.ins%b/=0.or.ins%d/=0.or.ins%third/=0.or. &
                        prog%expressions(ins%c)%kind/=ex_section.or.prog%expressions(ins%c)%symbol/=sym) then
                        call runtime_error('invalid section assignment target',ins%line,ins%column)
                        return
                    end if
                    call prepare_expression(ins%c,0)
                    if (diag%code/=0) return
                end if
                if (prog%symbols(sym)%rank>0.and.ins%b==0) then
                    if(prog%symbols(sym)%is_allocatable.and.ins%c==0.and.prog%expressions(ins%a)%rank>0) then
                        call assign_allocatable_array(sym,ins%a,ins%line,ins%column)
                        if(diag%code/=0) return
                        pc=pc+1;cycle
                    end if
                    if(.not.array_available(sym,ins%line,ins%column)) return
                    extent=size(refs(sym)%array%data,kind=int64)
                    target_rank=prog%symbols(sym)%rank
                    target_dims=storage_dims(sym)
                    if (ins%c/=0) then
                        extent=shape_extent(ins%c); target_dims=shape_dims(:,ins%c)
                        target_rank=prog%expressions(ins%c)%rank
                    end if
                    call prepare_expression(ins%a,0)
                    if (diag%code/=0) return
                    if (prog%expressions(ins%a)%rank>0) then
                        if (prog%expressions(ins%a)%rank/=target_rank.or. &
                            shape_extent(ins%a)/=extent.or.any(shape_dims(:,ins%a)/=target_dims)) then
                            call runtime_error('array assignment shapes do not conform',ins%line,ins%column)
                            return
                        end if
                    end if
                    allocate(assigned(int(extent)),stat=ios)
                    if (ios/=0) then
                        call runtime_error('array temporary allocation failed',ins%line,ins%column)
                        return
                    end if
                    if (prog%expressions(ins%a)%rank==0) then
                        ! Scalar expansion evaluates the scalar once, including
                        ! an empty target. No target element changes on failure.
                        a=evaluate(ins%a,0)
                        if (diag%code/=0) return
                        converted=convert(a,prog%symbols(sym)%typ,ins%line,ins%column,prog%symbols(sym)%real_kind)
                        if (diag%code/=0) return
                        if(prog%symbols(sym)%typ==ty_character) call fit_character(converted,sym,ins%line,ins%column)
                        if(diag%code/=0) return
                        do j=1,int(extent)
                            call consume(ins%line,ins%column)
                            if (diag%code/=0) return
                            assigned(j)=converted
                        end do
                    else
                        do j=1,int(extent)
                            a=evaluate(ins%a,0,j)
                            if (diag%code/=0) return
                            assigned(j)=convert(a,prog%symbols(sym)%typ,ins%line,ins%column,prog%symbols(sym)%real_kind)
                            if (diag%code/=0) return
                            if(prog%symbols(sym)%typ==ty_character) call fit_character(assigned(j),sym,ins%line,ins%column)
                            if(diag%code/=0) return
                        end do
                    end if
                    ! Commit only after every value/conversion has succeeded.
                    ! Self-references therefore see the complete old array.
                    do j=1,int(extent)
                        offset=j
                        if(ins%c/=0) offset=section_offset(ins%c,j)
                        refs(sym)%array%data(offset)=assigned(j)
                        refs(sym)%array%flags(offset)=.true.
                    end do
                    deallocate(assigned)
                else
                    if (prog%expressions(ins%a)%rank/=0) then
                        call runtime_error('scalar assignment requires scalar expression',ins%line,ins%column)
                        return
                    end if
                    a=evaluate(ins%a,0)
                    if (diag%code/=0) return
                    converted=convert(a,prog%symbols(sym)%typ,ins%line,ins%column,prog%symbols(sym)%real_kind)
                    if (diag%code/=0) return
                    if (prog%symbols(sym)%rank>0) then
                        offset=element_expression_offset(sym,ins%b,ins%d,ins%third,0,ins%line,ins%column)
                        if (diag%code/=0) return
                        if(prog%symbols(sym)%typ==ty_character) call fit_character(converted,sym,ins%line,ins%column)
                        if(diag%code/=0) return
                        refs(sym)%array%data(offset)=converted
                        refs(sym)%array%flags(offset)=.true.
                    else
                        if (ins%b/=0.or.ins%d/=0.or.ins%third/=0) then
                            call runtime_error('scalar assignment has an array subscript',ins%line,ins%column)
                            return
                        end if
                        if(prog%symbols(sym)%is_allocatable) then
                            call assign_allocatable_scalar(sym,converted,ins%line,ins%column)
                            if(diag%code/=0) return
                            pc=pc+1;cycle
                        end if
                        if(prog%symbols(sym)%typ==ty_character) call fit_character(converted,sym,ins%line,ins%column)
                        if(diag%code/=0) return
                        refs(sym)%value=converted
                        refs(sym)%defined=.true.
                    end if
                end if
            case(op_inquire_name)
                call execute_inquire_name(ins)
                if(diag%code/=0)return
            case(op_backspace)
                call execute_backspace(ins)
                if(diag%code/=0) return
            case(op_read_internal,op_read_external)
                call execute_internal_read(ins)
                if(diag%code/=0) return
            case(op_write_internal)
                block
                integer::file_symbol,file_offset,file_length,file_item
                type(value_t)::staged_record
                file_symbol=ins%symbol
                if(.not.valid_symbol(file_symbol)) return
                if(ins%b/=0.or.ins%c/=0.or.ins%d/=0.or.ins%target/=0.or.ins%component/=0.or. &
                   ins%generic_id/=0.or.ins%third/=0.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
                   ins%advance_mode/=0.or.len_trim(ins%construct_name)/=0)then
                    call runtime_error('invalid internal WRITE instruction metadata',ins%line,ins%column);return
                end if
                if(prog%symbols(file_symbol)%typ/=ty_character.or. &
                   prog%symbols(file_symbol)%is_parameter.or.prog%symbols(file_symbol)%dummy_intent==1.or. &
                   .not.allocated(ins%items).or.(.not.allocated(ins%format).and.ins%format_expr==0)) then
                    call runtime_error('invalid internal WRITE target or format',ins%line,ins%column);return
                end if
                file_offset=0
                if(prog%symbols(file_symbol)%rank>0)then
                    if(.not.valid_internal_write_element(prog,ins%a,file_symbol,scope))then
                        call runtime_error('invalid internal WRITE array element descriptor',ins%line,ins%column);return
                    end if
                    if(.not.valid_internal_write_values(prog,ins))then
                        call runtime_error('invalid internal WRITE element expression effects',ins%line,ins%column);return
                    end if
                    ! Freeze the address once without reading an undefined target.
                    file_offset=internal_write_element_offset(ins%a,file_symbol,ins%line,ins%column)
                    if(diag%code/=0)return
                    file_length=prog%symbols(file_symbol)%character_len
                    if(prog%symbols(file_symbol)%is_allocatable)then
                        file_length=refs(file_symbol)%array%character_len
                    else if(file_length<0)then
                        if(allocated(refs(file_symbol)%value%s))file_length=len(refs(file_symbol)%value%s)
                        if(file_length<0)file_length=refs(file_symbol)%array%character_len
                    end if
                else
                    if(ins%a/=0)then
                        call runtime_error('scalar internal WRITE has an element descriptor',ins%line,ins%column);return
                    end if
                    if(prog%symbols(file_symbol)%is_allocatable)then
                        if(.not.array_available(file_symbol,ins%line,ins%column))return
                    end if
                    file_length=prog%symbols(file_symbol)%character_len
                    if(file_length<0.and.allocated(refs(file_symbol)%value%s))file_length=len(refs(file_symbol)%value%s)
                end if
                if(file_length<0.or.file_length>65536)then
                    call runtime_error('invalid internal WRITE CHARACTER length',ins%line,ins%column);return
                end if
                call capture_output_format(ins,active_format)
                if(diag%code/=0) return
                call collect_output_values(ins,printed)
                if(diag%code/=0) return
                if(file_offset>0)then
                    do file_item=1,size(printed)
                        if(is_derived_type(printed(file_item)%tag))then
                            call runtime_error('derived values are unsupported in internal WRITE array elements', &
                                ins%line,ins%column);return
                        end if
                    end do
                end if
                call formatted_record(active_format,printed,line,ins%line,ins%column)
                if(diag%code/=0) return
                if(len(line)>file_length) then
                    call runtime_error('internal WRITE record exceeds CHARACTER length',ins%line,ins%column);return
                end if
                staged_record=value_t(tag=ty_character,s=line//repeat(' ',file_length-len(line)))
                ! Commit a single target only after address/format/value/length
                ! validation succeeds. Other array values and flags are untouched.
                if(file_offset>0)then
                    if(.not.array_available(file_symbol,ins%line,ins%column))return
                    if(file_offset>size(refs(file_symbol)%array%data))then
                        call runtime_error('internal WRITE target storage changed during evaluation',ins%line,ins%column);return
                    end if
                    refs(file_symbol)%array%data(file_offset)=staged_record
                    refs(file_symbol)%array%flags(file_offset)=.true.
                else
                    refs(file_symbol)%value=staged_record;refs(file_symbol)%defined=.true.
                end if
                deallocate(printed)
                end block
            case(op_write_defined)
                call check_external_effect(ins%line,ins%column)
                if(diag%code/=0) return
                if(.not.present(defined_output).or..not.in_output.or.scope<=0) then
                    call runtime_error('defined child WRITE requires an active parent data transfer',ins%line,ins%column)
                    return
                end if
                if(.not.allocated(ins%items).or..not.allocated(ins%format)) then
                    call runtime_error('invalid defined child WRITE',ins%line,ins%column);return
                end if
                if(size(prog%procedures(scope)%args)/=6) then
                    call runtime_error('invalid defined WRITE procedure',ins%line,ins%column);return
                end if
                if(ins%symbol/=prog%procedures(scope)%args(2)) then
                    call runtime_error('defined child WRITE unit differs',ins%line,ins%column);return
                end if
                call collect_output_values(ins,printed)
                if(diag%code/=0) return
                call formatted_record(ins%format,printed,line,ins%line,ins%column)
                if(diag%code/=0) return
                if(len(line)>65536-len(defined_output)) then
                    call runtime_error('defined WRITE record exceeds 65536 characters',ins%line,ins%column);return
                end if
                defined_output=defined_output//line
                if(ins%a>0) then
                    if(ins%a/=prog%procedures(scope)%args(5)) then
                        call runtime_error('defined child WRITE IOSTAT differs',ins%line,ins%column);return
                    end if
                    refs(ins%a)%value=value_t(tag=ty_integer,i=0_int64);refs(ins%a)%defined=.true.
                end if
                if(ins%b>0) then
                    if(ins%b/=prog%procedures(scope)%args(6)) then
                        call runtime_error('defined child WRITE IOMSG differs',ins%line,ins%column);return
                    end if
                end if
                deallocate(printed)
            case(op_stop)
                if(scope>0) then
                    if(prog%procedures(scope)%is_pure) then
                        call runtime_error('STOP inside PURE procedure',ins%line,ins%column);return
                    end if
                end if
                line='STOP';k=0
                if(ins%a/=0) then
                    a=evaluate(ins%a,0);if(diag%code/=0) return
                    if(a%tag==ty_character.and.allocated(a%s)) then
                        line='STOP '//a%s
                    else if(a%tag==ty_integer) then
                        if(a%i<0.or.a%i>255) then
                            call runtime_error('STOP integer status must be between 0 and 255',ins%line,ins%column);return
                        end if
                        k=int(a%i);write(buffer,'(i0)') a%i;line='STOP '//trim(buffer)
                    else
                        call runtime_error('invalid STOP code',ins%line,ins%column);return
                    end if
                end if
                call fail(diag,line,ins%line,ins%column,3);diag%stop_status=k;return
            case(op_print)
                if(ins%a/=0)then
                    if(.not.valid_runtime_output_unit(prog,ins%a,ins%symbol,scope))then
                        call runtime_error('invalid runtime output unit metadata',ins%line,ins%column);return
                    end if
                else if(ins%symbol/=0) then
                    if(.not.valid_stdout_unit(prog,ins%symbol,scope)) then
                        call runtime_error('invalid standard-output unit metadata',ins%line,ins%column);return
                    end if
                end if
                if(ins%b/=0.or.ins%c/=0.or.ins%d/=0.or.ins%target/=0.or. &
                   ins%component/=0.or.ins%generic_id/=0.or.ins%third/=0.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
                   len_trim(ins%construct_name)/=0) then
                    call runtime_error('invalid standard-output instruction metadata',ins%line,ins%column);return
                end if
                call check_external_effect(ins%line,ins%column)
                if(diag%code/=0) return
                if(scope/=0) then
                    if(prog%procedures(scope)%is_pure.or. &
                       (.not.prog%procedures(scope)%is_subroutine.and..not.prog%procedures(scope)%has_impure_prefix)) then
                        call runtime_error('I/O inside this function or PURE procedure is unsupported',ins%line,ins%column); return
                    end if
                end if
                if (.not.allocated(ins%items)) then
                    call runtime_error('invalid PRINT instruction',ins%line,ins%column)
                    return
                end if
                if(in_output) then
                    call runtime_error('recursive I/O on the output unit is unsupported',ins%line,ins%column); return
                end if
                if(ins%a/=0)then
                    a=evaluate(ins%a,0)
                    if(diag%code/=0)return
                    if(a%tag/=ty_integer.or.a%real_kind/=prog%expressions(ins%a)%real_kind)then
                        call runtime_error('invalid runtime output unit value',ins%line,ins%column);return
                    end if
                    if(a%i/=int(processor_output_unit,int64))then
                        call runtime_error('unsupported WRITE unit: runtime unit must equal OUTPUT_UNIT; file output is unsupported', &
                            prog%expressions(ins%a)%line,prog%expressions(ins%a)%column);return
                    end if
                end if
                in_output=.true.
                call capture_output_format(ins,active_format)
                if(diag%code/=0) return
                call collect_output_values(ins,printed)
                if(diag%code/=0) return
                if(allocated(active_format)) then
                    if(.not.allocated(context%output_tail)) context%output_tail=''
                    call formatted_record(active_format,printed,line,ins%line,ins%column, &
                        allow_reversion=.true.,nonadvancing=ins%advance_mode==1, &
                        initial_tail=context%output_tail,final_position=output_cursor)
                    if(diag%code/=0) return
                else
                line='';list_length=0
                do j=1,size(printed)
                    if(is_derived_type(printed(j)%tag)) then
                        call render_derived(printed(j),'LISTDIRECTED',defined_text,ins%line,ins%column)
                        if(diag%code/=0) return
                        call append_list_output(line,list_length,' '//defined_text,ins%line,ins%column)
                        if(diag%code/=0) return
                        cycle
                    end if
                    select case(printed(j)%tag)
                    case(ty_integer)
                        write(buffer,'(i0)') printed(j)%i
                        call append_list_output(line,list_length,' '//trim(buffer),ins%line,ins%column)
                    case(ty_real)
                        if(printed(j)%real_kind==8) then
                            write(buffer,'(g0.17)') printed(j)%r
                        else
                            write(buffer,'(g0.9)') real(printed(j)%r,real32)
                        end if
                        call append_list_output(line,list_length,' '//trim(buffer),ins%line,ins%column)
                    case(ty_logical)
                        if (printed(j)%l) then
                            call append_list_output(line,list_length,' T',ins%line,ins%column)
                        else
                            call append_list_output(line,list_length,' F',ins%line,ins%column)
                        end if
                    case(ty_character)
                        if (allocated(printed(j)%s)) then
                            if (j>1) then
                                if (printed(j-1)%tag==ty_character) then
                                    call append_list_output(line,list_length,printed(j)%s,ins%line,ins%column)
                                else
                                    call append_list_output(line,list_length,' '//printed(j)%s,ins%line,ins%column)
                                end if
                            else
                                call append_list_output(line,list_length,' '//printed(j)%s,ins%line,ins%column)
                            end if
                        else
                            call runtime_error('invalid character value',ins%line,ins%column)
                            return
                        end if
                    case default
                        call runtime_error('invalid PRINT value',ins%line,ins%column)
                        return
                    end select
                    if(diag%code/=0) return
                end do
                line=line(:list_length);output_cursor=len(line)
                end if
                call commit_output_record(line,ins%advance_mode,allocated(active_format),ins%line,ins%column,output_cursor)
                if(diag%code/=0) return
                deallocate(printed)
                in_output=.false.
            case(op_call)
                sym=ins%symbol
                if(sym<1.or.sym>prog%np) then
                    call runtime_error('invalid subroutine reference',ins%line,ins%column); return
                end if
                if(scope/=0) then
                    if(prog%procedures(scope)%is_pure.and..not.prog%procedures(sym)%is_pure) then
                        call runtime_error('impure CALL inside a function or PURE procedure',ins%line,ins%column); return
                    end if
                end if
                if(.not.prog%procedures(sym)%is_subroutine.or..not.allocated(ins%items)) then
                    call runtime_error('invalid CALL instruction',ins%line,ins%column); return
                end if
                if(.not.allocated(prog%procedures(sym)%args)) then
                    call runtime_error('missing subroutine dummies',ins%line,ins%column); return
                end if
                if(size(ins%items)/=size(prog%procedures(sym)%args)) then
                    call runtime_error('subroutine argument count mismatch',ins%line,ins%column); return
                end if
                call invoke_procedure(sym,ins%items,ins%line,ins%column,0)
                if(diag%code/=0) return
            case(op_return)
                if(scope==0) then
                    call runtime_error('RETURN outside a procedure',ins%line,ins%column); return
                end if
                pc=last_pc+1
                exit
            case(op_error_stop)
                if(ins%a==0) then
                    call runtime_error('ERROR STOP',ins%line,ins%column)
                else
                    a=evaluate(ins%a,0)
                    if(diag%code/=0) return
                    if(a%tag==ty_character.and.allocated(a%s)) then
                        call runtime_error('ERROR STOP: '//a%s,ins%line,ins%column)
                    else if(a%tag==ty_integer) then
                        write(buffer,'(i0)') a%i
                        call runtime_error('ERROR STOP: '//trim(buffer),ins%line,ins%column)
                    else
                        call runtime_error('invalid ERROR STOP code',ins%line,ins%column)
                    end if
                end if
                return
            case(op_branch)
                a=evaluate(ins%a,0)
                if (diag%code/=0) return
                if (a%tag/=ty_logical) then
                    call runtime_error('nonlogical branch condition',ins%line,ins%column)
                    return
                end if
                if (.not.a%l) then
                    pc=ins%target
                    cycle
                end if
            case(op_jump)
                pc=ins%target
                cycle
            case(op_exit,op_cycle)
                loop_pc=ins%a
                if(loop_pc<first_pc.or.loop_pc>=pc) then
                    call runtime_error('invalid EXIT/CYCLE loop target',ins%line,ins%column);return
                end if
                if(prog%code(loop_pc)%op/=op_do.or..not.active(loop_pc).or. &
                   prog%code(loop_pc)%target<=pc) then
                    call runtime_error('EXIT/CYCLE target is not an active enclosing DO',ins%line,ins%column);return
                end if
                j=prog%code(loop_pc)%target
                if(ins%op==op_cycle) j=j-1
                if(ins%target/=j.or.j<first_pc.or.j>last_pc+1) then
                    call runtime_error('invalid EXIT/CYCLE destination',ins%line,ins%column);return
                end if
                ! Leaving an outer loop must release every inner active variable.
                do j=loop_pc,pc-1
                    if(.not.active(j)) cycle
                    if(j==loop_pc.and.ins%op==op_cycle) cycle
                    active(j)=.false.
                    if(prog%code(j)%d==0) refs(prog%code(j)%symbol)%active=.false.
                end do
                pc=ins%target;cycle
            case(op_do)
                if(ins%target<=pc+1.or.ins%target>last_pc+1) then
                    call runtime_error('invalid DO exit target',ins%line,ins%column);return
                end if
                j=ins%target-1
                if(prog%code(j)%op/=op_next.or.prog%code(j)%a/=pc.or.prog%code(j)%target/=pc+1) then
                    call runtime_error('invalid DO back edge identity',ins%line,ins%column);return
                end if
                if(ins%d/=0.and.ins%d/=1.and.ins%d/=2) then
                    call runtime_error('invalid DO control form',ins%line,ins%column);return
                end if
                if(prog%code(j)%d/=ins%d.or.prog%code(j)%symbol/=ins%symbol) then
                    call runtime_error('DO back edge control form differs',ins%line,ins%column);return
                end if
                if(ins%d==2) then
                    if(ins%symbol/=0.or.ins%b/=0.or.ins%c/=0) then
                        call runtime_error('invalid DO WHILE loop control',ins%line,ins%column);return
                    end if
                    if(.not.valid_expression(ins%a)) return
                    associate(e=>prog%expressions(ins%a))
                    if(e%typ/=ty_logical.or.e%rank/=0.or.e%real_kind/=4.or.e%extent/=0.or. &
                       any(e%dims/=0).or.e%character_len/=-1) then
                        call runtime_error('invalid DO WHILE condition metadata',ins%line,ins%column);return
                    end if
                    end associate
                    call validate_while_condition(ins%a)
                    if(diag%code/=0) return
                    a=evaluate(ins%a,0)
                    if(diag%code/=0) return
                    call validate_while_value(a,ty_logical,4,-1,ins%line,ins%column)
                    if(diag%code/=0) return
                    active(pc)=a%l
                    if(a%l) then
                        pc=pc+1
                    else
                        pc=ins%target
                    end if
                    cycle
                end if
                if(ins%d==1) then
                    if(ins%symbol/=0.or.ins%a/=0.or.ins%b/=0.or.ins%c/=0) then
                        call runtime_error('bare DO has unexpected loop control',ins%line,ins%column);return
                    end if
                    active(pc)=.true.;pc=pc+1;cycle
                end if
                if(.not.valid_expression(ins%a).or..not.valid_expression(ins%b)) return
                if(prog%expressions(ins%a)%rank/=0.or.prog%expressions(ins%b)%rank/=0) then
                    call runtime_error('DO bounds must be scalar',ins%line,ins%column);return
                end if
                if(ins%c/=0) then
                    if(.not.valid_expression(ins%c)) return
                    if(prog%expressions(ins%c)%rank/=0) then
                        call runtime_error('DO step must be scalar',ins%line,ins%column);return
                    end if
                end if
                sym=ins%symbol
                if (.not.valid_symbol(sym)) return
                if (prog%symbols(sym)%is_dummy.and.prog%symbols(sym)%dummy_intent<=1) then
                    call runtime_error('INTENT(IN) dummy cannot be a DO variable',ins%line,ins%column); return
                end if
                if (prog%symbols(sym)%is_parameter) then
                    call runtime_error('DO variable cannot be a PARAMETER constant',ins%line,ins%column)
                    return
                end if
                if (prog%symbols(sym)%rank/=0.or.prog%symbols(sym)%typ/=ty_integer.or. &
                    (prog%symbols(sym)%real_kind/=4.and.prog%symbols(sym)%real_kind/=8)) then
                    call runtime_error('DO variable must be an INTEGER scalar',ins%line,ins%column)
                    return
                end if
                if (refs(sym)%active) then
                    call runtime_error('nested reuse of active DO variable',ins%line,ins%column)
                    return
                end if
                a=evaluate(ins%a,0)
                b=evaluate(ins%b,0)
                c=value_t(tag=ty_integer,real_kind=prog%symbols(sym)%real_kind,i=1_int64)
                if (ins%c/=0) c=evaluate(ins%c,0)
                if (diag%code/=0) return
                if (a%tag/=ty_integer .or. b%tag/=ty_integer .or. c%tag/=ty_integer) then
                    call runtime_error('noninteger DO control',ins%line,ins%column)
                    return
                end if
                if(.not.check_integer(a%i,ins%line,ins%column,prog%symbols(sym)%real_kind)) return
                if(.not.check_integer(b%i,ins%line,ins%column,prog%symbols(sym)%real_kind)) return
                if(.not.check_integer(c%i,ins%line,ins%column,prog%symbols(sym)%real_kind)) return
                if((a%real_kind/=4.and.a%real_kind/=8).or.(b%real_kind/=4.and.b%real_kind/=8).or. &
                   (c%real_kind/=4.and.c%real_kind/=8)) then
                    call runtime_error('unsupported DO control kind',ins%line,ins%column);return
                end if
                first=a%i
                last=b%i
                stride=c%i
                if (stride==0_int64) then
                    call runtime_error('DO step is zero',ins%line,ins%column)
                    return
                end if
                ! Freeze the converted controls. Comparing after each checked increment
                ! avoids overflowing a full-range int64 trip count or bound difference.
                refs(sym)%value=a
                refs(sym)%value%real_kind=prog%symbols(sym)%real_kind
                refs(sym)%defined=.true.
                if ((stride>0.and.first>last).or.(stride<0.and.first<last)) then
                    pc=ins%target
                    cycle
                end if
                active(pc)=.true.
                refs(sym)%active=.true.
                loop_last(pc)=last
                increments(pc)=stride
            case(op_next)
                loop_pc=ins%a
                if (loop_pc<1 .or. loop_pc>prog%nc) then
                    call runtime_error('invalid DO back edge',ins%line,ins%column)
                    return
                end if
                if (.not.active(loop_pc)) then
                    call runtime_error('inactive DO back edge',ins%line,ins%column)
                    return
                end if
                if(prog%code(loop_pc)%op/=op_do.or.prog%code(loop_pc)%target/=pc+1.or. &
                   ins%target/=loop_pc+1.or.ins%d/=prog%code(loop_pc)%d.or. &
                   ins%symbol/=prog%code(loop_pc)%symbol) then
                    call runtime_error('invalid DO back edge identity',ins%line,ins%column);return
                end if
                if(prog%code(loop_pc)%d==1) then
                    pc=ins%target;cycle
                end if
                if(prog%code(loop_pc)%d==2) then
                    active(loop_pc)=.false.;pc=loop_pc;cycle
                end if
                sym=prog%code(loop_pc)%symbol
                next_value=checked_op('+',refs(sym)%value%i,increments(loop_pc), &
                    prog%symbols(sym)%real_kind,ins%line,ins%column)
                if (diag%code/=0) return
                refs(sym)%value%i=next_value
                if ((increments(loop_pc)>0.and.next_value<=loop_last(loop_pc)).or. &
                    (increments(loop_pc)<0.and.next_value>=loop_last(loop_pc))) then
                    pc=ins%target
                    cycle
                end if
                active(loop_pc)=.false.
                refs(sym)%active=.false.
            case default
                call runtime_error('invalid instruction opcode',ins%line,ins%column)
                return
            end select
            end associate
            pc=pc+1
        end do
        if(pc/=last_pc+1) then
            call runtime_error('instruction escaped its call frame',0,0); return
        end if
        ! RETURN ends every DO owned by this frame. Release shared module
        ! control variables without touching loops still active in callers.
        do j=first_pc,last_pc
            if(.not.active(j).or.prog%code(j)%op/=op_do) cycle
            if(prog%code(j)%d==0) refs(prog%code(j)%symbol)%active=.false.
        end do
        if(scope/=0) then
            if(present(argument_bindings)) then
                do j=1,size(prog%procedures(scope)%args)
                    sym=prog%procedures(scope)%args(j)
                    if(prog%symbols(sym)%dummy_intent<=1.or..not.dummy_present(sym)) cycle
                    if(prog%symbols(sym)%is_pointer) then
                        call copy_alias_view(argument_bindings(j)%view,refs(sym)%array,0,0)
                        if(diag%code/=0) return
                        cycle
                    end if
                    if(argument_bindings(j)%shared_target) cycle
                    if(prog%symbols(sym)%is_allocatable) then
                        argument_bindings(j)%is_allocated=allocated(refs(sym)%array%values)
                        if(prog%symbols(sym)%typ==ty_character) then
                            argument_bindings(j)%character_len=-1
                            if(allocated(refs(sym)%value%s)) argument_bindings(j)%character_len=len(refs(sym)%value%s)
                        end if
                        argument_bindings(j)%lower_bounds=[refs(sym)%array%lower_bound,refs(sym)%array%lower_bound2,refs(sym)%array%lower_bound3]
                        argument_bindings(j)%upper_bounds=[refs(sym)%array%upper_bound,refs(sym)%array%upper_bound2,refs(sym)%array%upper_bound3]
                        argument_bindings(j)%dims=0_int64
                        if(argument_bindings(j)%is_allocated) then
                            if(prog%symbols(sym)%rank==0) then
                                refs(sym)%array%values(1)=refs(sym)%value
                                refs(sym)%array%initialized(1)=refs(sym)%defined
                            end if
                            argument_bindings(j)%dims=storage_dims(sym)
                            call move_alloc(refs(sym)%array%values,argument_bindings(j)%values)
                            call move_alloc(refs(sym)%array%initialized,argument_bindings(j)%initialized)
                        else
                            if(allocated(argument_bindings(j)%values)) deallocate(argument_bindings(j)%values)
                            if(allocated(argument_bindings(j)%initialized)) deallocate(argument_bindings(j)%initialized)
                            allocate(argument_bindings(j)%values(0),argument_bindings(j)%initialized(0))
                        end if
                    else if(prog%symbols(sym)%rank==0) then
                        argument_bindings(j)%values(1)=refs(sym)%value
                        argument_bindings(j)%initialized(1)=refs(sym)%defined
                    else
                        argument_bindings(j)%values=refs(sym)%array%data
                        argument_bindings(j)%initialized=refs(sym)%array%flags
                    end if
                end do
            end if
            if(prog%procedures(scope)%is_subroutine) return
            result_symbol=prog%procedures(scope)%result_symbol
            if(.not.valid_symbol(result_symbol)) return
            if(prog%symbols(result_symbol)%scope/=scope.or.prog%symbols(result_symbol)%is_dummy.or. &
               prog%symbols(result_symbol)%is_parameter) then
                call runtime_error('invalid function result declaration',0,0); return
            end if
            if(prog%symbols(result_symbol)%rank>0) then
                if(.not.present(procedure_array).or.prog%procedures(scope)%is_elemental.or. &
                   prog%symbols(result_symbol)%rank>3.or.prog%symbols(result_symbol)%typ<ty_integer.or. &
                   prog%symbols(result_symbol)%typ>ty_character) then
                    call runtime_error('invalid array function result declaration',0,0);return
                end if
                if(.not.allocated(refs(result_symbol)%array%values).or. &
                   .not.allocated(refs(result_symbol)%array%initialized)) then
                    call runtime_error('array function RESULT has no storage',0,0);return
                end if
                do j=1,size(refs(result_symbol)%array%data)
                    call consume(prog%procedures(scope)%end_line,prog%procedures(scope)%end_column)
                    if(diag%code/=0) return
                    if(.not.refs(result_symbol)%array%flags(j)) then
                        call runtime_error('array function RESULT has uninitialized elements', &
                            prog%procedures(scope)%end_line,prog%procedures(scope)%end_column);return
                    end if
                    if(refs(result_symbol)%array%data(j)%tag/=prog%symbols(result_symbol)%typ.or. &
                       ((prog%symbols(result_symbol)%typ==ty_real.or.prog%symbols(result_symbol)%typ==ty_integer).and. &
                       refs(result_symbol)%array%data(j)%real_kind/=prog%symbols(result_symbol)%real_kind)) then
                        call runtime_error('array function RESULT element type/kind differs',0,0);return
                    end if
                end do
                ! Transfer ownership before this frame is released. Caller-side
                ! expression caches never borrow storage from a finished frame.
                if(prog%symbols(result_symbol)%typ==ty_character) then
                    procedure_array%character_len=len(refs(result_symbol)%value%s)
                end if
                procedure_array%lower_bound=refs(result_symbol)%array%lower_bound
                procedure_array%upper_bound=refs(result_symbol)%array%upper_bound
                procedure_array%lower_bound2=refs(result_symbol)%array%lower_bound2
                procedure_array%lower_bound3=refs(result_symbol)%array%lower_bound3
                procedure_array%upper_bound2=refs(result_symbol)%array%upper_bound2
                procedure_array%upper_bound3=refs(result_symbol)%array%upper_bound3
                call move_alloc(refs(result_symbol)%array%values,procedure_array%values)
                return
            end if
            if(.not.present(procedure_value)) then
                call runtime_error('scalar function invocation requires a scalar result',0,0);return
            end if
            if(.not.refs(result_symbol)%defined) then
                call runtime_error('function RESULT is uninitialized',prog%procedures(scope)%end_line, &
                                   prog%procedures(scope)%end_column); return
            end if
            if(is_derived_type(prog%symbols(result_symbol)%typ)) then
                if(.not.record_defined(refs(result_symbol)%value)) then
                    call runtime_error('function RESULT has uninitialized components',0,0);return
                end if
            end if
            procedure_value=refs(result_symbol)%value
        end if
    contains
        subroutine check_saved_initializer(s)
            integer,intent(in)::s
            type(value_t)::value
            type(diagnostic_t)::cache_diag
            logical::same
            integer::n
            associate(v=>prog%symbols(s))
            if(v%typ==ty_character.and.v%length_expr/=0) then
                call execute_program(prog,cache_diag,constant_index=v%length_expr,constant_value=value,budget_remaining=budget)
                if(cache_diag%code/=0) then
                    diag=cache_diag;return
                end if
                if(value%tag/=ty_integer.or.max(0_int64,value%i)/=int(v%character_len,int64)) then
                    call runtime_error('SAVE CHARACTER length cache differs',v%line,v%column);return
                end if
            end if
            ! Recompute constants independently, without entering any procedure.
            ! Share the root budget; recursive activations reuse the validated bank.
            call execute_program(prog,cache_diag,constant_index=v%initializer_expr,constant_value=value, &
                constant_type=v%typ,constant_real_kind=v%real_kind,budget_remaining=budget)
            if(cache_diag%code/=0) then
                diag=cache_diag;return
            end if
            same=value%tag==v%constant_value%tag.and.value%real_kind==v%constant_value%real_kind
            select case(v%typ)
            case(ty_integer);same=same.and.value%i==v%constant_value%i
            case(ty_real);same=same.and.value%r==v%constant_value%r
            case(ty_logical);same=same.and.(value%l.eqv.v%constant_value%l)
            case(ty_character)
                if(.not.allocated(value%s).or..not.allocated(v%constant_value%s)) then
                    same=.false.
                else
                    n=v%character_len
                    value%s=value%s(:min(n,len(value%s)))//repeat(' ',max(0,n-len(value%s)))
                    same=same.and.len(v%constant_value%s)==n.and.value%s==v%constant_value%s
                end if
            end select
            if(.not.same) call runtime_error('SAVE initializer cache differs',v%line,v%column)
            end associate
        end subroutine
        ! The execution-owned random stream and bounded read-only process queries
        ! are allowed in ordinary functions. Shared-storage writes use the stronger
        ! guard, including RANDOM_NUMBER harvests in module/SAVE/host storage.
        subroutine check_random_effect(lin,col,name)
            integer,intent(in)::lin,col
            character(*),intent(in)::name
            integer::q,f
            do q=1,size(stack)
                f=stack(q)
                if(f<1.or.f>prog%np) then
                    call runtime_error('invalid call stack',lin,col);return
                end if
                if(prog%procedures(f)%is_pure.or.prog%procedures(f)%is_simple) then
                    call runtime_error(name//' is forbidden in PURE or SIMPLE procedures',lin,col);return
                end if
            end do
        end subroutine
        subroutine check_external_effect(lin,col)
            integer,intent(in)::lin,col
            integer::q,f
            do q=1,size(stack)
                f=stack(q)
                if(f<1.or.f>prog%np) then
                    call runtime_error('invalid call stack',lin,col);return
                end if
                if(prog%procedures(f)%is_pure.or. &
                   (.not.prog%procedures(f)%is_subroutine.and..not.prog%procedures(f)%has_impure_prefix)) then
                    call runtime_error('external side effect inside an ordinary function or PURE procedure',lin,col);return
                end if
            end do
        end subroutine
        subroutine prepare_component_defaults()
            type(value_t)::value
            type(diagnostic_t)::constant_diag
            integer::t,j,root
            type(component_value_t)::packed
            component_defaults=component_value_t()
            do t=1,prog%nt
                do j=1,prog%derived_types(t)%ncomponents
                    if(prog%derived_types(t)%component_types(j)==ty_character) then
                        root=prog%derived_types(t)%component_length_exprs(j)
                        if(root/=0) then
                            call execute_program(prog,constant_diag,constant_index=root,constant_value=value, &
                                budget_remaining=budget)
                            if(constant_diag%code/=0) then
                                diag=constant_diag;return
                            end if
                            if(value%tag/=ty_integer.or.max(0_int64,value%i)/= &
                               int(prog%derived_types(t)%component_lengths(j),int64)) then
                                call runtime_error('CHARACTER component length cache differs',0,0);return
                            end if
                        end if
                    end if
                    root=prog%derived_types(t)%component_initializers(j)
                    if(root==0) cycle
                    call execute_program(prog,constant_diag,constant_index=root,constant_value=value, &
                        constant_type=prog%derived_types(t)%component_types(j), &
                        constant_real_kind=prog%derived_types(t)%component_kinds(j),budget_remaining=budget)
                    if(constant_diag%code/=0) then
                        diag=constant_diag;return
                    end if
                    packed=pack_component(value,t,j)
                    if(diag%code/=0) return
                    component_defaults(j,t)=packed
                end do
            end do
        end subroutine
        function pack_component(v,t,c) result(out)
            type(value_t),intent(in)::v
            integer,intent(in)::t,c
            type(component_value_t)::out
            integer::n
            out=component_value_t()
            if(v%tag/=prog%derived_types(t)%component_types(c).or. &
               v%real_kind/=prog%derived_types(t)%component_kinds(c)) then
                call runtime_error('component value type-kind differs from schema',0,0);return
            end if
            out=component_value_t(v%tag,v%real_kind,v%i,v%r,v%l)
            if(v%tag==ty_character) then
                n=prog%derived_types(t)%component_lengths(c)
                if(n<0.or.n>65536.or..not.allocated(v%s)) then
                    call runtime_error('invalid CHARACTER component value or length',0,0);return
                end if
                out%s=v%s(:min(n,len(v%s)))//repeat(' ',max(0,n-len(v%s)))
            end if
        end function
        subroutine initialize_record(v,typ)
            type(value_t),intent(out)::v
            integer,intent(in)::typ
            integer::t,n,j,stat
            t=typ-ty_derived_base
            if(.not.is_derived_type(typ).or.t>prog%nt) then
                call runtime_error('invalid derived type identity',0,0);return
            end if
            n=prog%derived_types(t)%ncomponents
            if(n<1.or.n>16) then
                call runtime_error('invalid derived component count',0,0);return
            end if
            v%tag=typ;allocate(v%record,stat=stat)
            if(stat==0) allocate(v%record%components(n),v%record%component_defined(n),stat=stat)
            if(stat/=0) then
                call runtime_error('derived record allocation failed',0,0);return
            end if
            v%record%component_defined=.false.
            do j=1,n
                v%record%components(j)%tag=prog%derived_types(t)%component_types(j)
                v%record%components(j)%real_kind=prog%derived_types(t)%component_kinds(j)
                if(prog%derived_types(t)%component_initializers(j)/=0) then
                    if(present(constant_index)) then
                        call runtime_error('Derived defaults in constant record evaluation are unsupported',0,0);return
                    end if
                    v%record%components(j)=component_defaults(j,t)
                    v%record%component_defined(j)=.true.
                end if
            end do
        end subroutine
        logical function record_defined(v) result(ok)
            type(value_t),intent(in)::v
            ok=.false.
            if(.not.allocated(v%record)) return
            if(.not.allocated(v%record%components).or..not.allocated(v%record%component_defined)) return
            if(size(v%record%components)/=size(v%record%component_defined)) return
            ok=all(v%record%component_defined)
        end function
        ! Each call freezes addresses, then stages values and its PRNG state.
        ! Empty harvests charge statement/descriptor work but draw no numbers.
        subroutine clear_expression_cache()
            integer::q
            shape_state=0
            do q=1,prog%ne
                if(allocated(expression_cache(q)%values)) deallocate(expression_cache(q)%values)
                expression_cache(q)%character_len=-1
                expression_cache(q)%gather_character_bytes=0_int64
            end do
            cached_elements=0_int64;cached_gather_character_bytes=0_int64
        end subroutine
        subroutine validate_while_condition(root)
            integer,intent(in)::root
            integer,allocatable::marks(:)
            integer::status
            allocate(marks(prog%ne),stat=status)
            if(status/=0) then
                call runtime_error('DO WHILE validation allocation failed',0,0);return
            end if
            marks=0
            call validate_while_tree(root,marks,0)
        end subroutine
        recursive subroutine validate_while_tree(root,marks,depth)
            integer,intent(in)::root,depth
            integer,intent(inout)::marks(:)
            integer::j,s,children(10)
            if(diag%code/=0) return
            if(.not.valid_expression(root)) return
            if(depth>256.or.marks(root)==1) then
                call runtime_error('cyclic or excessive DO WHILE condition',0,0);return
            end if
            if(marks(root)==2) return
            marks(root)=1
            associate(e=>prog%expressions(root))
            call consume(e%line,e%column)
            if(diag%code/=0) return
            if(e%rank==0.and.any(e%dims/=0)) then
                call runtime_error('invalid DO WHILE scalar shape metadata',e%line,e%column);return
            end if
            if(((e%typ==ty_logical.or.e%typ==ty_character).and.e%real_kind/=4).or. &
               ((e%typ==ty_integer.or.e%typ==ty_real).and.e%real_kind/=4.and.e%real_kind/=8)) then
                call runtime_error('invalid DO WHILE expression kind metadata',e%line,e%column);return
            end if
            if(e%typ/=ty_character.and.e%character_len/=-1) then
                call runtime_error('invalid DO WHILE expression length metadata',e%line,e%column);return
            end if
            if(e%kind==ex_literal) then
                call validate_while_value(e%value,e%typ,e%real_kind,e%character_len,e%line,e%column)
                if(diag%code/=0) return
            end if
            if(e%kind==ex_variable.or.e%kind==ex_element.or.e%kind==ex_section.or.e%kind==ex_gather_rows) then
                s=e%symbol
                if(.not.valid_symbol(s,allow_absent=.true.)) return
                if(e%typ/=prog%symbols(s)%typ.or.e%real_kind/=prog%symbols(s)%real_kind) then
                    call runtime_error('invalid DO WHILE symbol type metadata',e%line,e%column);return
                end if
                if(prog%symbols(s)%is_parameter.and.prog%symbols(s)%parameter_ready) then
                    if(prog%symbols(s)%rank==0) then
                        call validate_while_value(prog%symbols(s)%constant_value,e%typ,e%real_kind, &
                            prog%symbols(s)%character_len,e%line,e%column)
                    else if(allocated(prog%symbols(s)%constant_values)) then
                        do j=1,size(prog%symbols(s)%constant_values)
                            call consume(e%line,e%column)
                            if(diag%code/=0) return
                            call validate_while_value(prog%symbols(s)%constant_values(j),e%typ,e%real_kind, &
                                prog%symbols(s)%character_len,e%line,e%column)
                            if(diag%code/=0) return
                        end do
                    end if
                    if(diag%code/=0) return
                end if
            end if
            children=[e%left,e%right,e%stride,e%left2,e%right2,e%stride2,e%left3,e%right3,e%stride3,e%third]
            do j=1,size(children)
                if(children(j)==0) cycle
                call validate_while_tree(children(j),marks,depth+1)
                if(diag%code/=0) return
            end do
            if(allocated(e%args)) then
                do j=1,size(e%args)
                    if(e%args(j)==0) cycle
                    call validate_while_tree(e%args(j),marks,depth+1)
                    if(diag%code/=0) return
                end do
            end if
            end associate
            marks(root)=2
        end subroutine
        subroutine validate_while_value(v,typ,rk,clen,lin,col)
            type(value_t),intent(in)::v
            integer,intent(in)::typ,rk,clen,lin,col
            if(v%tag/=typ.or.v%real_kind/=rk) then
                call runtime_error('invalid DO WHILE cached value type metadata',lin,col);return
            end if
            if(typ==ty_character) then
                if(.not.allocated(v%s)) then
                    call runtime_error('missing DO WHILE cached CHARACTER payload',lin,col);return
                end if
                if(clen<0.or.len(v%s)/=clen) then
                    call runtime_error('invalid DO WHILE cached CHARACTER length',lin,col);return
                end if
            end if
            if(typ>=ty_integer.and.typ<=ty_character) then
                if(allocated(v%record).or.(typ/=ty_character.and.allocated(v%s))) then
                    call runtime_error('invalid DO WHILE cached value payload',lin,col);return
                end if
            end if
        end subroutine
        recursive subroutine validate_where_expression(root,depth)
            integer,intent(in)::root,depth
            integer::j,children(10),proc
            if(diag%code/=0) return
            if(.not.valid_expression(root)) return
            if(depth>256) then
                call runtime_error('WHERE expression nesting limit exceeded',0,0);return
            end if
            associate(e=>prog%expressions(root))
            call consume(e%line,e%column);if(diag%code/=0) return
            if(e%kind==ex_gather_rows) then
                call runtime_error('row gathering inside WHERE/FORALL is unsupported',e%line,e%column);return
            end if
            if(e%kind==ex_user_call) then
                proc=e%symbol
                if(proc<1.or.proc>prog%np) then
                    call runtime_error('invalid WHERE function reference',e%line,e%column);return
                end if
                if(.not.prog%procedures(proc)%is_pure) then
                    call runtime_error('WHERE expressions require PURE functions',e%line,e%column);return
                end if
            end if
            children=[e%left,e%right,e%stride,e%left2,e%right2,e%stride2,e%left3,e%right3,e%stride3,e%third]
            do j=1,size(children)
                if(children(j)==0) cycle
                call validate_where_expression(children(j),depth+1)
                if(diag%code/=0) return
            end do
            if(allocated(e%args)) then
                do j=1,size(e%args)
                    if(e%args(j)==0) cycle
                    call validate_where_expression(e%args(j),depth+1)
                    if(diag%code/=0) return
                end do
            end if
            end associate
        end subroutine
        subroutine execute_where(entry)
            integer,intent(in)::entry
            integer::arm,finish,k,j,n,s,mask,rank,target_rank,offset,ios
            integer(int64)::dims(3),target_dims(3),target_extent
            logical,allocatable::remaining(:),active(:)
            logical::final_else
            type(value_t)::v,scalar
            type(value_t),allocatable::values(:)
            finish=prog%code(entry)%target;mask=prog%code(entry)%a
            if(finish<=entry.or.finish>last_pc+1.or.prog%code(entry)%scope/=scope.or. &
               prog%code(entry)%c<0.or.prog%code(entry)%c>1.or.prog%code(entry)%d/=0) then
                call runtime_error('invalid WHERE instruction',prog%code(entry)%line,prog%code(entry)%column);return
            end if
            if(.not.valid_expression(mask)) return
            rank=prog%expressions(mask)%rank
            if(prog%expressions(mask)%typ/=ty_logical.or.rank<1.or.rank>2) then
                call runtime_error('WHERE mask must be a LOGICAL array',prog%code(entry)%line,prog%code(entry)%column);return
            end if
            ! Validate the complete instruction chain before any selected write.
            arm=entry;final_else=.false.
            do while(arm<finish)
                associate(header=>prog%code(arm))
                if(header%scope/=scope.or.header%target/=finish.or.header%b<=arm.or.header%b>finish) then
                    call runtime_error('invalid WHERE arm interval',header%line,header%column);return
                end if
                if(arm/=entry) then
                    if(header%op/=op_elsewhere.or.header%d/=entry.or.final_else.or.header%c/=0) then
                        call runtime_error('invalid ELSEWHERE chain',header%line,header%column);return
                    end if
                end if
                if(header%a==0) then
                    final_else=.true.
                else
                    call validate_where_expression(header%a,0)
                    if(diag%code/=0) return
                    if(prog%expressions(header%a)%typ/=ty_logical.or.prog%expressions(header%a)%rank/=rank) then
                        call runtime_error('WHERE mask ranks or types differ',header%line,header%column);return
                    end if
                end if
                do k=arm+1,header%b-1
                    associate(ins=>prog%code(k))
                    if(ins%op/=op_assign.or.ins%scope/=scope.or.ins%b/=0.or.ins%d/=0.or.ins%component/=0) then
                        call runtime_error('WHERE body requires whole-array or section assignments',ins%line,ins%column);return
                    end if
                    s=ins%symbol
                    if(.not.valid_symbol(s)) return
                    if(prog%symbols(s)%rank<1.or.prog%symbols(s)%is_parameter.or. &
                       (prog%symbols(s)%is_dummy.and.prog%symbols(s)%dummy_intent<=1).or.refs(s)%active) then
                        call runtime_error('invalid WHERE assignment target',ins%line,ins%column);return
                    end if
                    if(prog%symbols(s)%scope<0.or.prog%symbols(s)%is_saved.or.captured(s)) call check_external_effect(ins%line,ins%column)
                    if(diag%code/=0) return
                    target_rank=prog%symbols(s)%rank
                    if(ins%c/=0) then
                        call validate_where_expression(ins%c,0)
                        if(diag%code/=0) return
                        if(prog%expressions(ins%c)%kind/=ex_section.or.prog%expressions(ins%c)%symbol/=s) then
                            call runtime_error('invalid WHERE section target',ins%line,ins%column);return
                        end if
                        target_rank=prog%expressions(ins%c)%rank
                    end if
                    if(target_rank/=rank) then
                        call runtime_error('WHERE target rank differs from mask',ins%line,ins%column);return
                    end if
                    call validate_where_expression(ins%a,0)
                    if(diag%code/=0) return
                    if(prog%expressions(ins%a)%rank/=0.and.prog%expressions(ins%a)%rank/=rank) then
                        call runtime_error('WHERE expression rank differs from mask',ins%line,ins%column);return
                    end if
                    end associate
                end do
                arm=header%b
                end associate
            end do
            if(prog%code(entry)%c==1) then
                if(finish/=entry+2.or.prog%code(entry)%b/=finish) then
                    call runtime_error('invalid single-line WHERE body',prog%code(entry)%line,prog%code(entry)%column);return
                end if
            end if
            call prepare_expression(mask,0)
            if(diag%code/=0) return
            dims=shape_dims(:,mask);target_extent=shape_extent(mask)
            if(target_extent<0.or.target_extent>max_array_elements) then
                call runtime_error('WHERE mask element limit exceeded',prog%code(entry)%line,prog%code(entry)%column);return
            end if
            n=int(target_extent)
            allocate(remaining(n),active(n),stat=ios)
            if(ios/=0) then
                call runtime_error('WHERE mask temporary allocation failed',prog%code(entry)%line,prog%code(entry)%column);return
            end if
            remaining=.true.;arm=entry
            do while(arm<finish)
                associate(header=>prog%code(arm))
                if(arm/=entry) call clear_expression_cache()
                mask=header%a;active=.false.
                if(mask/=0) then
                    call prepare_expression(mask,0)
                    if(diag%code/=0) return
                    if(shape_extent(mask)/=n.or.any(shape_dims(:,mask)/=dims)) then
                        call runtime_error('ELSEWHERE mask shape differs from WHERE',header%line,header%column);return
                    end if
                end if
                do j=1,n
                    call consume(header%line,header%column);if(diag%code/=0) return
                    if(.not.remaining(j)) cycle
                    if(mask==0) then
                        active(j)=.true.
                    else
                        v=evaluate(mask,0,j);if(diag%code/=0) return
                        if(v%tag/=ty_logical) then
                            call runtime_error('WHERE mask value must be LOGICAL',header%line,header%column);return
                        end if
                        active(j)=v%l
                    end if
                end do
                remaining=remaining.and..not.active
                do k=arm+1,header%b-1
                    associate(ins=>prog%code(k))
                    call consume(ins%line,ins%column);if(diag%code/=0) return
                    call clear_expression_cache();s=ins%symbol
                    if(.not.array_available(s,ins%line,ins%column)) return
                    target_extent=size(refs(s)%array%data,kind=int64);target_dims=storage_dims(s)
                    if(ins%c/=0) then
                        call prepare_expression(ins%c,0);if(diag%code/=0) return
                        target_extent=shape_extent(ins%c);target_dims=shape_dims(:,ins%c)
                    end if
                    if(target_extent/=n.or.any(target_dims/=dims)) then
                        call runtime_error('WHERE target shape differs from mask',ins%line,ins%column);return
                    end if
                    if(prog%expressions(ins%a)%rank>0) then
                        call prepare_expression(ins%a,0);if(diag%code/=0) return
                        if(shape_extent(ins%a)/=n.or.any(shape_dims(:,ins%a)/=dims)) then
                            call runtime_error('WHERE expression shape differs from mask',ins%line,ins%column);return
                        end if
                    end if
                    ! Shape/descriptor checks still run for an all-false mask,
                    ! but scalar data and elemental RHS values are never read.
                    if(.not.any(active)) cycle
                    allocate(values(n),stat=ios)
                    if(ios/=0) then
                        call runtime_error('WHERE assignment temporary allocation failed',ins%line,ins%column);return
                    end if
                    if(prog%expressions(ins%a)%rank==0) then
                        scalar=evaluate(ins%a,0);if(diag%code/=0) return
                    end if
                    do j=1,n
                        call consume(ins%line,ins%column);if(diag%code/=0) return
                        if(.not.active(j)) cycle
                        if(prog%expressions(ins%a)%rank==0) then
                            v=scalar
                        else
                            v=evaluate(ins%a,0,j);if(diag%code/=0) return
                        end if
                        values(j)=convert(v,prog%symbols(s)%typ,ins%line,ins%column,prog%symbols(s)%real_kind)
                        if(diag%code/=0) return
                        if(prog%symbols(s)%typ==ty_character) call fit_character(values(j),s,ins%line,ins%column)
                        if(diag%code/=0) return
                    end do
                    ! Each assignment sees its own complete old target. Later
                    ! assignments see the earlier committed values, frozen mask.
                    do j=1,n
                        if(.not.active(j)) cycle
                        offset=j
                        if(ins%c/=0) offset=section_offset(ins%c,j)
                        if(diag%code/=0) return
                        refs(s)%array%data(offset)=values(j);refs(s)%array%flags(offset)=.true.
                    end do
                    deallocate(values)
                    end associate
                end do
                arm=header%b
                end associate
            end do
        end subroutine
        recursive subroutine validate_forall_expression(root,indices,header,depth)
            integer,intent(in)::root,indices(2),depth
            logical,intent(in)::header
            integer::q,children(10),proc
            if(diag%code/=0) return
            if(.not.valid_expression(root)) return
            if(depth>256) then
                call runtime_error('FORALL expression nesting limit exceeded',0,0);return
            end if
            associate(e=>prog%expressions(root))
            call consume(e%line,e%column);if(diag%code/=0) return
            if(e%kind==ex_gather_rows) then
                call runtime_error('row gathering inside WHERE/FORALL is unsupported',e%line,e%column);return
            end if
            if(header.and.e%kind==ex_variable) then
                if(any(indices==e%symbol)) then
                    call runtime_error('FORALL bounds cannot reference an index in the same header',e%line,e%column);return
                end if
            end if
            if(e%kind==ex_user_call) then
                proc=e%symbol
                if(proc<1.or.proc>prog%np) then
                    call runtime_error('invalid FORALL function reference',e%line,e%column);return
                end if
                if(.not.prog%procedures(proc)%is_pure) then
                    call runtime_error('FORALL expressions require PURE functions',e%line,e%column);return
                end if
            end if
            children=[e%left,e%right,e%stride,e%left2,e%right2,e%stride2, &
                        e%left3,e%right3,e%stride3,e%third]
            do q=1,size(children)
                if(children(q)==0) cycle
                call validate_forall_expression(children(q),indices,header,depth+1)
                if(diag%code/=0) return
            end do
            if(allocated(e%args)) then
                do q=1,size(e%args)
                    if(e%args(q)==0) cycle
                    call validate_forall_expression(e%args(q),indices,header,depth+1)
                    if(diag%code/=0) return
                end do
            end if
            end associate
        end subroutine
        subroutine execute_forall(entry)
            integer,intent(in)::entry
            type(value_t)::saved(2)
            logical::saved_defined(2),saved_active(2)
            integer::n,q,s,k,h,root,indices(2)
            indices=0
            if(.not.allocated(prog%code(entry)%items)) then
                call runtime_error('FORALL header storage missing',prog%code(entry)%line,prog%code(entry)%column);return
            end if
            n=size(prog%code(entry)%items)/4
            if(n<1.or.n>2.or.size(prog%code(entry)%items)/=4*n.or. &
               prog%code(entry)%target<=entry.or.prog%code(entry)%target>last_pc+1) then
                call runtime_error('invalid FORALL instruction',prog%code(entry)%line,prog%code(entry)%column);return
            end if
            do q=1,n
                s=prog%code(entry)%items(4*q-3)
                if(.not.valid_symbol(s)) return
                if(prog%symbols(s)%scope/=scope.or.prog%symbols(s)%rank/=0.or. &
                   prog%symbols(s)%typ/=ty_integer.or.prog%symbols(s)%is_dummy.or. &
                   prog%symbols(s)%is_parameter.or.refs(s)%active) then
                    call runtime_error('invalid FORALL index variable',prog%code(entry)%line,prog%code(entry)%column);return
                end if
                if(q==2) then
                    if(s==prog%code(entry)%items(1)) then
                        call runtime_error('duplicate FORALL index',prog%code(entry)%line,prog%code(entry)%column);return
                    end if
                end if
                if(prog%symbols(s)%real_kind/=4.and.prog%symbols(s)%real_kind/=8) then
                    call runtime_error('unsupported FORALL index kind',prog%code(entry)%line,prog%code(entry)%column);return
                end if
                indices(q)=s
                saved(q)=refs(s)%value;saved_defined(q)=refs(s)%defined;saved_active(q)=refs(s)%active
            end do
            do q=1,n
                do h=2,4
                    root=prog%code(entry)%items(4*(q-1)+h)
                    if(h==4.and.root==0) cycle
                    call validate_forall_expression(root,indices,.true.,0)
                    if(diag%code/=0) return
                    if(prog%expressions(root)%rank/=0.or.prog%expressions(root)%typ/=ty_integer) then
                        call runtime_error('FORALL bounds must be scalar INTEGER',0,0);return
                    end if
                end do
            end do
            if(prog%code(entry)%a/=0) then
                root=prog%code(entry)%a
                call validate_forall_expression(root,indices,.false.,0)
                if(diag%code/=0) return
                if(prog%expressions(root)%rank/=0.or.prog%expressions(root)%typ/=ty_logical) then
                    call runtime_error('FORALL mask must be scalar LOGICAL',0,0);return
                end if
            end if
            do k=entry+1,prog%code(entry)%target-1
                if(prog%code(k)%op/=op_assign.or.prog%code(k)%scope/=scope) then
                    call runtime_error('FORALL body requires assignments',prog%code(k)%line,prog%code(k)%column);return
                end if
                call validate_forall_expression(prog%code(k)%a,indices,.false.,0)
                if(prog%code(k)%b/=0) call validate_forall_expression(prog%code(k)%b,indices,.false.,0)
                if(prog%code(k)%c/=0) call validate_forall_expression(prog%code(k)%c,indices,.false.,0)
                if(prog%code(k)%d/=0) call validate_forall_expression(prog%code(k)%d,indices,.false.,0)
                if(diag%code/=0) return
            end do
            call execute_forall_body(entry,n)
            ! FORALL indices have construct-local values, even when their outer
            ! declarations were undefined. Restore on success and on failure.
            do q=1,n
                s=prog%code(entry)%items(4*q-3)
                refs(s)%value=saved(q);refs(s)%defined=saved_defined(q);refs(s)%active=saved_active(q)
            end do
            call clear_expression_cache()
        end subroutine
        subroutine execute_forall_body(entry,n)
            integer,intent(in)::entry,n
            integer(int64),allocatable::index_values(:,:)
            logical,allocatable::mask(:),written(:)
            type(value_t),allocatable::pending(:)
            integer,allocatable::destinations(:)
            integer::counts(2),indices(2),q,h,t,u,s,root,lin,col,nsaved,off,rank,stat,jj,nb
            integer(int64)::lo,hi,step,current,total,nvalues,tdims(3),starts(2),strides(2)
            type(value_t)::v,first_value,last_value,step_value,sub1,sub2
            lin=prog%code(entry)%line;col=prog%code(entry)%column
            ! Count validated sequences before reserving their actual extent.
            ! A large configured cap must not reserve cap-sized scratch storage
            ! for a tiny FORALL, including an empty Cartesian product.
            counts=1;indices=0;starts=0_int64;strides=0_int64
            do q=1,n
                h=4*(q-1);s=prog%code(entry)%items(h+1);indices(q)=s
                first_value=evaluate(prog%code(entry)%items(h+2),0)
                last_value=evaluate(prog%code(entry)%items(h+3),0)
                step_value=value_t(tag=ty_integer,i=1_int64)
                if(prog%code(entry)%items(h+4)/=0) step_value=evaluate(prog%code(entry)%items(h+4),0)
                if(diag%code/=0) return
                if(first_value%tag/=ty_integer.or.last_value%tag/=ty_integer.or.step_value%tag/=ty_integer) then
                    call runtime_error('FORALL bounds and stride must be scalar INTEGER',lin,col);return
                end if
                lo=first_value%i;hi=last_value%i;step=step_value%i
                if(.not.check_integer(lo,lin,col,prog%symbols(s)%real_kind).or. &
                   .not.check_integer(hi,lin,col,prog%symbols(s)%real_kind).or. &
                   .not.check_integer(step,lin,col,prog%symbols(s)%real_kind)) return
                if(step==0_int64) then
                    call runtime_error('FORALL stride is zero',lin,col);return
                end if
                counts(q)=0;current=lo;starts(q)=lo;strides(q)=step
                do
                    if((step>0.and.current>hi).or.(step<0.and.current<hi)) exit
                    if(counts(q)==max_array_elements) then
                        call runtime_error('FORALL iteration limit exceeded',lin,col);return
                    end if
                    call consume(lin,col);if(diag%code/=0) return
                    counts(q)=counts(q)+1
                    ! No terminal increment belongs to FORALL. Stop safely when
                    ! the next mathematical index exceeds the integer model.
                    if(step>0) then
                        if(current>huge(current)-step) exit
                    else
                        if(current<(-huge(current)-1_int64)-step) exit
                    end if
                    current=current+step
                end do
            end do
            total=int(counts(1),int64)*int(counts(2),int64)
            if(total>max_array_elements) then
                call runtime_error('FORALL iteration limit exceeded',lin,col);return
            end if
            allocate(index_values(2,merge(maxval(counts),0,total>0)),mask(int(total)),stat=stat)
            if(stat/=0) then
                call runtime_error('FORALL index/mask allocation failed',lin,col);return
            end if
            index_values=0_int64
            if(total>0) then
                do q=1,n
                    current=starts(q)
                    do t=1,counts(q)
                        index_values(q,t)=current
                        if(t<counts(q)) current=current+strides(q)
                    end do
                end do
            end if
            do q=1,n
                refs(indices(q))%active=.true.
            end do
            do t=1,int(total)
                call set_forall_indices(t,n,indices,counts,index_values)
                call clear_expression_cache();call consume(lin,col)
                if(diag%code/=0) return
                mask(t)=.true.
                if(prog%code(entry)%a/=0) then
                    v=evaluate(prog%code(entry)%a,0)
                    if(diag%code/=0) return
                    if(v%tag/=ty_logical) then
                        call runtime_error('FORALL mask must be scalar LOGICAL',lin,col);return
                    end if
                    mask(t)=v%l
                end if
            end do
            do jj=entry+1,prog%code(entry)%target-1
                associate(ins=>prog%code(jj))
                lin=ins%line;col=ins%column;s=ins%symbol
                if(ins%op/=op_assign.or.ins%scope/=scope) then
                    call runtime_error('FORALL body requires assignments',lin,col);return
                end if
                if(.not.valid_symbol(s)) return
                if(prog%symbols(s)%rank<1.or.prog%symbols(s)%is_parameter.or. &
                   prog%symbols(s)%dummy_intent==1.or.ins%component/=0.or. &
                   (ins%b==0.and.ins%c==0)) then
                    call runtime_error('FORALL target must be a writable array element or section',lin,col);return
                end if
                if(prog%symbols(s)%scope<0.or.prog%symbols(s)%is_saved.or.captured(s)) call check_external_effect(lin,col)
                if(diag%code/=0) return
                ! A completely masked/empty assignment does not reference its
                ! target or RHS (in particular, unallocated storage is harmless).
                if(.not.any(mask)) cycle
                if(.not.array_available(s,lin,col)) return
                nb=size(refs(s)%array%data)
                allocate(pending(nb),destinations(nb),written(nb),stat=stat)
                if(stat/=0) then
                    call runtime_error('FORALL temporary allocation failed',lin,col);return
                end if
                written=.false.;nsaved=0
                do t=1,int(total)
                    if(.not.mask(t)) cycle
                    call set_forall_indices(t,n,indices,counts,index_values)
                    call clear_expression_cache();call consume(lin,col)
                    if(diag%code/=0) return
                    rank=0;nvalues=1_int64;tdims=0_int64;off=0
                    if(ins%c/=0) then
                        if(ins%b/=0.or.ins%d/=0.or.ins%third/=0) then
                            call runtime_error('invalid FORALL section target',lin,col);return
                        end if
                        if(.not.valid_expression(ins%c)) return
                        if(prog%expressions(ins%c)%kind/=ex_section.or.prog%expressions(ins%c)%symbol/=s) then
                            call runtime_error('invalid FORALL section target',lin,col);return
                        end if
                        call prepare_expression(ins%c,0)
                        if(diag%code/=0) return
                        rank=prog%expressions(ins%c)%rank;nvalues=shape_extent(ins%c);tdims=shape_dims(:,ins%c)
                    else
                        off=element_expression_offset(s,ins%b,ins%d,ins%third,0,lin,col)
                        if(diag%code/=0) return
                    end if
                    root=ins%a
                    if(.not.valid_expression(root)) return
                    call prepare_expression(root,0)
                    if(diag%code/=0) return
                    if(prog%expressions(root)%rank/=0) then
                        if(prog%expressions(root)%rank/=rank.or.shape_extent(root)/=nvalues.or. &
                           any(shape_dims(:,root)/=tdims)) then
                            call runtime_error('FORALL array assignment shapes do not conform',lin,col);return
                        end if
                    else
                        v=evaluate(root,0)
                        if(diag%code/=0) return
                        v=convert(v,prog%symbols(s)%typ,lin,col,prog%symbols(s)%real_kind)
                        if(diag%code/=0) return
                        if(prog%symbols(s)%typ==ty_character) call fit_character(v,s,lin,col)
                        if(diag%code/=0) return
                    end if
                    do u=1,int(nvalues)
                        call consume(lin,col);if(diag%code/=0) return
                        if(ins%c/=0) off=section_offset(ins%c,u)
                        if(diag%code/=0) return
                        if(off<1.or.off>nb) then
                            call runtime_error('FORALL destination is out of bounds',lin,col);return
                        end if
                        if(written(off)) then
                            call runtime_error('FORALL assignment defines an element more than once',lin,col);return
                        end if
                        written(off)=.true.;nsaved=nsaved+1;destinations(nsaved)=off
                        if(prog%expressions(root)%rank>0) then
                            v=evaluate(root,0,u)
                            if(diag%code/=0) return
                            v=convert(v,prog%symbols(s)%typ,lin,col,prog%symbols(s)%real_kind)
                            if(diag%code/=0) return
                            if(prog%symbols(s)%typ==ty_character) call fit_character(v,s,lin,col)
                            if(diag%code/=0) return
                        end if
                        pending(nsaved)=v
                    end do
                end do
                ! Each body statement completes over every active tuple before
                ! the next statement begins; both LHS mapping and RHS use old data.
                do u=1,nsaved
                    off=destinations(u)
                    refs(s)%array%data(off)=pending(u);refs(s)%array%flags(off)=.true.
                end do
                deallocate(pending,destinations,written)
                end associate
            end do
        end subroutine
        subroutine set_forall_indices(t,n,indices,counts,index_values)
            integer,intent(in)::t,n,indices(2),counts(2)
            integer(int64),intent(in)::index_values(:,:)
            integer::q,pos(2),s
            pos=[mod(t-1,counts(1))+1,(t-1)/counts(1)+1]
            do q=1,n
                s=indices(q)
                refs(s)%value=value_t(tag=ty_integer,real_kind=prog%symbols(s)%real_kind,i=index_values(q,pos(q)))
                refs(s)%defined=.true.
            end do
        end subroutine
        recursive subroutine fill_random(sym,index,lin,col)
            integer,intent(in)::sym,index,lin,col
            integer(int64)::saved_state
            saved_state=rng
            call fill_random_impl(sym,index,lin,col)
            if(diag%code/=0) rng=saved_state
        end subroutine
        recursive subroutine fill_random_impl(sym,index,lin,col)
            integer,intent(in)::sym,index,lin,col
            integer::n,j,off,ios
            integer,allocatable::offsets(:)
            type(value_t),allocatable::values(:)
            type(value_t)::x,y
            integer(int64)::state
            if(.not.valid_symbol(sym)) return
            if(.not.valid_expression(index)) return
            if(scope/=0) then
                if(prog%procedures(scope)%is_pure.or.prog%procedures(scope)%is_simple) then
                    call runtime_error('RANDOM_NUMBER is forbidden in PURE procedures',lin,col);return
                end if
            end if
            associate(e=>prog%expressions(index),v=>prog%symbols(sym))
            if(e%symbol/=sym.or.e%parenthesized.or.e%typ/=ty_real.or.v%typ/=ty_real.or. &
                e%real_kind/=v%real_kind.or.(v%real_kind/=4.and.v%real_kind/=8).or. &
                e%rank<0.or.e%rank>3.or.v%rank<0.or.v%rank>3) then
                call runtime_error('invalid RANDOM_NUMBER harvest',lin,col);return
            end if
            if(v%is_parameter.or.refs(sym)%active.or.(v%is_dummy.and.v%dummy_intent<=1)) then
                call runtime_error('RANDOM_NUMBER harvest is not writable',lin,col);return
            end if
            n=1;off=0
            select case(e%kind)
            case(ex_variable)
                if(e%rank/=v%rank) then
                    call runtime_error('RANDOM_NUMBER harvest rank mismatch',lin,col);return
                end if
                call prepare_expression(index,0)
                if(diag%code/=0) return
                if(e%rank>0) n=int(shape_extent(index))
            case(ex_element)
                if(e%rank/=0.or.v%rank==0) then
                    call runtime_error('invalid RANDOM_NUMBER element harvest',lin,col);return
                end if
                if(.not.valid_expression(e%left)) return
                if(prog%expressions(e%left)%rank/=0.or.prog%expressions(e%left)%typ/=ty_integer) then
                    call runtime_error('invalid RANDOM_NUMBER subscript',lin,col);return
                end if
                off=element_expression_offset(sym,e%left,e%right,e%third,0,lin,col)
                if(diag%code/=0) return
            case(ex_section)
                call prepare_expression(index,0)
                if(diag%code/=0) return
                n=int(shape_extent(index))
            case default
                call runtime_error('RANDOM_NUMBER requires a variable harvest',lin,col);return
            end select
            if(n<0.or.n>max_array_elements) then
                call runtime_error('RANDOM_NUMBER element limit exceeded',lin,col);return
            end if
            allocate(offsets(n),values(n),stat=ios)
            if(ios/=0) then
                call runtime_error('RANDOM_NUMBER staging allocation failed',lin,col);return
            end if
            state=rng
            do j=1,n
                call consume(lin,col)
                if(diag%code/=0) return
                offsets(j)=off
                if(e%rank>0) offsets(j)=j
                if(e%kind==ex_section) offsets(j)=section_offset(index,j)
                state=modulo(16807_int64*state,2147483647_int64)
                values(j)%tag=ty_real;values(j)%real_kind=v%real_kind
                values(j)%r=real(state,real64)/2147483647.0_real64
                if(v%real_kind==4) values(j)%r=real(min(real(values(j)%r,real32), &
                    nearest(1.0_real32,-1.0_real32)),real64)
            end do
            do j=1,n
                off=offsets(j)
                if(off==0) then
                    refs(sym)%value=values(j);refs(sym)%defined=.true.
                else
                    refs(sym)%array%data(off)=values(j);refs(sym)%array%flags(off)=.true.
                end if
            end do
            rng=state
            end associate
        end subroutine
        ! Validate the new type-spec even on zero-trip and unevaluated KIND
        ! paths. No data values are read, and selector evaluation is constant-only.
        subroutine validate_empty_constructor(index)
            integer,intent(in)::index
            integer::child,k
            type(value_t)::v
            type(diagnostic_t)::d
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('constructor arguments missing',e%line,e%column);return
            end if
            if(e%op/='integer'.and.e%op/='real'.and.e%op/='logical') then
                if(e%constructor_kind_expr/=0.or.(len_trim(e%op)>0.and.e%op/='character').or. &
                   (e%op=='character'.and.e%typ/=ty_character).or. &
                   (size(e%args)==0.and.e%op/='character')) &
                    call runtime_error('invalid constructor type marker',e%line,e%column)
                return
            end if
            if(size(e%args)/=0.or.e%rank/=1.or.e%extent/=0.or.any(e%dims/=0).or. &
               e%character_len/=-1.or.e%length_expr/=0.or.e%left/=0.or.e%right/=0.or. &
               e%symbol/=0.or.e%stride/=0.or.e%left2/=0.or.e%right2/=0.or.e%stride2/=0.or. &
               e%left3/=0.or.e%right3/=0.or.e%stride3/=0.or.e%third/=0.or. &
               e%generic_id/=0.or.e%bound_type/=0.or.e%bound_binding/=0.or.e%intrinsic_mask/=0.or. &
               .not.e%triplet(1).or.any(e%triplet(2:))) then
                call runtime_error('invalid typed empty constructor metadata',e%line,e%column);return
            end if
            if((e%op=='integer'.and.e%typ/=ty_integer).or. &
               (e%op=='real'.and.e%typ/=ty_real).or.(e%op=='logical'.and.e%typ/=ty_logical)) then
                call runtime_error('typed empty constructor type differs',e%line,e%column);return
            end if
            k=4;child=e%constructor_kind_expr
            if(child/=0) then
                if(.not.valid_expression(child))return
                if(e%typ==ty_logical.or.child==index.or.prog%expressions(child)%rank/=0.or. &
                   (prog%expressions(child)%kind/=ex_literal.and.prog%expressions(child)%kind/=ex_variable).or. &
                   prog%expressions(child)%typ/=ty_integer.or..not.bound_constant_expression(prog,child,0)) then
                    call runtime_error('invalid empty constructor KIND selector',e%line,e%column);return
                end if
                call evaluate_constant(prog,child,v,d)
                if(d%code/=0.or.v%tag/=ty_integer) then
                    call runtime_error('invalid constant empty constructor KIND',e%line,e%column);return
                end if
                if(v%i/=4.and.v%i/=8) then
                    call runtime_error('unsupported empty constructor KIND',e%line,e%column);return
                end if
                k=int(v%i)
            end if
            if(e%real_kind/=k) call runtime_error('empty constructor KIND cache differs',e%line,e%column)
            end associate
        end subroutine
        ! KIND needs declared type, never values or runtime section bounds. Walk
        ! only IR structure to reject forged references and cycles safely.
        recursive subroutine validate_kind_tree(index,marks,depth,derived_actual,character_actual)
            integer,intent(in)::index,depth
            integer,intent(inout)::marks(:)
            logical,intent(in),optional::derived_actual,character_actual
            integer::s,j,proc,result,dummy,child,r,children(10),n,t,c
            logical::permit_derived,child_derived,permit_component,child_context
            if(diag%code/=0) return
            if(.not.valid_expression(index)) return
            if(depth>512.or.marks(index)==1) then
                call runtime_error('cyclic or excessive KIND argument structure',0,0);return
            end if
            associate(a=>prog%expressions(index))
            permit_component=.false.
            if(present(character_actual)) permit_component=character_actual
            permit_derived=.false.
            if(present(derived_actual)) permit_derived=derived_actual.and.permit_component
            if(a%kind==ex_component.and..not.permit_component.and.a%typ/=ty_character) then
                call runtime_error('invalid KIND argument opcode',a%line,a%column);return
            end if
            if(is_derived_type(a%typ).and.permit_derived) then
                ! A CHARACTER function may take a scalar derived actual. Its
                ! declared result length does not read that object's values.
                ! This permission is local to function actuals/component bases,
                ! never to the root operand of an intrinsic KIND inquiry.
                t=a%typ-ty_derived_base
                if(a%rank/=0.or.a%extent/=0.or.any(a%dims/=0).or.a%real_kind/=4.or. &
                   a%character_len/=-1.or.(a%kind/=ex_variable.and.a%kind/=ex_record.and.a%kind/=ex_user_call)) then
                    call runtime_error('invalid KIND derived actual metadata',a%line,a%column);return
                end if
                if(.not.valid_component_defaults(prog,t)) then
                    call runtime_error('invalid KIND derived type metadata',a%line,a%column);return
                end if
                do j=1,prog%derived_types(t)%ncomponents
                    c=prog%derived_types(t)%component_types(j)
                    r=prog%derived_types(t)%component_kinds(j)
                    if(c<ty_integer.or.c>ty_character.or.(r/=4.and.r/=8).or. &
                       ((c==ty_logical.or.c==ty_character).and.r/=4)) then
                        call runtime_error('invalid KIND derived component metadata',a%line,a%column);return
                    end if
                end do
            else if(a%typ<ty_integer.or.a%typ>ty_character.or. &
               ((a%typ==ty_real.or.a%typ==ty_integer).and.a%real_kind/=4.and.a%real_kind/=8)) then
                call runtime_error('invalid KIND argument type metadata',a%line,a%column);return
            end if
            ! A node checked in the permissive function-actual context must
            ! be rechecked if later reached through a restrictive inquiry DAG.
            if(marks(index)==2.or.(marks(index)==3.and.permit_component)) return
            marks(index)=1
            call consume(a%line,a%column)
            if(diag%code/=0) return
            n=0;children=0
            select case(a%kind)
            case(ex_constructor_index)
                if(.not.valid_constructor_index(prog,index)) then
                    call runtime_error('invalid KIND constructor index',a%line,a%column);return
                end if
            case(ex_constructor_do)
                if(.not.allocated(a%args).or.a%rank/=1.or.a%extent/=-1_int64) then
                    call runtime_error('invalid KIND constructor implied-DO',a%line,a%column);return
                end if
                n=3;children(:3)=[a%left,a%right,a%stride]
                do j=1,size(a%args)
                    call validate_kind_tree(a%args(j),marks,depth+1,character_actual=permit_component)
                    if(diag%code/=0) return
                end do
            case(ex_literal)
                if(a%value%tag/=a%typ.or.((a%typ==ty_real.or.a%typ==ty_integer).and.a%value%real_kind/=a%real_kind)) then
                    call runtime_error('invalid KIND literal type metadata',a%line,a%column);return
                end if
            case(ex_record)
                if(.not.is_derived_type(a%typ).or..not.allocated(a%args)) then
                    call runtime_error('invalid KIND structure constructor metadata',a%line,a%column);return
                end if
                t=a%typ-ty_derived_base
                if(size(a%args)>prog%derived_types(t)%ncomponents) then
                    call runtime_error('invalid KIND structure component count',a%line,a%column);return
                end if
                do j=size(a%args)+1,prog%derived_types(t)%ncomponents
                    if(prog%derived_types(t)%component_initializers(j)==0) then
                        call runtime_error('missing KIND structure component without default',a%line,a%column);return
                    end if
                end do
                do j=1,size(a%args)
                    child=a%args(j)
                    call validate_kind_tree(child,marks,depth+1,character_actual=permit_component)
                    if(diag%code/=0) return
                    c=prog%derived_types(t)%component_types(j)
                    associate(x=>prog%expressions(child))
                    if(x%rank/=0.or.(c==ty_logical.neqv.x%typ==ty_logical).or. &
                       (c==ty_character.neqv.x%typ==ty_character).or.x%typ<ty_integer.or.x%typ>ty_character) then
                        call runtime_error('invalid KIND structure component argument',a%line,a%column);return
                    end if
                    end associate
                end do
            case(ex_component)
                child=a%left
                if(.not.valid_expression(child)) return
                if(prog%expressions(child)%kind/=ex_variable.or..not.is_derived_type(prog%expressions(child)%typ)) then
                    call runtime_error('invalid KIND component base',a%line,a%column);return
                end if
                call validate_kind_tree(child,marks,depth+1,.true.,.true.)
                if(diag%code/=0) return
                t=prog%expressions(child)%typ-ty_derived_base;c=a%symbol
                if(c<1.or.c>prog%derived_types(t)%ncomponents) then
                    call runtime_error('invalid KIND component reference',a%line,a%column);return
                end if
                if(a%typ/=prog%derived_types(t)%component_types(c).or. &
                   a%real_kind/=prog%derived_types(t)%component_kinds(c).or. &
                   a%rank/=0.or.a%extent/=0.or.any(a%dims/=0).or. &
                   a%character_len/=prog%derived_types(t)%component_lengths(c)) then
                    call runtime_error('invalid KIND component type metadata',a%line,a%column);return
                end if
            case(ex_gather_rows)
                call validate_row_gather(index,.true.,vector=children(1))
                if(diag%code/=0) return
                n=1
            case(ex_substring)
                call validate_substring(index,.true.)
                if(diag%code/=0) return
                n=3;children(:3)=[a%left,a%right,a%third]
            case(ex_variable,ex_element,ex_section)
                s=a%symbol
                if(.not.valid_symbol(s,allow_absent=.true.)) return
                if(a%typ/=prog%symbols(s)%typ.or. &
                   ((a%typ==ty_real.or.a%typ==ty_integer).and.a%real_kind/=prog%symbols(s)%real_kind)) then
                    call runtime_error('KIND argument type differs from symbol',a%line,a%column);return
                end if
                r=prog%symbols(s)%rank
                if(r<0.or.r>3) then
                    call runtime_error('invalid KIND symbol rank',a%line,a%column);return
                end if
                if(a%kind==ex_variable) then
                    if(a%rank/=r) then
                        call runtime_error('KIND argument rank differs from symbol',a%line,a%column);return
                    end if
                else if(a%kind==ex_element) then
                    if(a%rank/=0.or.r==0.or.a%left==0.or.(r>=2.eqv.a%right==0).or.(r==3.eqv.a%third==0)) then
                        call runtime_error('invalid KIND element structure',a%line,a%column);return
                    end if
                    n=r;children(1:3)=[a%left,a%right,a%third]
                else
                    if(r==0.or.a%rank<1.or.a%extent/=-1_int64) then
                        call runtime_error('invalid KIND section structure',a%line,a%column);return
                    end if
                    if(a%rank/=sum(merge(1,0,a%triplet(:r)))) then
                        call runtime_error('invalid KIND section rank',a%line,a%column);return
                    end if
                    n=3*r;children=[a%left,a%right,a%stride,a%left2,a%right2,a%stride2, &
                        a%left3,a%right3,a%stride3,a%third]
                    do j=1,r
                        if(a%triplet(j)) cycle
                        if(children(3*j-2)==0.or.any(children(3*j-1:3*j)/=0)) then
                            call runtime_error('invalid KIND scalar section subscript',a%line,a%column);return
                        end if
                    end do
                    if(r<3.and.(a%triplet(3).or.any(children(7:)/=0))) then
                        call runtime_error('invalid KIND third section dimension',a%line,a%column);return
                    end if
                    if(r==1.and.(a%triplet(2).or.any(children(4:)/=0))) then
                        call runtime_error('invalid KIND second section dimension',a%line,a%column);return
                    end if
                end if
                do j=1,n
                    child=children(j)
                    if(child==0) cycle
                    if(.not.valid_expression(child)) return
                    if(prog%expressions(child)%typ/=ty_integer.or.prog%expressions(child)%rank/=0) then
                        call runtime_error('invalid KIND subscript type',a%line,a%column);return
                    end if
                end do
            case(ex_unary)
                n=1;children(1)=a%left
                if(a%op/='+'.and.a%op/='-'.and.a%op/='.not.') then
                    call runtime_error('invalid KIND unary operator',a%line,a%column);return
                end if
            case(ex_binary)
                n=2;children(:2)=[a%left,a%right]
                select case(a%op)
                case('+','-','*','/','**','//','==','/=','<','<=','>','>=', &
                     '.eq.','.ne.','.lt.','.le.','.gt.','.ge.','.and.','.or.','.eqv.','.neqv.')
                case default
                    call runtime_error('invalid KIND binary operator',a%line,a%column);return
                end select
            case(ex_call,ex_user_call,ex_constructor)
                if(.not.allocated(a%args)) then
                    call runtime_error('missing KIND child arguments',a%line,a%column);return
                end if
                if(size(a%args)>max_expressions) then
                    call runtime_error('excessive KIND child arguments',a%line,a%column);return
                end if
                if(a%kind==ex_user_call) then
                    proc=a%symbol
                    if(proc<1.or.proc>prog%np) then
                        call runtime_error('invalid KIND procedure reference',a%line,a%column);return
                    end if
                    if(prog%procedures(proc)%is_subroutine.or..not.allocated(prog%procedures(proc)%args)) then
                        call runtime_error('invalid KIND function metadata',a%line,a%column);return
                    end if
                    if(size(a%args)/=size(prog%procedures(proc)%args)) then
                        call runtime_error('invalid KIND function argument count',a%line,a%column);return
                    end if
                    if(a%bound_type/=0.or.a%bound_binding/=0) then
                        t=a%bound_type;c=a%bound_binding
                        if(t<1.or.t>prog%nt.or.t>max_types) then
                            call runtime_error('invalid KIND bound type identity',a%line,a%column);return
                        end if
                        if(c<1.or.c>prog%derived_types(t)%nbindings.or.c>16) then
                            call runtime_error('invalid KIND binding identity',a%line,a%column);return
                        end if
                        if(prog%derived_types(t)%binding_procedures(c)/=proc) then
                            call runtime_error('KIND binding procedure differs',a%line,a%column);return
                        end if
                        if(size(a%args)<1) then
                            call runtime_error('missing KIND bound receiver',a%line,a%column);return
                        end if
                        child=a%args(1)
                        if(.not.valid_expression(child)) return
                        associate(receiver=>prog%expressions(child))
                        s=receiver%symbol
                        if(receiver%kind/=ex_variable.or.receiver%typ/=ty_derived_base+t.or. &
                           receiver%rank/=0.or.receiver%extent/=0.or.any(receiver%dims/=0)) then
                            call runtime_error('invalid KIND bound receiver metadata',a%line,a%column);return
                        end if
                        if(.not.valid_symbol(s,allow_absent=.true.)) return
                        if(prog%symbols(s)%typ/=ty_derived_base+t.or.prog%symbols(s)%rank/=0) then
                            call runtime_error('KIND bound receiver declaration differs',a%line,a%column);return
                        end if
                        end associate
                        dummy=prog%procedures(proc)%args(1)
                        if(dummy<1.or.dummy>prog%ns) then
                            call runtime_error('invalid KIND passed-object dummy',a%line,a%column);return
                        end if
                        if(prog%symbols(dummy)%typ/=ty_derived_base+t.or.prog%symbols(dummy)%rank/=0.or. &
                           .not.prog%symbols(dummy)%is_dummy.or.prog%symbols(dummy)%scope/=proc) then
                            call runtime_error('KIND passed-object declaration differs',a%line,a%column);return
                        end if
                    end if
                    result=prog%procedures(proc)%result_symbol
                    if(result<1.or.result>prog%ns) then
                        call runtime_error('invalid KIND function result reference',a%line,a%column);return
                    end if
                    if(a%typ/=prog%symbols(result)%typ.or. &
                       ((a%typ==ty_real.or.a%typ==ty_integer).and.a%real_kind/=prog%symbols(result)%real_kind).or. &
                       (prog%procedures(proc)%is_elemental.and.prog%symbols(result)%rank/=0).or. &
                       (.not.prog%procedures(proc)%is_elemental.and.a%rank/=prog%symbols(result)%rank)) then
                        call runtime_error('invalid KIND function result metadata',a%line,a%column);return
                    end if
                else if(a%kind==ex_constructor) then
                    call validate_empty_constructor(index)
                    if(diag%code/=0)return
                    if(a%rank/=1.or.any(a%dims/=0)) then
                        call runtime_error('invalid KIND constructor metadata',a%line,a%column);return
                    end if
                else
                    select case(a%op)
                    case('trim','kind','dble','abs','exp','log','log10','sqrt','erfc','sinh','cosh','tanh','sin','cos','tan','selected_int_kind')
                        if(size(a%args)/=1) then
                            call runtime_error('invalid KIND child intrinsic count',a%line,a%column);return
                        end if
                    case('len')
                        call validate_len_metadata(index)
                        if(diag%code/=0)return
                    case('dprod','tand')
                        call validate_dprod_tand(index,.false.)
                        if(diag%code/=0)return
                    case('real')
                        call validate_real_conversion(index,.false.)
                        if(diag%code/=0)return
                    case('asin','atan','atan2')
                        call validate_inverse_trig(index,.false.)
                        if(diag%code/=0)return
                    case('new_line')
                        call validate_new_line(index,.false.)
                        if(diag%code/=0)return
                    case('acosd','asind','sind','cosd')
                        call validate_degree_trig(index,.false.)
                        if(diag%code/=0)return
                    case('rrspacing','acos')
                        call validate_acos(index,.false.)
                        if(diag%code/=0)return
                    case('aint','anint','asinh','acosh')
                        call validate_real_round_inverse(index,.false.)
                        if(diag%code/=0)return
                    case('erf','bessel_j0','bessel_j1','bessel_jn','bessel_y0','bessel_y1','bessel_yn')
                        call validate_erf_bessel(index)
                        if(diag%code/=0) return
                    case('erfc_scaled')
                        call validate_erfc_scaled(index)
                        if(diag%code/=0) return
                    case('isnan')
                        call validate_isnan(index)
                        if(diag%code/=0) return
                    case('digits','epsilon','radix','tiny','huge','minexponent','maxexponent')
                        call validate_numeric_model(index)
                        if(diag%code/=0) return
                    case('allocated')
                        if(size(a%args)/=1.or.a%typ/=ty_logical.or.a%rank/=0.or.a%real_kind/=4) then
                            call runtime_error('invalid KIND ALLOCATED metadata',a%line,a%column);return
                        end if
                        child=a%args(1)
                        if(.not.valid_expression(child)) return
                        s=prog%expressions(child)%symbol
                        if(prog%expressions(child)%kind/=ex_variable.or.prog%expressions(child)%parenthesized.or. &
                           s<1.or.s>prog%ns) then
                            call runtime_error('invalid KIND ALLOCATED argument',a%line,a%column);return
                        end if
                        if(.not.prog%symbols(s)%is_allocatable) then
                            call runtime_error('invalid KIND ALLOCATED target',a%line,a%column);return
                        end if
                    case('present')
                        if(size(a%args)/=1.or.a%typ/=ty_logical.or.a%rank/=0.or.a%real_kind/=4) then
                            call runtime_error('invalid KIND PRESENT metadata',a%line,a%column);return
                        end if
                        child=a%args(1)
                        if(.not.valid_expression(child)) return
                        s=prog%expressions(child)%symbol
                        if(prog%expressions(child)%kind/=ex_variable.or.prog%expressions(child)%parenthesized.or. &
                           s<1.or.s>prog%ns) then
                            call runtime_error('invalid KIND PRESENT argument',a%line,a%column);return
                        end if
                        if(.not.prog%symbols(s)%is_dummy.or..not.prog%symbols(s)%is_optional.or. &
                           prog%symbols(s)%scope/=a%scope) then
                            call runtime_error('invalid KIND PRESENT dummy',a%line,a%column);return
                        end if
                    case('associated')
                        call validate_associated_metadata(index)
                        if(diag%code/=0) return
                    case('selected_real_kind')
                        if(size(a%args)>3.or.a%intrinsic_mask<0.or.a%intrinsic_mask>7.or. &
                           a%typ/=ty_integer.or.a%real_kind/=4.or.a%rank/=0) then
                            call runtime_error('invalid SELECTED_REAL_KIND metadata',a%line,a%column);return
                        end if
                        if(popcnt(a%intrinsic_mask)/=size(a%args)) then
                            call runtime_error('invalid SELECTED_REAL_KIND slots',a%line,a%column);return
                        end if
                        do j=1,size(a%args)
                            child=a%args(j)
                            if(child<1.or.child>prog%ne) then
                                call runtime_error('invalid SELECTED_REAL_KIND child',a%line,a%column);return
                            end if
                            if(prog%expressions(child)%typ/=ty_integer.or.prog%expressions(child)%rank/=0) then
                                call runtime_error('SELECTED_REAL_KIND needs scalar INTEGER',a%line,a%column);return
                            end if
                        end do
                    case('minloc','maxloc','findloc')
                        call validate_location_metadata(index)
                        if(diag%code/=0) return
                    case('shape')
                        call validate_shape_intrinsic(index)
                        if(diag%code/=0) return
                    case('eoshift')
                        call validate_eoshift(index,.false.)
                        if(diag%code/=0)return
                    case('cshift')
                        call validate_cshift(index)
                        if(diag%code/=0) return
                    case('reshape')
                        call validate_reshape(index)
                        if(diag%code/=0) return
                    case('merge')
                        if(size(a%args)/=3) then
                            call runtime_error('invalid MERGE argument count',a%line,a%column);return
                        end if
                    case('all','any','count','parity')
                        if(size(a%args)<1.or.size(a%args)>3) then
                            call runtime_error('invalid logical reduction argument count',a%line,a%column);return
                        end if
                    case('iand','ior','ieor','not','btest','bit_size','leadz','trailz','maskl','maskr','shiftr')
                        call validate_bit_intrinsic(index,.false.)
                        if(diag%code/=0)return
                    case('lge','lgt','lle','llt')
                        call validate_lexical_intrinsic(index,.false.)
                        if(diag%code/=0)return
                    case('index','scan','verify','len_trim','adjustl','adjustr')
                        call validate_character_intrinsic(index)
                        if(diag%code/=0) return
                    case('fraction','exponent','set_exponent','iachar')
                        call validate_model_decomposition(index)
                        if(diag%code/=0) return
                    case('spacing','nearest')
                        call validate_spacing_nearest(index)
                        if(diag%code/=0) return
                    case('dim','sign','log_gamma')
                        call validate_elementary_math(index)
                        if(diag%code/=0) return
                    case('repeat')
                        call validate_repeat_metadata(index)
                        if(diag%code/=0) return
                    case('char','achar')
                        call validate_character_code(index)
                        if(diag%code/=0) return
                    case('int','nint','floor','ceiling')
                        if(size(a%args)<1.or.size(a%args)>2) then
                            call runtime_error('invalid INT argument count',a%line,a%column);return
                        end if
                    case('pack')
                        if(size(a%args)<2.or.size(a%args)>3) then
                            call runtime_error('invalid KIND PACK argument count',a%line,a%column);return
                        end if
                    case('transpose','norm2')
                        call validate_matrix_call(index,.false.)
                        if(diag%code/=0)return
                    case('mod','modulo','dot_product','matmul')
                        if(size(a%args)/=2) then
                            call runtime_error('invalid KIND child intrinsic count',a%line,a%column);return
                        end if
                    case('min','max')
                        call validate_minmax(index,.false.)
                        if(diag%code/=0)return
                    case('lbound','ubound')
                        call validate_bounds_inquiry(index,.false.)
                        if(diag%code/=0)return
                    case('size','sum','product','minval','maxval')
                        if(size(a%args)<1) then
                            call runtime_error('missing KIND child intrinsic arguments',a%line,a%column);return
                        end if
                    case default
                        call runtime_error('invalid KIND child intrinsic',a%line,a%column);return
                    end select
                    if(.not.is_bit_intrinsic(a%op).and.a%op/='eoshift'.and..not.is_bounds_inquiry(a%op).and.a%op/='min'.and.a%op/='max'.and.a%op/='transpose'.and.a%op/='norm2'.and..not.is_lexical_intrinsic(a%op).and..not.is_degree_trig(a%op).and.a%op/='new_line'.and.a%op/='rrspacing'.and.a%op/='asin'.and.a%op/='atan'.and.a%op/='atan2'.and.a%op/='acos'.and.a%op/='real'.and.a%op/='aint'.and.a%op/='anint'.and.a%op/='asinh'.and.a%op/='acosh'.and.a%op/='dprod'.and.a%op/='tand') &
                        call validate_utility_intrinsic(index)
                    if(diag%code/=0) return
                    if(a%op=='kind'.and.(a%rank/=0.or.a%typ/=ty_integer)) then
                        call runtime_error('invalid nested KIND result metadata',a%line,a%column);return
                    end if
                end if
                r=0
                do j=1,size(a%args)
                    child=a%args(j)
                    if(a%kind==ex_user_call) then
                        dummy=prog%procedures(proc)%args(j)
                        if(dummy<1.or.dummy>prog%ns) then
                            call runtime_error('invalid KIND dummy reference',a%line,a%column);return
                        end if
                        if(child==0) then
                            if(.not.prog%symbols(dummy)%is_optional.or..not.prog%symbols(dummy)%is_dummy.or. &
                               prog%symbols(dummy)%scope/=proc) then
                                call runtime_error('missing required KIND function argument',a%line,a%column);return
                            end if
                            if(.not.valid_optional_declaration(dummy)) return
                            cycle
                        end if
                    end if
                    child_context=permit_component;child_derived=.false.
                    if(a%kind==ex_user_call) then
                        child_context=child_context.or.(a%typ==ty_character.and.a%character_len>=0)
                        child_derived=child_context.and.is_derived_type(prog%symbols(dummy)%typ)
                    else if(a%kind==ex_call) then
                        ! Existing strict inquiry/metadata walkers keep their
                        ! own operand policies even inside a CHARACTER actual.
                        ! Ordinary value operations (ABS, numeric MIN/MAX,
                        ! reductions and arithmetic) retain their prior support.
                        select case(a%op)
                        case('kind','len','new_line','digits','epsilon','radix','tiny','huge', &
                             'minexponent','maxexponent','size','shape','lbound','ubound', &
                             'iand','ior','ieor','not','btest','bit_size','leadz','trailz','maskl','maskr','shiftr','eoshift', &
                             'real','dprod','tand','acosd','asind','sind','cosd','rrspacing','acos', &
                             'aint','anint','asinh','acosh','asin','atan','atan2', &
                             'lge','lgt','lle','llt','transpose','norm2')
                            child_context=.false.
                        case('min','max')
                            if(a%typ==ty_character) child_context=.false.
                        end select
                    end if
                    call validate_kind_tree(child,marks,depth+1,child_derived,child_context)
                    if(diag%code/=0) return
                    r=max(r,prog%expressions(child)%rank)
                    if(a%kind==ex_constructor) then
                        if(prog%expressions(child)%rank>1.or.prog%expressions(child)%typ/=a%typ.or. &
                           ((a%typ==ty_real.or.a%typ==ty_integer).and.prog%expressions(child)%real_kind/=a%real_kind)) then
                            call runtime_error('invalid KIND constructor item metadata',a%line,a%column);return
                        end if
                    else if(a%kind==ex_user_call) then
                        dummy=prog%procedures(proc)%args(j)
                        if(dummy<1.or.dummy>prog%ns) then
                            call runtime_error('invalid KIND dummy reference',a%line,a%column);return
                        end if
                        if(.not.prog%symbols(dummy)%is_dummy.or.prog%symbols(dummy)%scope/=proc.or. &
                           prog%symbols(dummy)%typ/=prog%expressions(child)%typ.or. &
                           ((prog%symbols(dummy)%typ>=ty_integer.and.prog%symbols(dummy)%typ<=ty_logical).and. &
                            prog%symbols(dummy)%real_kind/=prog%expressions(child)%real_kind).or. &
                           (.not.prog%procedures(proc)%is_elemental.and. &
                            prog%symbols(dummy)%rank/=prog%expressions(child)%rank)) then
                            call runtime_error('invalid KIND actual argument metadata',a%line,a%column);return
                        end if
                    end if
                end do
                if(a%kind==ex_user_call) then
                    if(prog%procedures(proc)%is_elemental.and.a%rank/=r) then
                        call runtime_error('invalid KIND elemental result rank',a%line,a%column);return
                    end if
                end if
            case default
                call runtime_error('invalid KIND argument opcode',a%line,a%column);return
            end select
            do j=1,n
                child=children(j)
                if(child==0.and.(a%kind==ex_section.or.a%kind==ex_substring.or.a%kind==ex_constructor_do)) cycle
                call validate_kind_tree(child,marks,depth+1,character_actual=permit_component)
                if(diag%code/=0) return
            end do
            end associate
            marks(index)=merge(3,2,permit_component)
        end subroutine
        ! Numeric model inquiries use declared type/kind only, never descriptor
        ! state, element values, section bounds or user-function execution.
        recursive subroutine validate_new_line(index,walk_tree)
            integer,intent(in)::index
            logical,optional,intent(in)::walk_tree
            integer::a
            integer,allocatable::marks(:)
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing NEW_LINE operand',e%line,e%column);return
            end if
            if(size(e%args)/=1.or.e%intrinsic_mask/=0.or.e%typ/=ty_character.or.e%real_kind/=4.or. &
               e%rank/=0.or.e%extent/=0.or.any(e%dims/=0).or.e%character_len/=1) then
                call runtime_error('invalid NEW_LINE metadata',e%line,e%column);return
            end if
            a=e%args(1)
            if(.not.valid_expression(a))return
            if(prog%expressions(a)%typ/=ty_character.or.prog%expressions(a)%real_kind/=4.or. &
               prog%expressions(a)%rank<0.or.prog%expressions(a)%rank>3.or. &
               .not.exponent_inquiry_operand_supported(prog,a)) then
                call runtime_error('NEW_LINE requires whole default CHARACTER operand',e%line,e%column);return
            end if
            end associate
            allocate(marks(prog%ne),source=0)
            call validate_new_line_character_tree(index,marks,0)
            if(diag%code/=0)return
            if(present(walk_tree))then
                if(.not.walk_tree)return
            end if
            marks=0
            call validate_kind_tree(index,marks,0)
        end subroutine
        recursive subroutine validate_new_line_character_tree(index,marks,depth)
            integer,intent(in)::index,depth
            integer,intent(inout)::marks(:)
            integer::j,s,result,children(10)
            if(diag%code/=0)return
            if(.not.valid_expression(index))return
            if(depth>512.or.marks(index)==1)then
                call runtime_error('cyclic NEW_LINE operand',0,0);return
            end if
            if(marks(index)==2)return
            marks(index)=1
            associate(x=>prog%expressions(index))
            if(x%typ==ty_character)then
                if(x%real_kind/=4.or.x%character_len < -1.or.x%character_len>65536)then
                    call runtime_error('NEW_LINE CHARACTER kind/length metadata differs',x%line,x%column);return
                end if
                if(x%kind==ex_literal)then
                    if(.not.allocated(x%value%s))then
                        call runtime_error('missing NEW_LINE CHARACTER literal',x%line,x%column);return
                    end if
                    if(x%value%real_kind/=4.or.x%character_len/=len(x%value%s))then
                        call runtime_error('NEW_LINE CHARACTER literal cache differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_user_call)then
                    s=x%symbol
                    if(s<1.or.s>prog%np)then
                        call runtime_error('invalid NEW_LINE function reference',x%line,x%column);return
                    end if
                    result=prog%procedures(s)%result_symbol
                    if(result<1.or.result>prog%ns)then
                        call runtime_error('invalid NEW_LINE function result',x%line,x%column);return
                    end if
                    if(prog%symbols(result)%typ/=ty_character.or.prog%symbols(result)%real_kind/=4)then
                        call runtime_error('NEW_LINE function result kind differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_variable)then
                    s=x%symbol
                    if(.not.valid_symbol(s,allow_absent=.true.))return
                    if(prog%symbols(s)%real_kind/=4)then
                        call runtime_error('NEW_LINE CHARACTER declaration kind differs',x%line,x%column);return
                    end if
                end if
            end if
            children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third]
            do j=1,size(children)
                if(children(j)==0)cycle
                call validate_new_line_character_tree(children(j),marks,depth+1)
                if(diag%code/=0)return
            end do
            if(allocated(x%args))then
                do j=1,size(x%args)
                    if(x%args(j)==0.and.x%kind==ex_user_call)cycle
                    call validate_new_line_character_tree(x%args(j),marks,depth+1)
                    if(diag%code/=0)return
                end do
            end if
            end associate
            marks(index)=2
        end subroutine
        subroutine new_line_value(index,value)
            integer,intent(in)::index
            type(value_t),intent(out)::value
            call validate_new_line(index)
            if(diag%code/=0)return
            value=value_t(tag=ty_character,real_kind=4,s=new_line('a'))
        end subroutine
        subroutine validate_numeric_model(index)
            integer,intent(in)::index
            integer::arg,t,k,wanted_type,wanted_kind
            associate(e=>prog%expressions(index))
            if(e%op=='bit_size')then
                call validate_bit_intrinsic(index,.false.)
                return
            end if
            if(.not.allocated(e%args)) then
                call runtime_error('missing numeric model inquiry argument',e%line,e%column);return
            end if
            if(size(e%args)/=1.or.e%intrinsic_mask/=0.or.e%rank/=0.or.e%extent/=0.or.any(e%dims/=0)) then
                call runtime_error('invalid numeric model inquiry metadata',e%line,e%column);return
            end if
            arg=e%args(1)
            if(.not.valid_expression(arg)) return
            if(e%op=='minexponent'.or.e%op=='maxexponent') then
                if(.not.exponent_inquiry_operand_supported(prog,arg)) then
                    call runtime_error('MINEXPONENT/MAXEXPONENT subobject operands unsupported',e%line,e%column);return
                end if
            end if
            associate(a=>prog%expressions(arg))
            t=a%typ;k=a%real_kind
            if((t/=ty_integer.and.t/=ty_real).or.(k/=4.and.k/=8).or.a%rank<0.or.a%rank>3) then
                call runtime_error('invalid numeric model inquiry argument type/kind/rank',e%line,e%column);return
            end if
            if((e%op=='minexponent'.or.e%op=='maxexponent').and.t/=ty_real) then
                call runtime_error('MINEXPONENT/MAXEXPONENT requires REAL X',e%line,e%column);return
            end if
            if((e%op=='epsilon'.or.e%op=='tiny').and.t/=ty_real) then
                call runtime_error('EPSILON/TINY requires REAL X',e%line,e%column);return
            end if
            wanted_type=t;wanted_kind=k
            if(e%op=='digits'.or.e%op=='radix'.or.e%op=='minexponent'.or.e%op=='maxexponent') then
                wanted_type=ty_integer;wanted_kind=4
            end if
            if(e%typ/=wanted_type.or.e%real_kind/=wanted_kind) then
                call runtime_error('numeric model inquiry result type/kind differs',e%line,e%column);return
            end if
            end associate
            end associate
        end subroutine
        subroutine numeric_model_value(index,value)
            integer,intent(in)::index
            type(value_t),intent(out)::value
            integer::arg,k
            integer,allocatable::marks(:)
            call validate_numeric_model(index)
            if(diag%code/=0) return
            allocate(marks(prog%ne),source=0)
            call validate_kind_tree(index,marks,0)
            if(diag%code/=0) return
            associate(e=>prog%expressions(index))
            arg=e%args(1);k=prog%expressions(arg)%real_kind
            value=value_t(tag=e%typ,real_kind=e%real_kind)
            select case(e%op)
            case('bit_size')
                value%i=8_int64*k
            case('digits')
                if(prog%expressions(arg)%typ==ty_integer) then
                    value%i=31_int64
                    if(k==8)value%i=63_int64
                else if(k==4) then
                    value%i=int(digits(0.0_real32),int64)
                else
                    value%i=int(digits(0.0_real64),int64)
                end if
            case('radix')
                if(prog%expressions(arg)%typ==ty_integer) then
                    value%i=int(radix(0_int64),int64)
                else if(k==4) then
                    value%i=int(radix(0.0_real32),int64)
                else
                    value%i=int(radix(0.0_real64),int64)
                end if
            case('minexponent')
                if(k==4) then
                    value%i=int(minexponent(0.0_real32),int64)
                else
                    value%i=int(minexponent(0.0_real64),int64)
                end if
            case('maxexponent')
                if(k==4) then
                    value%i=int(maxexponent(0.0_real32),int64)
                else
                    value%i=int(maxexponent(0.0_real64),int64)
                end if
            case('epsilon')
                if(k==4) then
                    value%r=real(epsilon(0.0_real32),real64)
                else
                    value%r=epsilon(0.0_real64)
                end if
            case('tiny')
                if(k==4) then
                    value%r=real(tiny(0.0_real32),real64)
                else
                    value%r=tiny(0.0_real64)
                end if
            case('huge')
                if(e%typ==ty_integer) then
                    if(k==4) then
                        value%i=imax
                    else
                        value%i=huge(0_int64)
                    end if
                else if(k==4) then
                    value%r=real(huge(0.0_real32),real64)
                else
                    value%r=huge(0.0_real64)
                end if
            end select
            end associate
        end subroutine
        subroutine kind_value(index,value)
            integer,intent(in)::index
            type(value_t),intent(out)::value
            integer::arg,t,rk
            integer,allocatable::marks(:)
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing KIND argument',e%line,e%column);return
            end if
            if(size(e%args)/=1.or.e%typ/=ty_integer.or.e%rank/=0.or.e%extent/=0) then
                call runtime_error('invalid KIND inquiry',e%line,e%column);return
            end if
            arg=e%args(1)
            allocate(marks(prog%ne),source=0)
            call validate_kind_tree(index,marks,0)
            if(diag%code/=0) return
            associate(a=>prog%expressions(arg))
            if(arg==index.or.a%kind<ex_literal.or.(a%kind>ex_constructor.and.a%kind/=ex_substring.and.a%kind/=ex_gather_rows.and.a%kind/=ex_constructor_index)) then
                call runtime_error('invalid KIND argument expression',e%line,e%column);return
            end if
            t=a%typ;rk=a%real_kind
            if(a%rank<0.or.a%rank>3) then
                call runtime_error('invalid KIND argument rank',e%line,e%column);return
            end if
            if(a%kind==ex_variable.or.a%kind==ex_element.or.a%kind==ex_section) then
                if(.not.valid_symbol(a%symbol,allow_absent=.true.)) return
                if(t/=prog%symbols(a%symbol)%typ.or. &
                   (t==ty_real.and.rk/=prog%symbols(a%symbol)%real_kind)) then
                    call runtime_error('KIND argument type differs from symbol',e%line,e%column);return
                end if
            end if
            value%tag=ty_integer
            select case(t)
            case(ty_logical);value%i=4_int64
            case(ty_integer);value%i=int(rk,int64)
            case(ty_character);value%i=1_int64
            case(ty_real)
                if(rk/=4.and.rk/=8) then
                    call runtime_error('unsupported KIND argument kind',e%line,e%column);return
                end if
                value%i=int(rk,int64)
            case default
                call runtime_error('unsupported KIND argument type',e%line,e%column)
            end select
            end associate
            end associate
        end subroutine
        ! ELEMENTAL calls reuse scalar IN bindings at a selected column-major
        ! position. No array dummy or lifted procedure-result storage is created.
        recursive subroutine invoke_procedure(proc,items,lin,col,depth,result,element_position,element_results,array_result)
            integer, intent(in) :: proc,items(:),lin,col,depth
            type(value_t), intent(out), optional :: result
            integer, intent(in), optional :: element_position
            type(value_t), allocatable, intent(out), optional :: element_results(:)
            type(array_storage_t), intent(out), optional :: array_result
            type(argument_t), allocatable :: arguments(:), scalar_arguments(:)
            type(actual_binding_t), allocatable :: bindings(:)
            type(value_t) :: subscript,subscript2
            integer :: j,k,q,dummy,index,sym,off,call_rank,position,slot,writable_count
            integer,allocatable :: selected(:)
            integer(int64) :: extent,total,call_extent,call_dims(3)
            logical :: designator,whole_elemental,missing
            if(proc<1.or.proc>prog%np) then
                call runtime_error('invalid procedure reference',lin,col); return
            end if
            if(.not.internal_call_visible(prog,scope,proc)) then
                call runtime_error('internal call outside its lexical host',lin,col);return
            end if
            ! Reject the next activation before evaluating its actual arguments.
            ! Locals, dummies, loop state and expression caches are frame-owned.
            ! Module/SAVE storage and explicitly captured host references retain
            ! their separate, checked storage lifetimes.
            if(size(stack)>=64) then
                call runtime_error('procedure call depth limit exceeded (64)',lin,col);return
            end if
            if(any(stack==proc).and..not.prog%procedures(proc)%is_recursive) then
                call runtime_error('recursive invocation requires RECURSIVE',lin,col);return
            end if
            if(.not.allocated(prog%procedures(proc)%args)) then
                call runtime_error('missing procedure dummies',lin,col); return
            end if
            if(size(items)/=size(prog%procedures(proc)%args).or.size(items)>16) then
                call runtime_error('procedure argument count mismatch',lin,col); return
            end if
            do j=1,size(items)
                dummy=prog%procedures(proc)%args(j)
                if(dummy<1.or.dummy>prog%ns) then
                    call runtime_error('invalid dummy symbol',lin,col);return
                end if
                if(.not.valid_optional_declaration(dummy)) return
            end do
            if(prog%procedures(proc)%is_elemental) then
                if(prog%procedures(proc)%is_pure.eqv.prog%procedures(proc)%has_impure_prefix) then
                    call runtime_error('inconsistent ELEMENTAL purity designation',lin,col);return
                end if
                if(prog%procedures(proc)%has_impure_prefix.and. &
                   (prog%procedures(proc)%has_pure_prefix.or.prog%procedures(proc)%is_simple)) then
                    call runtime_error('conflicting ELEMENTAL purity prefixes',lin,col);return
                end if
            end if
            whole_elemental=prog%procedures(proc)%is_elemental.and. &
                (prog%procedures(proc)%is_subroutine.or.present(element_results))
            call_rank=0;call_extent=1_int64;call_dims=0_int64;writable_count=0
            ! Validate every descriptor and conformability before data evaluation
            ! or any scalar body, including empty calls and dynamic sections.
            if(whole_elemental) then
                do j=1,size(items)
                    index=items(j);dummy=prog%procedures(proc)%args(j)
                    if(dummy<1.or.dummy>prog%ns) then
                        call runtime_error('invalid ELEMENTAL dummy symbol',lin,col);return
                    end if
                    missing=absent_actual(index,dummy)
                    if(diag%code/=0) return
                    if(missing) then
                        if(.not.prog%symbols(dummy)%is_optional) then
                            call runtime_error('absent actual associated with required dummy',lin,col);return
                        end if
                        cycle
                    end if
                    if(.not.valid_expression(index)) return
                    if(prog%symbols(dummy)%dummy_intent>=2) writable_count=writable_count+1
                    call prepare_expression(index,depth+1)
                    if(diag%code/=0) return
                    if(prog%expressions(index)%rank==0) cycle
                    if(call_rank==0) then
                        call_rank=prog%expressions(index)%rank
                        call_extent=shape_extent(index);call_dims=shape_dims(:,index)
                    else if(prog%expressions(index)%rank/=call_rank.or.any(shape_dims(:,index)/=call_dims)) then
                        call runtime_error('ELEMENTAL actual argument shapes do not conform',lin,col);return
                    end if
                end do
                if(call_rank>0.and.prog%procedures(proc)%is_subroutine) then
                    if(writable_count==0) then
                        call runtime_error('ELEMENTAL array CALL requires an OUT or INOUT dummy',lin,col);return
                    end if
                    do j=1,size(items)
                        dummy=prog%procedures(proc)%args(j)
                        missing=absent_actual(items(j),dummy)
                        if(diag%code/=0) return
                        if(missing) cycle
                        if(prog%symbols(dummy)%dummy_intent<2) cycle
                        if(prog%expressions(items(j))%rank/=call_rank) then
                            call runtime_error('ELEMENTAL array CALL requires array writable actuals',lin,col);return
                        end if
                    end do
                end if
                if(present(element_results)) allocate(element_results(int(call_extent)))
            end if
            if(module_actual_conflict(prog,proc,items)) then
                call runtime_error('module actual conflicts with callee host/USE association',lin,col);return
            end if
            allocate(arguments(size(items)),bindings(size(items)))
            total=0_int64
            ! Freeze each actual's address/section in the caller. No actual data
            ! changes before all actual expressions and alias checks succeed.
            do j=1,size(items)
                index=items(j); dummy=prog%procedures(proc)%args(j)
                if(dummy<1.or.dummy>prog%ns) then
                    call runtime_error('invalid dummy symbol',lin,col); return
                end if
                if(.not.prog%symbols(dummy)%is_dummy.or.prog%symbols(dummy)%scope/=proc.or. &
                   prog%symbols(dummy)%dummy_intent<0.or.prog%symbols(dummy)%dummy_intent>3) then
                    call runtime_error('invalid dummy intent or scope',lin,col); return
                end if
                missing=absent_actual(index,dummy)
                if(diag%code/=0) return
                if(missing) then
                    if(.not.prog%symbols(dummy)%is_optional) then
                        call runtime_error('absent actual associated with required dummy',lin,col);return
                    end if
                    arguments(j)%is_present=.false.
                    cycle
                end if
                if(.not.valid_expression(index)) return
                if(prog%expressions(index)%kind==ex_gather_rows.and. &
                   ((.not.prog%expressions(index)%parenthesized.and. &
                     .not.bare_gather_input(prog,index,dummy)).or.prog%symbols(dummy)%dummy_intent/=1)) then
                    call runtime_error('gathered row user actual requires parentheses',lin,col);return
                end if
                if(prog%expressions(index)%typ/=prog%symbols(dummy)%typ.or. &
                   (.not.prog%procedures(proc)%is_elemental.and. &
                    prog%expressions(index)%rank/=prog%symbols(dummy)%rank)) then
                    call runtime_error('procedure argument type or rank mismatch',lin,col); return
                end if
                if((prog%symbols(dummy)%typ>=ty_integer.and.prog%symbols(dummy)%typ<=ty_logical).and. &
                   prog%expressions(index)%real_kind/=prog%symbols(dummy)%real_kind) then
                    call runtime_error('procedure REAL argument kind mismatch',lin,col); return
                end if
                if(prog%procedures(proc)%is_elemental) then
                    if(prog%symbols(dummy)%rank/=0.or.prog%symbols(dummy)%dummy_intent<1.or. &
                       (.not.prog%procedures(proc)%is_subroutine.and.prog%symbols(dummy)%dummy_intent/=1)) then
                        call runtime_error('invalid ELEMENTAL scalar dummy declaration',lin,col); return
                    end if
                    if(prog%expressions(index)%rank>0.and..not.present(element_position).and..not.whole_elemental) then
                        call runtime_error('ELEMENTAL array argument requires an element position',lin,col); return
                    end if
                end if
                bindings(j)%writable=prog%symbols(dummy)%dummy_intent>=2
                if(bindings(j)%writable.and..not.prog%procedures(proc)%is_subroutine) then
                    call runtime_error('functions require INTENT(IN) arguments',lin,col); return
                end if
                arguments(j)%typ=prog%symbols(dummy)%typ
                arguments(j)%real_kind=prog%symbols(dummy)%real_kind
                arguments(j)%rank=prog%symbols(dummy)%rank
                if(whole_elemental) arguments(j)%rank=prog%expressions(index)%rank
                designator=.not.prog%expressions(index)%parenthesized.and. &
                    (prog%expressions(index)%kind==ex_variable.or. &
                     prog%expressions(index)%kind==ex_element.or.prog%expressions(index)%kind==ex_section)
                sym=0
                if(designator) then
                    sym=prog%expressions(index)%symbol
                    if(.not.valid_symbol(sym,.true.)) return
                    if(prog%expressions(index)%typ/=prog%symbols(sym)%typ.or. &
                       ((prog%symbols(sym)%typ>=ty_integer.and.prog%symbols(sym)%typ<=ty_logical).and. &
                        prog%expressions(index)%real_kind/=prog%symbols(sym)%real_kind)) then
                        call runtime_error('actual designator type differs from its variable binding',lin,col);return
                    end if
                    select case(prog%expressions(index)%kind)
                    case(ex_variable)
                        if(prog%expressions(index)%rank/=prog%symbols(sym)%rank) then
                            call runtime_error('actual variable rank differs from its binding',lin,col);return
                        end if
                    case(ex_element)
                        if(prog%expressions(index)%rank/=0.or.prog%symbols(sym)%rank==0) then
                            call runtime_error('invalid actual element binding',lin,col);return
                        end if
                    case(ex_section)
                        if(prog%expressions(index)%rank<1.or. &
                           prog%expressions(index)%rank>prog%symbols(sym)%rank) then
                            call runtime_error('invalid actual section binding',lin,col);return
                        end if
                    end select
                    if(prog%symbols(sym)%is_parameter) designator=.false.
                end if
                if(bindings(j)%writable) then
                    if(sym>0) then
                        if(prog%symbols(sym)%scope<0.or.prog%symbols(sym)%is_saved.or.captured(sym)) call check_external_effect(lin,col)
                        if(diag%code/=0) return
                    end if
                    if(.not.designator) then
                        call runtime_error('writable dummy requires a variable actual argument',lin,col); return
                    end if
                    if(prog%symbols(sym)%is_dummy.and.prog%symbols(sym)%dummy_intent<=1) then
                        call runtime_error('INTENT(IN) actual cannot be passed to a writable dummy',lin,col); return
                    end if
                    if(refs(sym)%active) then
                        call runtime_error('active DO variable cannot be a writable actual argument',lin,col); return
                    end if
                end if
                if(prog%symbols(dummy)%is_pointer) then
                    if(.not.designator.or.prog%expressions(index)%kind/=ex_variable.or.sym==0) then
                        call runtime_error('POINTER dummy requires a whole pointer actual',lin,col);return
                    end if
                    if(.not.prog%symbols(sym)%is_pointer.or..not.prog%procedures(proc)%is_subroutine.or. &
                       prog%procedures(proc)%is_elemental) then
                        call runtime_error('invalid POINTER dummy association',lin,col);return
                    end if
                    bindings(j)%symbol=sym;bindings(j)%pointer_descriptor=.true.
                    allocate(bindings(j)%offsets(0),arguments(j)%values(0),arguments(j)%initialized(0))
                    arguments(j)%is_pointer=.true.
                    if(prog%symbols(dummy)%dummy_intent/=2) then
                        call copy_alias_view(arguments(j)%view,refs(sym)%array,lin,col)
                        if(diag%code/=0) return
                    end if
                    cycle
                end if
                if(sym>0) then
                    if(prog%symbols(sym)%is_pointer) then
                        call runtime_error('POINTER actuals require POINTER dummies in this subset',lin,col);return
                    end if
                end if
                if(designator.and.sym>0) then
                    if(prog%symbols(dummy)%is_target.and.prog%symbols(dummy)%rank>0.and. &
                       prog%symbols(dummy)%rank<=2.and.prog%symbols(dummy)%assumed_shape.and. &
                       .not.prog%symbols(dummy)%is_allocatable.and.prog%expressions(index)%kind==ex_variable.and. &
                       (prog%symbols(dummy)%typ==ty_integer.or.prog%symbols(dummy)%typ==ty_real).and. &
                       .not.prog%symbols(sym)%is_allocatable.and.prog%symbols(sym)%scope>=0) then
                        if(.not.array_available(sym,lin,col)) return
                        if(refs(sym)%array%can_alias) then
                            arguments(j)%shared_target=.true.;bindings(j)%shared_target=.true.
                            call copy_alias_view(arguments(j)%view,refs(sym)%array,lin,col)
                            if(diag%code/=0) return
                            arguments(j)%dims=storage_dims(sym)
                            extent=size(refs(sym)%array%data,kind=int64);total=total+extent
                            if(total>max_array_elements) then
                                call runtime_error('total argument array element limit exceeded',lin,col);return
                            end if
                            bindings(j)%symbol=sym
                            allocate(arguments(j)%values(0),arguments(j)%initialized(0))
                            bindings(j)%offsets=[(k,k=1,int(extent))]
                            cycle
                        end if
                    end if
                end if
                if(prog%symbols(dummy)%is_allocatable) then
                    if(.not.designator.or.prog%expressions(index)%kind/=ex_variable.or.sym==0) then
                        call runtime_error('ALLOCATABLE dummy requires whole allocatable actual',lin,col);return
                    end if
                    if(.not.prog%symbols(sym)%is_allocatable.or.prog%procedures(proc)%is_elemental) then
                        call runtime_error('invalid ALLOCATABLE dummy association',lin,col);return
                    end if
                    bindings(j)%symbol=sym;bindings(j)%allocatable_descriptor=.true.
                    allocate(bindings(j)%offsets(0))
                    arguments(j)%is_allocatable=.true.
                    arguments(j)%deferred_character=prog%symbols(sym)%deferred_character
                    if(arguments(j)%deferred_character.neqv.prog%symbols(dummy)%deferred_character) then
                        call runtime_error('ALLOCATABLE CHARACTER deferred length differs',lin,col);return
                    end if
                    if(prog%symbols(sym)%typ==ty_character) then
                        if(.not.prog%symbols(sym)%deferred_character.or. &
                           (allocated(refs(sym)%array%values).and.prog%symbols(dummy)%dummy_intent/=2)) then
                            arguments(j)%character_len=character_length(index,depth+1)
                            if(diag%code/=0) return
                        end if
                    end if
                    arguments(j)%is_allocated=allocated(refs(sym)%array%values).and.prog%symbols(dummy)%dummy_intent/=2
                    extent=0_int64
                    if(arguments(j)%is_allocated) then
                        if(.not.array_available(sym,lin,col)) return
                        extent=size(refs(sym)%array%data,kind=int64)
                        arguments(j)%dims=storage_dims(sym)
                        arguments(j)%lower_bounds=[refs(sym)%array%lower_bound,refs(sym)%array%lower_bound2,refs(sym)%array%lower_bound3]
                        arguments(j)%upper_bounds=[refs(sym)%array%upper_bound,refs(sym)%array%upper_bound2,refs(sym)%array%upper_bound3]
                    end if
                    total=total+extent
                    if(total>max_array_elements) then
                        call runtime_error('total argument array element limit exceeded',lin,col);return
                    end if
                    allocate(arguments(j)%values(int(extent)),arguments(j)%initialized(int(extent)))
                    if(arguments(j)%is_allocated) then
                        do k=1,int(extent)
                            call consume(lin,col)
                            if(diag%code/=0) return
                            arguments(j)%values(k)=refs(sym)%array%data(k)
                            arguments(j)%initialized(k)=refs(sym)%array%flags(k)
                        end do
                        if(prog%symbols(sym)%rank==0) then
                            arguments(j)%values(1)=refs(sym)%value
                            arguments(j)%initialized(1)=refs(sym)%defined
                        end if
                    end if
                    cycle
                end if
                if(sym>0.and.designator) then
                    if(prog%symbols(sym)%is_allocatable.and.prog%symbols(sym)%rank==0) then
                        if(.not.array_available(sym,lin,col)) return
                    end if
                end if
                ! An empty elemental invocation has no scalar invocations and
                ! must not evaluate scalar data expressions or invalidate OUT.
                if(whole_elemental.and.call_extent==0) cycle
                extent=1_int64
                if(arguments(j)%rank>0) then
                    call prepare_expression(index,depth+1)
                    if(diag%code/=0) return
                    extent=shape_extent(index)
                    arguments(j)%dims=shape_dims(:,index)
                    total=total+extent
                    if(total>max_array_elements) then
                        call runtime_error('total argument array element limit exceeded',lin,col); return
                    end if
                end if
                if(prog%symbols(dummy)%typ==ty_character.and.(designator.or.arguments(j)%rank>0)) then
                    arguments(j)%character_len=character_length(index,depth+1)
                    if(diag%code/=0) return
                end if
                allocate(arguments(j)%values(int(extent)),arguments(j)%initialized(int(extent)))
                arguments(j)%initialized=.false.
                if(designator) then
                    bindings(j)%symbol=sym
                    allocate(bindings(j)%offsets(int(extent)))
                    if(arguments(j)%rank==0) then
                        off=0
                        if(prog%procedures(proc)%is_elemental.and.prog%expressions(index)%rank>0) then
                            call prepare_expression(index,depth+1)
                            if(diag%code/=0) return
                            if(element_position<1.or.element_position>shape_extent(index)) then
                                call runtime_error('ELEMENTAL argument position out of bounds',lin,col); return
                            end if
                            off=element_position
                            if(prog%expressions(index)%kind==ex_section) off=section_offset(index,element_position)
                        else if(prog%expressions(index)%kind==ex_element) then
                            off=element_expression_offset(sym,prog%expressions(index)%left, &
                                prog%expressions(index)%right,prog%expressions(index)%third,depth,lin,col)
                            if(diag%code/=0) return
                        else if(prog%symbols(sym)%rank/=0) then
                            call runtime_error('invalid scalar actual argument',lin,col); return
                        end if
                        bindings(j)%offsets(1)=off
                    else
                        do k=1,int(extent)
                            off=k
                            if(prog%expressions(index)%kind==ex_section) then
                                off=section_offset(index,k)
                            end if
                            bindings(j)%offsets(k)=off
                        end do
                    end if
                    do k=1,int(extent)
                        call consume(lin,col)
                        if(diag%code/=0) return
                        ! OUT does not read even an undefined or stale actual.
                        if(prog%symbols(dummy)%dummy_intent==2) then
                            if(prog%symbols(dummy)%typ==ty_character) then
                                if(.not.allocated(refs(sym)%value%s)) then
                                    call runtime_error('CHARACTER actual has no declared length',lin,col);return
                                end if
                                arguments(j)%values(k)%tag=ty_character
                                arguments(j)%values(k)%s=repeat(' ',len(refs(sym)%value%s))
                            end if
                            cycle
                        end if
                        off=bindings(j)%offsets(k)
                        if(off==0) then
                            arguments(j)%values(k)=refs(sym)%value
                            arguments(j)%initialized(k)=refs(sym)%defined
                        else
                            arguments(j)%values(k)=refs(sym)%array%data(off)
                            arguments(j)%initialized(k)=refs(sym)%array%flags(off)
                        end if
                    end do
                else
                    ! A substring input is copied as a value, but remains a
                    ! designator for alias checks. Conservatively reserve its
                    ! entire scalar base against any writable actual.
                    if(prog%expressions(index)%kind==ex_substring.and.prog%expressions(index)%symbol>0.and. &
                       .not.prog%expressions(index)%parenthesized) then
                        bindings(j)%symbol=prog%expressions(index)%symbol
                        bindings(j)%gathered_input=prog%expressions(index)%third/=0
                        allocate(bindings(j)%offsets(1),source=0)
                    else
                        allocate(bindings(j)%offsets(0))
                        if(bare_gather_input(prog,index,dummy))then
                            ! Values are copied, but a bare section retains its
                            ! base association. Do not reevaluate vector indices
                            ! to build alias offsets; reserve its entire base.
                            sym=prog%expressions(index)%symbol
                            if(.not.valid_symbol(sym,.true.))return
                            if(.not.prog%symbols(sym)%is_parameter)then
                                bindings(j)%symbol=sym
                                bindings(j)%gathered_input=.true.
                            end if
                        end if
                    end if
                    do k=1,int(extent)
                        if(prog%procedures(proc)%is_elemental.and.prog%expressions(index)%rank>0.and..not.whole_elemental) then
                            arguments(j)%values(k)=evaluate(index,depth+1,element_position)
                        else if(arguments(j)%rank==0) then
                            arguments(j)%values(k)=evaluate(index,depth+1)
                        else
                            arguments(j)%values(k)=evaluate(index,depth+1,k)
                        end if
                        if(diag%code/=0) return
                        arguments(j)%initialized(k)=.true.
                    end do
                    if(prog%symbols(dummy)%typ==ty_character.and.arguments(j)%rank==0) then
                        if(.not.allocated(arguments(j)%values(1)%s)) then
                            call runtime_error('CHARACTER actual has no value',lin,col);return
                        end if
                        arguments(j)%character_len=len(arguments(j)%values(1)%s)
                    end if
                end if
            end do
            if(whole_elemental.and.call_extent==0) return
            ! Exact bounded address membership is required: a multidimensional
            ! section is not generally one monotone arithmetic progression.
            ! Build a map only for a potentially writable alias pair. Scalar
            ! calls need at most slot zero; read-only and disjoint-symbol calls
            ! allocate nothing. Empty and expression bindings never overlap.
            do j=1,size(items)-1
                if(bindings(j)%symbol==0) cycle
                do q=j+1,size(items)
                    if(bindings(j)%pointer_descriptor.and.bindings(q)%pointer_descriptor.and. &
                       bindings(j)%symbol==bindings(q)%symbol.and. &
                       (bindings(j)%writable.or.bindings(q)%writable)) then
                        call runtime_error('overlapping POINTER descriptors with a writable dummy are unsupported',lin,col);return
                    end if
                    if((bindings(j)%gathered_input.or.bindings(q)%gathered_input).and. &
                       (bindings(j)%writable.or.bindings(q)%writable))then
                        if(same_backing(bindings(q)%symbol,bindings(j)%symbol))then
                            if(prog%expressions(items(j))%kind==ex_substring.or.prog%expressions(items(q))%kind==ex_substring)then
                                call runtime_error('array-element substring base overlaps a writable actual',lin,col)
                            else if((bindings(j)%gathered_input.and.prog%expressions(items(j))%typ==ty_character).or. &
                               (bindings(q)%gathered_input.and.prog%expressions(items(q))%typ==ty_character))then
                                call runtime_error('bare CHARACTER gather base overlaps a writable actual',lin,col)
                            else
                                call runtime_error('bare numeric gather base overlaps a writable actual',lin,col)
                            end if
                            return
                        end if
                    end if
                    if(bindings(j)%pointer_descriptor.or.bindings(q)%pointer_descriptor) cycle
                    if(.not.same_backing(bindings(q)%symbol,bindings(j)%symbol)) cycle
                    if(.not.(bindings(j)%writable.or.bindings(q)%writable)) cycle
                    if(bindings(j)%allocatable_descriptor.or.bindings(q)%allocatable_descriptor) then
                        call runtime_error('overlapping allocatable descriptors with a writable dummy are unsupported',lin,col);return
                    end if
                end do
                if(size(bindings(j)%offsets)==0) cycle
                do q=j+1,size(items)
                    if(bindings(j)%pointer_descriptor.or.bindings(q)%pointer_descriptor) cycle
                    if(.not.same_backing(bindings(q)%symbol,bindings(j)%symbol)) cycle
                    if(.not.(bindings(j)%writable.or.bindings(q)%writable)) cycle
                    if(size(bindings(q)%offsets)==0) cycle
                    if(.not.allocated(selected)) then
                        allocate(selected(0:maxval(bindings(j)%offsets)),source=0)
                        do k=1,size(bindings(j)%offsets)
                            call consume(lin,col)
                            if(diag%code/=0) return
                            selected(bindings(j)%offsets(k))=1
                        end do
                    end if
                    do k=1,size(bindings(q)%offsets)
                        call consume(lin,col)
                        if(diag%code/=0) return
                        off=bindings(q)%offsets(k)
                        if(off>ubound(selected,1)) cycle
                        if(selected(off)==0) cycle
                        call runtime_error('overlapping actual arguments with a writable dummy are unsupported',lin,col)
                        return
                    end do
                end do
                if(allocated(selected)) deallocate(selected)
            end do
            if(whole_elemental) then
                allocate(scalar_arguments(size(items)))
                do j=1,size(items)
                    scalar_arguments(j)%is_present=arguments(j)%is_present
                    if(.not.arguments(j)%is_present) cycle
                    scalar_arguments(j)%typ=arguments(j)%typ
                    scalar_arguments(j)%real_kind=arguments(j)%real_kind
                    scalar_arguments(j)%character_len=arguments(j)%character_len
                    allocate(scalar_arguments(j)%values(1),scalar_arguments(j)%initialized(1))
                end do
                ! Array element order is mandatory for IMPURE ELEMENTAL. Pure
                ! calls use the same deterministic order, sharing the budget.
                do position=1,int(call_extent)
                    call consume(lin,col)
                    if(diag%code/=0) return
                    do j=1,size(items)
                        if(.not.arguments(j)%is_present) cycle
                        slot=1
                        if(arguments(j)%rank>0) slot=position
                        scalar_arguments(j)%values(1)=arguments(j)%values(slot)
                        scalar_arguments(j)%initialized(1)=arguments(j)%initialized(slot)
                    end do
                    if(present(element_results)) then
                        call execute_program(prog,diag,procedure_index=proc,argument_bindings=scalar_arguments, &
                            procedure_value=element_results(position),budget_remaining=budget,call_stack=stack, &
                            io_in_progress=in_output,random_state=rng,module_store=modules,pointer_context=context,input_units=input_units)
                    else
                        call execute_program(prog,diag,procedure_index=proc,argument_bindings=scalar_arguments, &
                            budget_remaining=budget,call_stack=stack,io_in_progress=in_output,random_state=rng,module_store=modules,pointer_context=context,input_units=input_units)
                    end if
                    if(diag%code/=0) return
                    do j=1,size(items)
                        if(.not.bindings(j)%writable) cycle
                        slot=1
                        if(arguments(j)%rank>0) slot=position
                        arguments(j)%values(slot)=scalar_arguments(j)%values(1)
                        arguments(j)%initialized(slot)=scalar_arguments(j)%initialized(1)
                    end do
                end do
            else
                call execute_program(prog,diag,procedure_index=proc,argument_bindings=arguments, &
                    procedure_value=result,budget_remaining=budget,call_stack=stack,io_in_progress=in_output, &
                    random_state=rng,procedure_array=array_result,module_store=modules,pointer_context=context,input_units=input_units)
                if(diag%code/=0) return
            end if
            call validate_allocatable_copyout(arguments,bindings,lin,col)
            if(diag%code/=0) return
            ! Copy out values AND definition flags, including unwritten OUT
            ! elements. Nested forwarding therefore cannot resurrect old data.
            do j=1,size(items)
                if(.not.bindings(j)%writable) cycle
                sym=bindings(j)%symbol
                if(bindings(j)%pointer_descriptor) then
                    call copy_alias_view(refs(sym)%array,arguments(j)%view,lin,col)
                    if(diag%code/=0) return
                    cycle
                end if
                if(bindings(j)%shared_target) cycle
                if(bindings(j)%allocatable_descriptor) then
                    if(prog%symbols(sym)%rank==0) refs(sym)%defined=.false.
                    if(prog%symbols(sym)%deferred_character) then
                        if(allocated(refs(sym)%value%s)) deallocate(refs(sym)%value%s)
                        refs(sym)%array%character_len=arguments(j)%character_len
                        if(arguments(j)%is_allocated) then
                            refs(sym)%value%tag=ty_character
                            refs(sym)%value%s=repeat(' ',arguments(j)%character_len)
                        end if
                    end if
                    if(allocated(refs(sym)%array%values)) deallocate(refs(sym)%array%values)
                    if(allocated(refs(sym)%array%initialized)) deallocate(refs(sym)%array%initialized)
                    refs(sym)%array%lower_bound=arguments(j)%lower_bounds(1)
                    refs(sym)%array%upper_bound=arguments(j)%upper_bounds(1)
                    refs(sym)%array%lower_bound2=arguments(j)%lower_bounds(2)
                    refs(sym)%array%lower_bound3=arguments(j)%lower_bounds(3)
                    refs(sym)%array%upper_bound2=arguments(j)%upper_bounds(2)
                    refs(sym)%array%upper_bound3=arguments(j)%upper_bounds(3)
                    if(arguments(j)%is_allocated) then
                        call move_alloc(arguments(j)%values,refs(sym)%array%values)
                        call move_alloc(arguments(j)%initialized,refs(sym)%array%initialized)
                        call bind_owned_storage(sym)
                        if(prog%symbols(sym)%rank==0) then
                            refs(sym)%value=refs(sym)%array%values(1)
                            refs(sym)%defined=refs(sym)%array%initialized(1)
                            if(.not.refs(sym)%defined) then
                                refs(sym)%value%tag=ty_character
                                refs(sym)%value%s=repeat(' ',arguments(j)%character_len)
                            end if
                        end if
                    end if
                    cycle
                end if
                if(size(arguments(j)%values)>size(bindings(j)%offsets).or. &
                   size(arguments(j)%initialized)/=size(arguments(j)%values)) then
                    call runtime_error('invalid procedure copy-out storage',lin,col);return
                end if
                ! Explicit-shape association can use only the leading element
                ! sequence of a larger actual. Preserve the unassociated tail.
                do k=1,size(arguments(j)%values)
                    off=bindings(j)%offsets(k)
                    if(off==0) then
                        refs(sym)%value=arguments(j)%values(k)
                        refs(sym)%defined=arguments(j)%initialized(k)
                    else
                        refs(sym)%array%data(off)=arguments(j)%values(k)
                        refs(sym)%array%flags(off)=arguments(j)%initialized(k)
                    end if
                end do
            end do
        end subroutine
        ! An allocatable whole target changes shape only after its complete RHS
        ! has been evaluated and converted. Self-growth and sections therefore
        ! keep reading the old descriptor, including when allocation is needed.
        subroutine assign_allocatable_scalar(sym,value,lin,col)
            integer,intent(in)::sym,lin,col
            type(value_t),intent(inout)::value
            type(array_storage_t)::fresh
            integer::n,j,ios
            integer(int64)::live
            if(.not.prog%symbols(sym)%is_allocatable.or.prog%symbols(sym)%rank/=0.or. &
               prog%symbols(sym)%typ/=ty_character.or.value%tag/=ty_character.or..not.allocated(value%s)) then
                call runtime_error('invalid scalar ALLOCATABLE CHARACTER assignment',lin,col);return
            end if
            n=len(value%s)
            if(.not.prog%symbols(sym)%deferred_character) then
                call fit_character(value,sym,lin,col)
                if(diag%code/=0) return
                n=len(value%s)
            end if
            if(.not.character_storage_fits(sym,1_int64,n)) then
                call runtime_error('CHARACTER allocation byte or length limit exceeded',lin,col);return
            end if
            live=0_int64
            do j=1,prog%ns
                if(j==sym) cycle
                if(prog%symbols(sym)%scope<0) then
                    if(prog%symbols(j)%scope>=0) cycle
                else
                    if(prog%symbols(j)%scope/=prog%symbols(sym)%scope) cycle
                end if
                if(allocated(refs(j)%array%values)) live=live+size(refs(j)%array%values,kind=int64)
            end do
            if(live>=max_array_elements) then
                call runtime_error('total array element limit exceeded during scalar allocation',lin,col);return
            end if
            if(allocated(refs(sym)%array%values)) then
                if(.not.array_available(sym,lin,col)) return
            else
                allocate(fresh%values(1),fresh%initialized(1),stat=ios)
                if(ios/=0) then
                    call runtime_error('scalar CHARACTER allocation failed',lin,col);return
                end if
                fresh%initialized=.false.
                call move_alloc(fresh%values,refs(sym)%array%values)
                call move_alloc(fresh%initialized,refs(sym)%array%initialized)
            end if
            refs(sym)%value=value;refs(sym)%defined=.true.
            refs(sym)%array%character_len=n
            refs(sym)%array%lower_bound=1;refs(sym)%array%upper_bound=1
            refs(sym)%array%lower_bound2=1;refs(sym)%array%upper_bound2=1
            refs(sym)%array%lower_bound3=1;refs(sym)%array%upper_bound3=1
            call bind_owned_storage(sym)
        end subroutine
        recursive subroutine assign_allocatable_array(sym,root,lin,col)
            integer,intent(in)::sym,root,lin,col
            integer::j,d,source,ios,clen
            integer(int64)::dims(3),old_dims(3),lo(3),hi(3),extent,live
            logical::replace
            type(value_t)::v
            type(array_storage_t)::fresh
            if(.not.prog%symbols(sym)%is_allocatable.or. &
               prog%symbols(sym)%rank<1.or.prog%symbols(sym)%rank>3.or. &
               (prog%symbols(sym)%typ/=ty_integer.and.prog%symbols(sym)%typ/=ty_real.and. &
                prog%symbols(sym)%typ/=ty_logical.and.prog%symbols(sym)%typ/=ty_character)) then
                call runtime_error('invalid allocatable assignment target',lin,col);return
            end if
            if(prog%expressions(root)%rank/=prog%symbols(sym)%rank) then
                call runtime_error('allocatable assignment ranks do not conform',lin,col);return
            end if
            call prepare_expression(root,0)
            if(diag%code/=0) return
            dims=shape_dims(:,root);extent=shape_extent(root)
            clen=-1
            if(prog%symbols(sym)%typ==ty_character) then
                if(prog%symbols(sym)%deferred_character) then
                    clen=character_length(root,0)
                else
                    clen=prog%symbols(sym)%character_len
                    if(clen<0.and.allocated(refs(sym)%value%s)) clen=len(refs(sym)%value%s)
                end if
                if(diag%code/=0) return
                if(.not.character_storage_fits(sym,extent,clen)) then
                    call runtime_error('CHARACTER allocation byte limit exceeded (16777216)',lin,col);return
                end if
            end if
            if(any(dims<0).or.any(dims>imax).or.extent<0.or.extent>max_array_elements) then
                call runtime_error('allocatable assignment element limit exceeded',lin,col);return
            end if
            if(shape_size(dims)/=extent) then
                call runtime_error('allocatable assignment shape differs from storage',lin,col);return
            end if
            replace=.true.
            if(allocated(refs(sym)%array%values)) then
                if(.not.array_available(sym,lin,col)) return
                old_dims=storage_dims(sym)
                replace=any(old_dims/=dims)
                if(prog%symbols(sym)%deferred_character) then
                    if(.not.allocated(refs(sym)%value%s)) then
                        call runtime_error('allocated CHARACTER target has no length descriptor',lin,col);return
                    end if
                    replace=replace.or.len(refs(sym)%value%s)/=clen
                end if
            end if
            lo=1_int64;hi=dims
            if(.not.replace) then
                lo=[refs(sym)%array%lower_bound,refs(sym)%array%lower_bound2,refs(sym)%array%lower_bound3]
                hi=[refs(sym)%array%upper_bound,refs(sym)%array%upper_bound2,refs(sym)%array%upper_bound3]
            else if(prog%expressions(root)%kind==ex_variable.and..not.prog%expressions(root)%parenthesized) then
                source=prog%expressions(root)%symbol
                if(.not.valid_symbol(source)) return
                if(.not.prog%symbols(source)%is_parameter) then
                    if(.not.array_available(source,lin,col)) return
                end if
                do d=1,prog%symbols(sym)%rank
                    if(dims(d)==0) cycle
                    if(d==1) lo(d)=refs(source)%array%lower_bound
                    if(d==2) lo(d)=refs(source)%array%lower_bound2
                    if(d==3) lo(d)=refs(source)%array%lower_bound3
                end do
                hi=lo+dims-1_int64
            end if
            ! Local frames have separate pools. All modules share one pool,
            ! matching initial module storage and explicit ALLOCATE accounting.
            live=0_int64
            do j=1,prog%ns
                if(j==sym) cycle
                if(prog%symbols(sym)%scope<0) then
                    if(prog%symbols(j)%scope>=0) cycle
                else
                    if(prog%symbols(j)%scope/=prog%symbols(sym)%scope) cycle
                end if
                if(allocated(refs(j)%array%values)) live=live+size(refs(j)%array%values,kind=int64)
            end do
            if(live>max_array_elements-extent) then
                call runtime_error('total array element limit exceeded during allocatable assignment',lin,col);return
            end if
            allocate(fresh%values(int(extent)),fresh%initialized(int(extent)),stat=ios)
            if(ios/=0) then
                call runtime_error('allocatable assignment temporary allocation failed',lin,col);return
            end if
            do j=1,int(extent)
                v=evaluate(root,0,j)
                if(diag%code/=0) return
                fresh%values(j)=convert(v,prog%symbols(sym)%typ,lin,col,prog%symbols(sym)%real_kind)
                if(diag%code/=0) return
                if(prog%symbols(sym)%typ==ty_character) then
                    if(.not.allocated(fresh%values(j)%s)) then
                        call runtime_error('invalid CHARACTER assignment value',lin,col);return
                    end if
                    fresh%values(j)%s=fresh%values(j)%s(:min(clen,len(fresh%values(j)%s)))// &
                        repeat(' ',max(0,clen-len(fresh%values(j)%s)))
                end if
                if(diag%code/=0) return
            end do
            fresh%initialized=.true.
            if(prog%symbols(sym)%typ==ty_character) then
                refs(sym)%array%character_len=clen
                refs(sym)%value%tag=ty_character;refs(sym)%value%s=repeat(' ',clen)
            end if
            call move_alloc(fresh%values,refs(sym)%array%values)
            call move_alloc(fresh%initialized,refs(sym)%array%initialized)
            call bind_owned_storage(sym)
            refs(sym)%array%lower_bound=lo(1);refs(sym)%array%upper_bound=hi(1)
            refs(sym)%array%lower_bound2=lo(2);refs(sym)%array%upper_bound2=hi(2)
            refs(sym)%array%lower_bound3=lo(3);refs(sym)%array%upper_bound3=hi(3)
        end subroutine
        subroutine freeze_character_dummy_lengths()
            integer::s,e,n,allocation_status
            integer,allocatable::marks(:)
            type(value_t)::length_value
            if(scope<=0) return
            do s=1,prog%ns
                associate(v=>prog%symbols(s))
                if(v%scope/=scope.or.v%typ/=ty_character.or..not.v%is_dummy.or. &
                   v%character_len>=0.or.v%length_expr==0) cycle
                if(.not.valid_character_length_dummy(prog,s)) then
                    call runtime_error('invalid specification-length ALLOCATABLE CHARACTER dummy',v%line,v%column);return
                end if
                if(.not.dummy_present(s).or..not.allocated(refs(s)%value%s)) then
                    call runtime_error('missing specification-length CHARACTER argument descriptor',v%line,v%column);return
                end if
                if(.not.allocated(marks)) then
                    allocate(marks(prog%ne),stat=allocation_status)
                    if(allocation_status/=0) then
                        call runtime_error('CHARACTER dummy length validation allocation failed',v%line,v%column);return
                    end if
                end if
                e=v%length_expr;marks=0
                call validate_kind_tree(e,marks,0)
                if(diag%code/=0) return
                length_value=evaluate(e,0)
                if(diag%code/=0) return
                if(length_value%tag/=ty_integer.or.length_value%i>65536_int64) then
                    call runtime_error('CHARACTER length limit exceeded (65536)',v%line,v%column);return
                end if
                n=int(max(0_int64,length_value%i))
                if(len(refs(s)%value%s)/=n.or.refs(s)%array%character_len/=n) then
                    call runtime_error('ALLOCATABLE CHARACTER actual length differs from specification-length dummy', &
                        v%line,v%column);return
                end if
                ! Keep this verified descriptor for the entire activation,
                ! including ALLOCATE, self-reallocation, nested calls and copyout.
                end associate
            end do
        end subroutine
        logical function character_storage_fits(sym,extent,clen) result(ok)
            integer,intent(in)::sym,clen
            integer(int64),intent(in)::extent
            integer::j,n
            integer(int64)::bytes
            ok=.false.
            if(clen<0.or.clen>65536.or.extent<0.or.extent>max_array_elements) return
            bytes=extent*int(clen,int64)
            do j=1,prog%ns
                if(j==sym.or.prog%symbols(j)%typ/=ty_character) cycle
                if(prog%symbols(sym)%scope<0) then
                    if(prog%symbols(j)%scope>=0) cycle
                else
                    if(prog%symbols(j)%scope/=prog%symbols(sym)%scope) cycle
                end if
                if(.not.allocated(refs(j)%array%values)) cycle
                n=prog%symbols(j)%character_len
                if(n<0.and.allocated(refs(j)%value%s)) n=len(refs(j)%value%s)
                if(n<0.or.n>65536) return
                bytes=bytes+size(refs(j)%array%values,kind=int64)*int(n,int64)
            end do
            ok=bytes<=16777216_int64
        end function
        subroutine validate_allocatable_copyout(arguments,bindings,lin,col)
            type(argument_t),intent(in)::arguments(:)
            type(actual_binding_t),intent(in)::bindings(:)
            integer,intent(in)::lin,col
            integer::j,k,q,target_scope,clen
            integer(int64)::live,n,bytes
            logical::replaced
            ! Preflight every destination pool before moving any descriptors.
            do j=1,size(bindings)
                if(.not.bindings(j)%allocatable_descriptor.or..not.bindings(j)%writable) cycle
                target_scope=prog%symbols(bindings(j)%symbol)%scope;live=0_int64;bytes=0_int64
                do k=1,prog%ns
                    if(target_scope<0) then
                        if(prog%symbols(k)%scope>=0) cycle
                    else
                        if(prog%symbols(k)%scope/=target_scope) cycle
                    end if
                    replaced=.false.;n=0_int64;clen=0
                    do q=1,size(bindings)
                        if(.not.bindings(q)%allocatable_descriptor.or..not.bindings(q)%writable) cycle
                        if(bindings(q)%symbol/=k) cycle
                        replaced=.true.
                        if(arguments(q)%is_allocated) then
                            n=size(arguments(q)%values,kind=int64)
                            if(prog%symbols(k)%typ==ty_character) clen=arguments(q)%character_len
                        end if
                    end do
                    if(.not.replaced) then
                        if(allocated(refs(k)%array%values)) then
                            n=size(refs(k)%array%data,kind=int64)
                            if(prog%symbols(k)%typ==ty_character) then
                                clen=prog%symbols(k)%character_len
                                if(clen<0.and.allocated(refs(k)%value%s)) clen=len(refs(k)%value%s)
                            end if
                        end if
                    end if
                    if(clen<0.or.clen>65536) then
                        call runtime_error('invalid CHARACTER copyout length descriptor',lin,col);return
                    end if
                    bytes=bytes+n*int(clen,int64)
                    if(bytes>16777216_int64.and.prog%symbols(bindings(j)%symbol)%typ==ty_character) then
                        call runtime_error('CHARACTER allocation byte limit exceeded at copyout (16777216)',lin,col);return
                    end if
                    live=live+n
                    if(live>max_array_elements) then
                        call runtime_error('total array element limit exceeded by allocatable argument copyout',lin,col);return
                    end if
                end do
            end do
        end subroutine
        logical function valid_descriptor_symbol(index) result(ok)
            integer,intent(in)::index
            ! Descriptor access is not pointee access, but still requires a
            ! present actual. Shape validation/PRESENT use separate absent paths.
            ok=valid_symbol(index,.true.)
            if(.not.ok) return
            if(.not.dummy_present(index)) then
                ok=.false.;call runtime_error('reference to absent OPTIONAL dummy', &
                    prog%symbols(index)%line,prog%symbols(index)%column)
            end if
        end function
        subroutine nullify_view(view)
            type(array_storage_t),intent(inout)::view
            nullify(view%data,view%flags)
            view%borrowed=.true.;view%can_alias=.false.;view%pointer_state=-1
            view%owner_depth=-1;view%owner_generation=0_int64;view%owner_symbol=0
            view%lower_bound=1;view%upper_bound=0
            view%lower_bound2=1;view%upper_bound2=1;view%lower_bound3=1;view%upper_bound3=1
        end subroutine
        logical function valid_view_owner(view,lin,col) result(ok)
            type(array_storage_t),intent(in)::view
            integer,intent(in)::lin,col
            integer::d
            ok=.false.;d=view%owner_depth
            if(d<0.or.d>64.or.view%owner_symbol<1.or.view%owner_symbol>prog%ns) then
                call runtime_error('invalid pointer backing identity',lin,col);return
            end if
            if(.not.context%live(d).or.context%generation(d)/=view%owner_generation) then
                call runtime_error('POINTER target lifetime has expired',lin,col);return
            end if
            ! Do not inspect Fortran pointer association status before the token:
            ! expired local targets make the raw component pointer undefined.
            if(.not.associated(view%data).or..not.associated(view%flags)) then
                call runtime_error('missing pointer backing view',lin,col);return
            end if
            if(size(view%data)/=size(view%flags).or.size(view%data)>max_array_elements) then
                call runtime_error('invalid pointer backing view extent',lin,col);return
            end if
            ok=.true.
        end function
        subroutine copy_alias_view(dst,src,lin,col)
            type(array_storage_t),intent(inout)::dst
            type(array_storage_t),intent(in)::src
            integer,intent(in)::lin,col
            if(src%pointer_state==1.or.src%can_alias) then
                if(.not.valid_view_owner(src,lin,col)) return
                dst%data=>src%data;dst%flags=>src%flags
            else
                nullify(dst%data,dst%flags)
            end if
            dst%borrowed=.true.;dst%can_alias=src%can_alias
            dst%pointer_state=src%pointer_state
            dst%owner_depth=src%owner_depth;dst%owner_generation=src%owner_generation;dst%owner_symbol=src%owner_symbol
            dst%lower_bound=src%lower_bound;dst%upper_bound=src%upper_bound
            dst%lower_bound2=src%lower_bound2;dst%upper_bound2=src%upper_bound2
            dst%lower_bound3=src%lower_bound3;dst%upper_bound3=src%upper_bound3
        end subroutine
        subroutine pointer_assignment(ins)
            type(instruction_t),intent(in)::ins
            integer::p,s,root,n,first,last,step,k
            integer(int64)::lo
            type(array_storage_t)::view
            p=ins%symbol;root=ins%a
            if(.not.valid_descriptor_symbol(p)) return
            if(.not.prog%symbols(p)%is_pointer.or.prog%symbols(p)%dummy_intent==1.or. &
               ins%b/=0.or.ins%c/=0.or.ins%d/=0.or.ins%third/=0.or.ins%component/=0.or. &
               ins%target/=0.or.ins%generic_id/=0.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
               allocated(ins%items).or.allocated(ins%format).or.len_trim(ins%construct_name)/=0) then
                call runtime_error('invalid POINTER association target',ins%line,ins%column);return
            end if
            if(.not.valid_expression(root)) return
            if(prog%expressions(root)%kind==ex_call.and.prog%expressions(root)%op=='null') then
                if(.not.allocated(prog%expressions(root)%args)) then
                    call runtime_error('missing NULL operands',ins%line,ins%column);return
                end if
                if(size(prog%expressions(root)%args)/=0.or.prog%expressions(root)%typ/=0.or. &
                   prog%expressions(root)%rank/=0.or.prog%expressions(root)%real_kind/=4.or. &
                   prog%expressions(root)%extent/=0.or.any(prog%expressions(root)%dims/=0).or. &
                   prog%expressions(root)%parenthesized.or..not.clean_pointer_call(root)) then
                    call runtime_error('invalid NULL pointer descriptor',ins%line,ins%column);return
                end if
                call nullify_view(refs(p)%array);return
            end if
            associate(e=>prog%expressions(root))
            if(e%parenthesized.or.(e%kind/=ex_variable.and.e%kind/=ex_section).or.e%rank/=1.or. &
               e%typ/=prog%symbols(p)%typ.or.e%real_kind/=prog%symbols(p)%real_kind) then
                call runtime_error('POINTER requires a conforming rank-one target view',ins%line,ins%column);return
            end if
            s=e%symbol
            if(.not.valid_descriptor_symbol(s)) return
            if((.not.prog%symbols(s)%is_target.and..not.prog%symbols(s)%is_pointer).or. &
               prog%symbols(s)%is_allocatable.or.prog%symbols(s)%is_automatic.or. &
               prog%symbols(s)%scope<0.or.prog%symbols(s)%rank>2.or. &
               (prog%symbols(s)%is_pointer.and.e%kind/=ex_variable)) then
                call runtime_error('POINTER target requires fixed local/caller TARGET storage',ins%line,ins%column);return
            end if
            if(e%typ/=prog%symbols(s)%typ.or.e%real_kind/=prog%symbols(s)%real_kind.or. &
               prog%symbols(s)%rank<1) then
                call runtime_error('POINTER target metadata differs from declaration',ins%line,ins%column);return
            end if
            if(prog%symbols(s)%is_pointer) then
                if(e%extent/=-1.or.any(e%dims/=0).or.e%left/=0.or.e%right/=0.or.e%stride/=0.or. &
                   e%left2/=0.or.e%right2/=0.or.e%stride2/=0.or.allocated(e%args)) then
                    call runtime_error('invalid whole POINTER descriptor metadata',ins%line,ins%column);return
                end if
                if(refs(s)%array%pointer_state==-1) then
                    call nullify_view(refs(p)%array);return
                end if
            end if
            if(.not.array_available(s,ins%line,ins%column)) return
            if(.not.refs(s)%array%can_alias) then
                call runtime_error('TARGET dummy lacks shareable caller backing storage',ins%line,ins%column);return
            end if
            lo=1_int64;first=1;step=1;n=size(refs(s)%array%data)
            if(e%kind==ex_variable) then
                if(prog%symbols(s)%rank/=1) then
                    call runtime_error('whole POINTER target must have rank one',ins%line,ins%column);return
                end if
                if(any(e%dims/=0).or.e%left/=0.or.e%right/=0.or.e%stride/=0.or. &
                   e%left2/=0.or.e%right2/=0.or.e%stride2/=0.or.allocated(e%args)) then
                    call runtime_error('invalid whole POINTER target metadata',ins%line,ins%column);return
                end if
                if(prog%symbols(s)%is_pointer.or.prog%symbols(s)%assumed_shape) then
                    if(e%extent/=-1) then
                        call runtime_error('dynamic POINTER target extent differs',ins%line,ins%column);return
                    end if
                else if(e%extent/=n) then
                    call runtime_error('fixed POINTER target extent differs',ins%line,ins%column);return
                end if
                if(n>0) lo=refs(s)%array%lower_bound
            else
                call prepare_expression(root,0)
                if(diag%code/=0) return
                n=int(shape_extent(root))
                if(n>0) first=section_offset(root,1)
                if(n>1) step=section_offset(root,2)-first
                if(diag%code/=0) return
                do k=1,n
                    if(section_offset(root,k)/=first+(k-1)*step) then
                        call runtime_error('POINTER section is not a linear rank-one view',ins%line,ins%column);return
                    end if
                end do
            end if
            if(step==0) then
                call runtime_error('POINTER section stride is zero',ins%line,ins%column);return
            end if
            last=first+(n-1)*step
            if(n>0) then
                if(min(first,last)<1.or.max(first,last)>size(refs(s)%array%data)) then
                    call runtime_error('POINTER section exceeds backing storage',ins%line,ins%column);return
                end if
            else
                first=1;last=0;step=1
            end if
            call copy_alias_view(view,refs(s)%array,ins%line,ins%column)
            if(diag%code/=0) return
            view%data=>refs(s)%array%data(first:last:step)
            view%flags=>refs(s)%array%flags(first:last:step)
            view%pointer_state=1;view%can_alias=.true.
            view%lower_bound=lo;view%upper_bound=lo+int(n,int64)-1
            view%lower_bound2=1;view%upper_bound2=1;view%lower_bound3=1;view%upper_bound3=1
            call copy_alias_view(refs(p)%array,view,ins%line,ins%column)
            end associate
        end subroutine
        logical function clean_pointer_call(index) result(ok)
            integer,intent(in)::index
            associate(e=>prog%expressions(index))
            ok=e%kind==ex_call.and.e%symbol==0.and.e%left==0.and.e%right==0.and.e%stride==0.and. &
               e%left2==0.and.e%right2==0.and.e%stride2==0.and.e%left3==0.and.e%right3==0.and. &
               e%stride3==0.and.e%third==0.and.e%length_expr==0.and.e%character_len==-1.and. &
               e%generic_id==0.and.e%bound_type==0.and.e%bound_binding==0.and.e%intrinsic_mask==0
            end associate
        end function
        subroutine validate_associated_metadata(index)
            integer,intent(in)::index
            integer::j,a,s,p
            if(.not.valid_expression(index)) return
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing ASSOCIATED arguments',e%line,e%column);return
            end if
            if(size(e%args)<1.or.size(e%args)>2.or.e%typ/=ty_logical.or.e%rank/=0.or.e%real_kind/=4.or. &
               e%extent/=0.or.any(e%dims/=0).or.e%scope<0.or.e%scope>prog%np.or. &
               any(e%triplet.neqv.[.true.,.false.,.false.]).or..not.clean_pointer_call(index)) then
                call runtime_error('invalid ASSOCIATED descriptor metadata',e%line,e%column);return
            end if
            p=0
            do j=1,size(e%args)
                a=e%args(j)
                if(.not.valid_expression(a)) return
                s=prog%expressions(a)%symbol
                if(.not.valid_symbol(s,allow_absent=.true.)) return
                associate(x=>prog%expressions(a),sym=>prog%symbols(s))
                if(x%scope/=e%scope.or.x%parenthesized.or.(x%kind/=ex_variable.and.x%kind/=ex_section).or.x%rank/=1.or. &
                   x%typ/=sym%typ.or.x%real_kind/=sym%real_kind.or. &
                   allocated(x%args).or.any(x%dims/=0).or.x%third/=0.or.x%left3/=0.or.x%right3/=0.or. &
                   x%stride3/=0.or.x%length_expr/=0.or.x%character_len/=-1.or.x%generic_id/=0.or. &
                   x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or.len_trim(x%op)/=0) then
                    call runtime_error('invalid ASSOCIATED argument designator metadata',e%line,e%column);return
                end if
                if(j==1.or.sym%is_pointer) then
                    if(.not.sym%is_pointer.or.x%kind/=ex_variable.or.x%extent/=-1) then
                        call runtime_error('ASSOCIATED POINTER requires a whole pointer variable',e%line,e%column);return
                    end if
                else if(.not.sym%is_target.or.sym%is_allocatable.or.sym%is_automatic.or. &
                        sym%scope<0.or.sym%rank<1.or.sym%rank>2) then
                    call runtime_error('ASSOCIATED TARGET requires fixed local/caller TARGET storage',e%line,e%column);return
                end if
                if(j==1) then
                    p=s
                else if(sym%typ/=prog%symbols(p)%typ.or.sym%real_kind/=prog%symbols(p)%real_kind) then
                    call runtime_error('ASSOCIATED target type/kind differs from pointer',e%line,e%column);return
                end if
                if(x%kind==ex_variable) then
                    if(sym%rank/=1.or.x%left/=0.or.x%right/=0.or.x%stride/=0.or.x%left2/=0.or. &
                       x%right2/=0.or.x%stride2/=0.or.any(x%triplet.neqv.[.true.,.false.,.false.])) then
                        call runtime_error('invalid whole ASSOCIATED argument metadata',e%line,e%column);return
                    end if
                    if(sym%is_pointer.or.sym%assumed_shape) then
                        if(x%extent/=-1) then
                            call runtime_error('invalid dynamic ASSOCIATED extent',e%line,e%column);return
                        end if
                    else if(x%extent/=max(0_int64,sym%upper_bound-sym%lower_bound+1_int64)) then
                        call runtime_error('invalid fixed ASSOCIATED extent',e%line,e%column);return
                    end if
                else
                    if(x%extent/=-1.or.x%triplet(3).or.sum(merge(1,0,x%triplet(:sym%rank)))/=1) then
                        call runtime_error('invalid ASSOCIATED section metadata',e%line,e%column);return
                    end if
                    if(sym%rank==1.and.(x%triplet(2).or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0)) then
                        call runtime_error('invalid ASSOCIATED inactive section dimension',e%line,e%column);return
                    end if
                end if
                end associate
            end do
            end associate
        end subroutine
        integer function associated_pointer_status(sym,lin,col) result(state)
            integer,intent(in)::sym,lin,col
            state=0
            if(.not.valid_descriptor_symbol(sym)) return
            state=refs(sym)%array%pointer_state
            if(state==0) then
                call runtime_error('POINTER association status is undefined',lin,col);return
            end if
            if(state==-1) return
            if(state/=1) then
                call runtime_error('invalid POINTER association status',lin,col);return
            end if
            if(.not.valid_view_owner(refs(sym)%array,lin,col)) state=0
        end function
        subroutine associated_value(index,value)
            integer,intent(in)::index
            type(value_t),intent(out)::value
            type(value_t),pointer::element
            integer::p,t,root,pstate,tstate,n,k,offset
            call validate_associated_metadata(index)
            if(diag%code/=0) return
            value=value_t(tag=ty_logical,l=.false.)
            associate(e=>prog%expressions(index))
            p=prog%expressions(e%args(1))%symbol
            pstate=associated_pointer_status(p,e%line,e%column)
            if(diag%code/=0) return
            if(size(e%args)==1) then
                value%l=pstate==1;return
            end if
            root=e%args(2);t=prog%expressions(root)%symbol
            ! An absent whole optional nonpointer TARGET is an omitted optional
            ! actual (F2018 15.5.2.12p4,16.2.1p2,16.9.16p5 case(i)). A section
            ! of an absent argument is not such an actual. Absent POINTER
            ! targets remain outside this bounded forwarding extension.
            if(prog%expressions(root)%kind==ex_variable.and.prog%symbols(t)%is_optional.and. &
               .not.prog%symbols(t)%is_pointer.and..not.dummy_present(t)) then
                value%l=pstate==1;return
            end if
            ! Validate both descriptors even if POINTER is disassociated. No
            ! raw pointer may be inspected before its owner generation check.
            if(.not.valid_descriptor_symbol(t)) return
            tstate=1
            if(prog%symbols(t)%is_pointer) then
                tstate=associated_pointer_status(t,e%line,e%column)
                if(diag%code/=0) return
                if(tstate==-1) return
            else
                if(.not.array_available(t,e%line,e%column)) return
                if(.not.refs(t)%array%can_alias) then
                    call runtime_error('ASSOCIATED TARGET lacks shareable caller backing storage',e%line,e%column);return
                end if
                if(.not.valid_view_owner(refs(t)%array,e%line,e%column)) return
            end if
            call prepare_expression(root,0)
            if(diag%code/=0) return
            n=int(shape_extent(root))
            if(pstate==-1.or.n==0) return
            if(n/=size(refs(p)%array%data)) return
            if(.not.same_backing(p,t)) return
            do k=1,n
                call consume(e%line,e%column)
                if(diag%code/=0) return
                offset=k
                if(prog%expressions(root)%kind==ex_section) offset=section_offset(root,k)
                if(diag%code/=0) return
                if(offset<1.or.offset>size(refs(t)%array%data)) then
                    call runtime_error('ASSOCIATED element mapping exceeds backing storage',e%line,e%column);return
                end if
                ! Scalar association compares storage identity without reading
                ! a value/defined flag. Element-by-element mapping ignores lower
                ! bounds and irrelevant singleton strides but preserves order.
                element=>refs(p)%array%data(k)
                if(.not.associated(element,refs(t)%array%data(offset))) return
            end do
            value%l=.true.
            end associate
        end subroutine
        logical function same_backing(a,b) result(same)
            integer,intent(in)::a,b
            same=a==b
            if(a<1.or.b<1.or.a>prog%ns.or.b>prog%ns) return
            if(prog%symbols(a)%rank==0.or.prog%symbols(b)%rank==0) return
            if(refs(a)%array%owner_depth<0.or.refs(b)%array%owner_depth<0) return
            same=refs(a)%array%owner_depth==refs(b)%array%owner_depth.and. &
                refs(a)%array%owner_generation==refs(b)%array%owner_generation.and. &
                refs(a)%array%owner_symbol==refs(b)%array%owner_symbol
        end function
        subroutine bind_owned_storage(sym)
            integer,intent(in)::sym
            if(refs(sym)%array%borrowed) return
            nullify(refs(sym)%array%data,refs(sym)%array%flags)
            if(.not.allocated(refs(sym)%array%values).or..not.allocated(refs(sym)%array%initialized)) return
            refs(sym)%array%data=>refs(sym)%array%values
            refs(sym)%array%flags=>refs(sym)%array%initialized
            refs(sym)%array%owner_depth=frame_depth
            refs(sym)%array%owner_generation=context%generation(frame_depth)
            refs(sym)%array%owner_symbol=sym
            refs(sym)%array%can_alias=prog%symbols(sym)%is_target.and..not.prog%symbols(sym)%is_allocatable.and. &
                .not.prog%symbols(sym)%is_dummy.and..not.prog%symbols(sym)%is_automatic.and.prog%symbols(sym)%scope>=0
        end subroutine
        logical function array_available(sym,lin,col) result(ok)
            integer,intent(in)::sym,lin,col
            ok=.false.
            if(prog%symbols(sym)%is_pointer) then
                if(refs(sym)%array%pointer_state/=1) then
                    call runtime_error('POINTER is undefined or disassociated',lin,col);return
                end if
            end if
            if(refs(sym)%array%borrowed) then
                if(.not.valid_view_owner(refs(sym)%array,lin,col)) return
            else
                call bind_owned_storage(sym)
            end if
            if(.not.associated(refs(sym)%array%data).or..not.associated(refs(sym)%array%flags)) then
                call runtime_error('reference to unallocated array '//trim(prog%symbols(sym)%name),lin,col);return
            end if
            if(size(refs(sym)%array%data)/=size(refs(sym)%array%flags)) then
                call runtime_error('invalid array allocation descriptor',lin,col);return
            end if
            if(prog%symbols(sym)%rank==0) then
                if(.not.prog%symbols(sym)%is_allocatable.or.prog%symbols(sym)%typ/=ty_character.or. &
                   size(refs(sym)%array%data)/=1.or.any(storage_dims(sym)/=1_int64)) then
                    call runtime_error('invalid scalar CHARACTER allocation descriptor',lin,col);return
                end if
            end if
            ok=.true.
        end function
        subroutine allocated_value(index,value)
            integer,intent(in)::index
            type(value_t),intent(out)::value
            integer::child,s
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing ALLOCATED argument',e%line,e%column);return
            end if
            if(size(e%args)/=1.or.e%rank/=0.or.e%typ/=ty_logical.or.e%real_kind/=4) then
                call runtime_error('invalid ALLOCATED metadata',e%line,e%column);return
            end if
            child=e%args(1)
            if(.not.valid_expression(child)) return
            s=prog%expressions(child)%symbol
            if(prog%expressions(child)%kind/=ex_variable.or.prog%expressions(child)%parenthesized) then
                call runtime_error('ALLOCATED requires a whole allocatable array',e%line,e%column);return
            end if
            if(.not.valid_symbol(s)) return
            if(.not.prog%symbols(s)%is_allocatable.or.prog%symbols(s)%rank<0.or.prog%symbols(s)%rank>3.or. &
               (prog%symbols(s)%rank==0.and.prog%symbols(s)%typ/=ty_character)) then
                call runtime_error('ALLOCATED requires an allocatable array',e%line,e%column);return
            end if
            if(present(constant_index)) then
                call runtime_error('ALLOCATED is not a constant expression',e%line,e%column);return
            end if
            value%tag=ty_logical;value%l=allocated(refs(s)%array%values)
            end associate
        end subroutine
        subroutine validate_allocation_outputs(ins,stat_sym,errmsg_sym)
            type(instruction_t),intent(in)::ins
            integer,intent(out)::stat_sym,errmsg_sym
            integer::q,root,t,s,k,typ
            stat_sym=0;errmsg_sym=0;s=ins%symbol
            if(.not.valid_allocation_message(prog,ins))then
                call runtime_error('invalid ERRMSG control or allocation bound dependencies',ins%line,ins%column);return
            end if
            do q=1,2
                root=ins%a;typ=ty_integer
                if(q==2)then
                    root=ins%third;typ=ty_character
                end if
                if(root==0)cycle
                if(.not.valid_expression(root))return
                if(.not.valid_allocation_output(prog,root,typ,scope))then
                    call runtime_error('invalid allocation status target metadata',ins%line,ins%column);return
                end if
                t=prog%expressions(root)%symbol
                if(.not.valid_symbol(t))return
                if(refs(t)%active)then
                    call runtime_error('allocation status target is an active DO variable',ins%line,ins%column);return
                end if
                if(associated(refs(t)%value,refs(s)%value).or.associated(refs(t)%array,refs(s)%array))then
                    call runtime_error('allocation status target aliases an allocation object',ins%line,ins%column);return
                end if
                if(prog%symbols(t)%is_saved.or.captured(t))call check_external_effect(ins%line,ins%column)
                if(diag%code/=0)return
                if(q==1)then
                    stat_sym=t
                else
                    errmsg_sym=t
                    if(stat_sym>0)then
                        if(associated(refs(t)%value,refs(stat_sym)%value))then
                            call runtime_error('allocation STAT and ERRMSG alias',ins%line,ins%column);return
                        end if
                    end if
                    if(prog%symbols(t)%is_allocatable)then
                        if(.not.array_available(t,ins%line,ins%column))return
                    end if
                    ! Validate storage without reading its undefined contents.
                    k=prog%symbols(t)%character_len
                    if(k<0.and.allocated(refs(t)%value%s))k=len(refs(t)%value%s)
                    if(k<0.or.k>65536.or..not.allocated(refs(t)%value%s))then
                        call runtime_error('invalid fixed-length ERRMSG storage',ins%line,ins%column);return
                    end if
                    if(len(refs(t)%value%s)/=k)then
                        call runtime_error('ERRMSG length descriptor differs',ins%line,ins%column);return
                    end if
                end if
            end do
        end subroutine
        subroutine finish_allocation_outputs(stat_sym,errmsg_sym,status,failure,lin,col)
            integer,intent(in)::stat_sym,errmsg_sym,status,lin,col
            character(*),intent(in)::failure
            type(value_t)::message
            ! Successful statements do not define or change ERRMSG.
            if(status/=0.and.errmsg_sym>0)then
                message%tag=ty_character;message%s=failure
                call fit_character(message,errmsg_sym,lin,col)
                if(diag%code/=0)return
                refs(errmsg_sym)%value=message;refs(errmsg_sym)%defined=.true.
            end if
            if(stat_sym>0)then
                refs(stat_sym)%value=value_t(tag=ty_integer,real_kind=prog%symbols(stat_sym)%real_kind,i=int(status,int64))
                refs(stat_sym)%defined=.true.
            else if(status/=0)then
                call runtime_error(failure,lin,col)
            end if
        end subroutine
        subroutine execute_move_alloc(ins)
            type(instruction_t),intent(in)::ins
            type(value_t)::character_value
            integer::from,to,s,j,e,clen,tlen,nchar
            integer(int64)::live,bytes,n,lo(3),hi(3),dims(3)
            logical::source_allocated,source_defined
            if(.not.valid_move_alloc(prog,ins)) then
                call runtime_error('invalid MOVE_ALLOC instruction metadata',ins%line,ins%column);return
            end if
            do j=1,2
                e=ins%items(j)
                if(.not.valid_expression(e)) return
                s=prog%expressions(e)%symbol
                if(.not.valid_symbol(s)) return
                if(prog%symbols(s)%scope<0.or.prog%symbols(s)%is_saved.or.captured(s)) &
                    call check_external_effect(ins%line,ins%column)
                if(diag%code/=0) return
                if(refs(s)%array%borrowed.or.refs(s)%array%can_alias.or.refs(s)%array%pointer_state/=0) then
                    call runtime_error('MOVE_ALLOC requires an owned allocatable descriptor',ins%line,ins%column);return
                end if
                if(allocated(refs(s)%array%values).neqv.allocated(refs(s)%array%initialized)) then
                    call runtime_error('invalid MOVE_ALLOC allocation descriptor',ins%line,ins%column);return
                end if
                if(allocated(refs(s)%array%values)) then
                    if(.not.array_available(s,ins%line,ins%column)) return
                    dims=storage_dims(s);n=size(refs(s)%array%values,kind=int64)
                    lo=[refs(s)%array%lower_bound,refs(s)%array%lower_bound2,refs(s)%array%lower_bound3]
                    hi=[refs(s)%array%upper_bound,refs(s)%array%upper_bound2,refs(s)%array%upper_bound3]
                    if(n>max_array_elements.or.any(dims>imax).or.shape_size(dims)/=n.or. &
                       any(lo<imin).or.any(lo>imax).or.any(hi<imin-1_int64).or.any(hi>imax)) then
                        call runtime_error('invalid MOVE_ALLOC allocation shape',ins%line,ins%column);return
                    end if
                    do e=1,3
                        if(hi(e)<imin.and.dims(e)/=0) then
                            call runtime_error('invalid MOVE_ALLOC empty upper bound',ins%line,ins%column);return
                        end if
                    end do
                else if(associated(refs(s)%array%data).or.associated(refs(s)%array%flags)) then
                    call runtime_error('invalid unallocated MOVE_ALLOC descriptor',ins%line,ins%column);return
                end if
                if(prog%symbols(s)%typ==ty_character) then
                    if(.not.prog%symbols(s)%deferred_character.or.allocated(refs(s)%array%values)) then
                        if(.not.allocated(refs(s)%value%s)) then
                            call runtime_error('missing MOVE_ALLOC CHARACTER length descriptor',ins%line,ins%column);return
                        end if
                        nchar=len(refs(s)%value%s)
                        if(nchar>65536.or.(prog%symbols(s)%character_len>=0.and. &
                           nchar/=prog%symbols(s)%character_len)) then
                            call runtime_error('invalid MOVE_ALLOC CHARACTER length descriptor',ins%line,ins%column);return
                        end if
                        if(allocated(refs(s)%array%values)) then
                            if(refs(s)%array%character_len/=nchar) then
                                call runtime_error('inconsistent MOVE_ALLOC CHARACTER descriptor',ins%line,ins%column);return
                            end if
                        end if
                    end if
                end if
            end do
            from=prog%expressions(ins%items(1))%symbol;to=prog%expressions(ins%items(2))%symbol
            if(associated(refs(from)%array,refs(to)%array).or.associated(refs(from)%value,refs(to)%value)) then
                call runtime_error('MOVE_ALLOC arguments alias the same allocation',ins%line,ins%column);return
            end if
            source_allocated=allocated(refs(from)%array%values)
            source_defined=refs(from)%defined;clen=-1
            if(prog%symbols(from)%typ==ty_character) then
                if(source_allocated.or..not.prog%symbols(from)%deferred_character) clen=len(refs(from)%value%s)
                if(.not.prog%symbols(to)%deferred_character) then
                    if(clen<0) then
                        call runtime_error('unallocated deferred-length FROM requires deferred-length TO',ins%line,ins%column);return
                    end if
                    tlen=len(refs(to)%value%s)
                    if(clen/=tlen) then
                        call runtime_error('MOVE_ALLOC CHARACTER lengths must agree for nondeferred TO',ins%line,ins%column);return
                    end if
                end if
            end if
            ! Preflight the destination live region, excluding both replaced
            ! allocations. Moving a payload within one region must not count it twice.
            live=0_int64;bytes=0_int64
            do j=1,prog%ns
                if(j==from.or.j==to) cycle
                if(prog%symbols(to)%scope<0) then
                    if(prog%symbols(j)%scope>=0) cycle
                else
                    if(prog%symbols(j)%scope/=prog%symbols(to)%scope) cycle
                end if
                if(.not.allocated(refs(j)%array%values)) cycle
                n=size(refs(j)%array%values,kind=int64);live=live+n
                if(prog%symbols(j)%typ==ty_character) then
                    if(.not.allocated(refs(j)%value%s)) then
                        call runtime_error('invalid CHARACTER storage descriptor during MOVE_ALLOC',ins%line,ins%column);return
                    end if
                    nchar=len(refs(j)%value%s)
                    if(nchar>65536) then
                        call runtime_error('invalid CHARACTER length during MOVE_ALLOC',ins%line,ins%column);return
                    end if
                    bytes=bytes+n*int(nchar,int64)
                end if
            end do
            if(source_allocated) then
                n=size(refs(from)%array%values,kind=int64);live=live+n
                if(clen>=0) bytes=bytes+n*int(clen,int64)
            end if
            if(live>max_array_elements.or.bytes>16777216_int64) then
                call runtime_error('MOVE_ALLOC destination storage limit exceeded',ins%line,ins%column);return
            end if
            ! No element evaluation or payload copy: undefined flags move with
            ! the allocation. Only the bounded scalar CHARACTER metadata/value
            ! is prepared before either descriptor is changed.
            if(source_allocated.and.prog%symbols(from)%typ==ty_character) character_value=refs(from)%value
            lo=[refs(from)%array%lower_bound,refs(from)%array%lower_bound2,refs(from)%array%lower_bound3]
            hi=[refs(from)%array%upper_bound,refs(from)%array%upper_bound2,refs(from)%array%upper_bound3]
            nullify(refs(to)%array%data,refs(to)%array%flags)
            call move_alloc(refs(from)%array%values,refs(to)%array%values)
            call move_alloc(refs(from)%array%initialized,refs(to)%array%initialized)
            nullify(refs(from)%array%data,refs(from)%array%flags)
            refs(from)%array%lower_bound=1_int64;refs(from)%array%upper_bound=0_int64
            refs(from)%array%lower_bound2=1_int64;refs(from)%array%upper_bound2=0_int64
            refs(from)%array%lower_bound3=1_int64;refs(from)%array%upper_bound3=0_int64
            refs(from)%defined=.false.;refs(to)%defined=.false.
            if(source_allocated) then
                refs(to)%array%lower_bound=lo(1);refs(to)%array%upper_bound=hi(1)
                refs(to)%array%lower_bound2=lo(2);refs(to)%array%upper_bound2=hi(2)
                refs(to)%array%lower_bound3=lo(3);refs(to)%array%upper_bound3=hi(3)
                refs(to)%array%character_len=clen
                refs(to)%defined=source_defined
                if(prog%symbols(to)%typ==ty_character) then
                    refs(to)%value%tag=ty_character;refs(to)%value%real_kind=4
                    call move_alloc(character_value%s,refs(to)%value%s)
                end if
                call bind_owned_storage(to)
            else
                refs(to)%array%lower_bound=1_int64;refs(to)%array%upper_bound=0_int64
                refs(to)%array%lower_bound2=1_int64;refs(to)%array%upper_bound2=0_int64
                refs(to)%array%lower_bound3=1_int64;refs(to)%array%upper_bound3=0_int64
                if(prog%symbols(to)%deferred_character) then
                    if(allocated(refs(to)%value%s)) deallocate(refs(to)%value%s)
                    refs(to)%array%character_len=-1
                end if
            end if
            if(prog%symbols(from)%deferred_character) then
                if(allocated(refs(from)%value%s)) deallocate(refs(from)%value%s)
                refs(from)%array%character_len=-1
            end if
        end subroutine
        subroutine execute_allocation_group(first)
            integer,intent(in)::first
            integer::n,j,q,s,k,root,stat_sym,errmsg_sym,status
            integer,allocatable::marks(:)
            character(:),allocatable::failure
            if(.not.valid_allocation_group(prog,first)) then
                call runtime_error('invalid multi-object allocation group or bound dependencies', &
                                   prog%code(first)%line,prog%code(first)%column);return
            end if
            n=prog%code(first)%c;stat_sym=0;errmsg_sym=0;status=0
            if(first+n-1>last_pc) then
                call runtime_error('allocation group crosses call-frame boundary', &
                                   prog%code(first)%line,prog%code(first)%column);return
            end if
            ! Validate every descriptor, effect and operand tree before changing
            ! any allocation status. Execution then commits objects left-to-right.
            allocate(marks(prog%ne),source=0)
            do j=1,n
                q=first+j-1
                associate(ins=>prog%code(q))
                if(ins%scope/=scope) then
                    call runtime_error('allocation group is outside active frame',ins%line,ins%column);return
                end if
                s=ins%symbol
                if(.not.valid_symbol(s)) return
                if(prog%symbols(s)%scope<0.or.prog%symbols(s)%is_saved.or.captured(s)) &
                    call check_external_effect(ins%line,ins%column)
                if(diag%code/=0) return
                call validate_allocation_outputs(ins,stat_sym,errmsg_sym)
                if(diag%code/=0)return
                do k=0,size(ins%items)
                    root=ins%b
                    if(k>0) root=ins%items(k)
                    if(root==0) cycle
                    call validate_kind_tree(root,marks,0)
                    if(diag%code/=0) return
                    if(prog%expressions(root)%typ/=ty_integer.or.prog%expressions(root)%rank/=0) then
                        call runtime_error('allocation bound must be scalar INTEGER',ins%line,ins%column);return
                    end if
                end do
                end associate
            end do
            do j=1,n
                q=first+j-1
                if(j>1) call consume(prog%code(q)%line,prog%code(q)%column)
                if(diag%code/=0) return
                call execute_allocation(prog%code(q),status,failure)
                if(diag%code/=0.or.status/=0) exit
            end do
            if(diag%code/=0) return
            call finish_allocation_outputs(stat_sym,errmsg_sym,status,failure,prog%code(q)%line,prog%code(q)%column)
        end subroutine
        subroutine execute_allocation(ins,group_status,group_failure)
            type(instruction_t),intent(in)::ins
            integer,optional,intent(out)::group_status
            character(:),allocatable,optional,intent(out)::group_failure
            integer::s,d,j,root,stat_sym,errmsg_sym,status,ios,clen
            integer(int64)::lo(3),hi(3),dims(3),extent,live
            type(value_t)::v
            type(array_storage_t)::fresh
            character(:),allocatable::failure
            s=ins%symbol;stat_sym=0;errmsg_sym=0;status=0;failure='';clen=-1
            if(present(group_status)) group_status=0
            if(.not.valid_symbol(s)) return
            if(.not.prog%symbols(s)%is_allocatable.or.prog%symbols(s)%rank<0.or. &
               (prog%symbols(s)%rank==0.and.prog%symbols(s)%typ/=ty_character).or. &
               prog%symbols(s)%rank>3.or.prog%symbols(s)%dummy_intent==1.or. &
               prog%symbols(s)%is_parameter.or. &
               (prog%symbols(s)%typ/=ty_integer.and.prog%symbols(s)%typ/=ty_real.and. &
                prog%symbols(s)%typ/=ty_logical.and.prog%symbols(s)%typ/=ty_character)) then
                call runtime_error('invalid allocation target',ins%line,ins%column);return
            end if
            if(ins%component/=0.or.ins%generic_id/=0.or.ins%bound_type/=0.or.ins%bound_binding/=0.or. &
               len_trim(ins%construct_name)/=0.or.allocated(ins%format).or.ins%format_expr/=0.or.ins%advance_mode/=0)then
                call runtime_error('unexpected allocation instruction metadata',ins%line,ins%column);return
            end if
            if(.not.allocated(ins%items)) then
                call runtime_error('missing allocation shape metadata',ins%line,ins%column);return
            end if
            call validate_allocation_outputs(ins,stat_sym,errmsg_sym)
            if(diag%code/=0)return
            if(ins%op==op_allocate) then
                if(size(ins%items)/=2*prog%symbols(s)%rank) then
                    call runtime_error('allocation rank differs from target',ins%line,ins%column);return
                end if
                if(prog%symbols(s)%typ==ty_character) then
                    if(prog%symbols(s)%deferred_character) then
                        if(.not.valid_expression(ins%b)) return
                        if(prog%expressions(ins%b)%typ/=ty_integer.or.prog%expressions(ins%b)%rank/=0) then
                            call runtime_error('allocation CHARACTER length must be scalar INTEGER',ins%line,ins%column);return
                        end if
                        v=evaluate(ins%b,0)
                        if(diag%code/=0) return
                        if(v%i>65536_int64) then
                            status=1;failure='CHARACTER length limit exceeded (65536)'
                        else
                            clen=int(max(0_int64,v%i))
                        end if
                    else
                        if(ins%b/=0) then
                            call runtime_error('unexpected allocation CHARACTER length operand',ins%line,ins%column);return
                        end if
                        clen=prog%symbols(s)%character_len
                        if(clen<0.and.allocated(refs(s)%value%s)) clen=len(refs(s)%value%s)
                        if(clen<0.or.clen>65536) then
                            call runtime_error('invalid CHARACTER allocation length descriptor',ins%line,ins%column);return
                        end if
                    end if
                else if(ins%b/=0) then
                    call runtime_error('unexpected allocation length operand',ins%line,ins%column);return
                end if
                lo=1_int64;hi=1_int64
                do d=1,prog%symbols(s)%rank
                    do j=1,2
                        root=ins%items(2*d-2+j)
                        if(root==0.and.j==1) cycle
                        if(.not.valid_expression(root)) return
                        if(prog%expressions(root)%typ/=ty_integer.or.prog%expressions(root)%rank/=0) then
                            call runtime_error('allocation bound must be scalar INTEGER',ins%line,ins%column);return
                        end if
                        v=evaluate(root,0)
                        if(diag%code/=0) return
                        if(v%tag/=ty_integer.or.v%i<imin.or.v%i>imax) then
                            call runtime_error('allocation bound exceeds supported INTEGER range',ins%line,ins%column);return
                        end if
                        if(j==1) lo(d)=v%i
                        if(j==2) hi(d)=v%i
                    end do
                end do
                dims=max(0_int64,hi-lo+1_int64)
                ! Validate dimensions before the overflow-safe, capped three-factor product.
                if(any(dims>imax)) then
                    status=1;failure='allocation dimension extent exceeds INTEGER range'
                else
                    extent=shape_size(dims)
                    live=0_int64
                    do j=1,prog%ns
                        if(prog%symbols(s)%scope<0) then
                            if(prog%symbols(j)%scope>=0) cycle
                        else
                            if(prog%symbols(j)%scope/=prog%symbols(s)%scope) cycle
                        end if
                        if(allocated(refs(j)%array%values)) live=live+size(refs(j)%array%values,kind=int64)
                    end do
                    if(extent>max_array_elements.or.live>max_array_elements-extent) then
                        status=1;failure='total array element limit exceeded during ALLOCATE'
                    end if
                end if
                if(allocated(refs(s)%array%values)) then
                    status=1;failure='ALLOCATE target is already allocated'
                end if
                if(status==0.and.prog%symbols(s)%typ==ty_character) then
                    if(.not.character_storage_fits(s,extent,clen)) then
                        status=1;failure='CHARACTER allocation byte limit exceeded (16777216)'
                    end if
                end if
                if(status==0) then
                    allocate(fresh%values(int(extent)),fresh%initialized(int(extent)),stat=ios)
                    if(ios/=0) then
                        status=1;failure='array storage allocation failed'
                    else
                        fresh%initialized=.false.
                        if(prog%symbols(s)%rank==0) refs(s)%defined=.false.
                        if(prog%symbols(s)%typ==ty_character) then
                            refs(s)%value%tag=ty_character;refs(s)%value%s=repeat(' ',clen)
                            refs(s)%array%character_len=clen
                        end if
                        fresh%lower_bound=lo(1);fresh%upper_bound=hi(1)
                        fresh%lower_bound2=lo(2);fresh%upper_bound2=hi(2)
                        fresh%lower_bound3=lo(3);fresh%upper_bound3=hi(3)
                        call move_alloc(fresh%values,refs(s)%array%values)
                        call move_alloc(fresh%initialized,refs(s)%array%initialized)
            call bind_owned_storage(s)
                        refs(s)%array%lower_bound=lo(1);refs(s)%array%upper_bound=hi(1)
                        refs(s)%array%lower_bound2=lo(2);refs(s)%array%upper_bound2=hi(2)
                        refs(s)%array%lower_bound3=lo(3);refs(s)%array%upper_bound3=hi(3)
                    end if
                end if
            else
                if(size(ins%items)/=0) then
                    call runtime_error('DEALLOCATE has unexpected shape operands',ins%line,ins%column);return
                end if
                if(.not.allocated(refs(s)%array%values)) then
                    status=1;failure='DEALLOCATE target is not allocated'
                else
                    deallocate(refs(s)%array%values)
                    if(prog%symbols(s)%rank==0) refs(s)%defined=.false.
                    nullify(refs(s)%array%data,refs(s)%array%flags)
                    if(prog%symbols(s)%deferred_character) then
                        if(allocated(refs(s)%value%s)) deallocate(refs(s)%value%s)
                        refs(s)%array%character_len=-1
                    end if
                    if(allocated(refs(s)%array%initialized)) deallocate(refs(s)%array%initialized)
                    refs(s)%array%lower_bound=1_int64;refs(s)%array%upper_bound=0_int64
                    refs(s)%array%lower_bound2=1_int64;refs(s)%array%upper_bound2=0_int64
                    refs(s)%array%lower_bound3=1_int64;refs(s)%array%upper_bound3=0_int64
                end if
            end if
            if(present(group_status)) then
                group_status=status
                if(present(group_failure)) group_failure=failure
                return
            end if
            call finish_allocation_outputs(stat_sym,errmsg_sym,status,failure,ins%line,ins%column)
        end subroutine
        subroutine allocate_frame_array(sym)
            integer,intent(in)::sym
            integer::j,k,ios
            integer(int64)::dims(3),extent
            ! An omitted array has no descriptor or argument storage to copy.
            if(.not.dummy_present(sym)) return
            if(prog%symbols(sym)%is_allocatable.or.prog%symbols(sym)%is_pointer.or.refs(sym)%array%borrowed) return
            if (prog%symbols(sym)%rank<1.or.prog%symbols(sym)%rank>3) then
                call runtime_error('only rank-one/two/three arrays are supported',prog%symbols(sym)%line,prog%symbols(sym)%column)
                return
            end if
            if (.not.check_integer(refs(sym)%array%lower_bound,prog%symbols(sym)%line, &
                                   prog%symbols(sym)%column)) return
            if(refs(sym)%array%upper_bound>=refs(sym)%array%lower_bound.or..not.prog%symbols(sym)%assumed_shape) then
                if (.not.check_integer(refs(sym)%array%upper_bound,prog%symbols(sym)%line, &
                                       prog%symbols(sym)%column)) return
            end if
            if(prog%symbols(sym)%rank>=2) then
                if(.not.check_integer(refs(sym)%array%lower_bound2,prog%symbols(sym)%line, &
                    prog%symbols(sym)%column)) return
                if(refs(sym)%array%upper_bound2>=refs(sym)%array%lower_bound2.or..not.prog%symbols(sym)%assumed_shape) then
                    if(.not.check_integer(refs(sym)%array%upper_bound2,prog%symbols(sym)%line, &
                        prog%symbols(sym)%column)) return
                end if
            end if
            if(prog%symbols(sym)%rank==3) then
                if(.not.check_integer(refs(sym)%array%lower_bound3,prog%symbols(sym)%line,prog%symbols(sym)%column)) return
                if(refs(sym)%array%upper_bound3>=refs(sym)%array%lower_bound3.or..not.prog%symbols(sym)%assumed_shape) then
                    if(.not.check_integer(refs(sym)%array%upper_bound3,prog%symbols(sym)%line,prog%symbols(sym)%column)) return
                end if
            end if
            dims=storage_dims(sym)
            if(any(dims>imax)) then
                call runtime_error('array element limit exceeded: dimension extent exceeds INTEGER range',0,0); return
            end if
            extent=shape_size(dims)
            total_elements=total_elements+extent
            if (total_elements>max_array_elements) then
                call runtime_error('total array element limit exceeded',prog%symbols(sym)%line,prog%symbols(sym)%column)
                return
            end if
            allocate(refs(sym)%array%values(int(extent)),refs(sym)%array%initialized(int(extent)),stat=ios)
            if (ios/=0) then
                call runtime_error('array storage allocation failed',prog%symbols(sym)%line,prog%symbols(sym)%column)
                return
            end if
            call bind_owned_storage(sym)
            refs(sym)%array%flags=.false.
            if(prog%symbols(sym)%is_dummy.and.present(argument_bindings)) then
                do j=1,size(prog%procedures(scope)%args)
                    if(prog%procedures(scope)%args(j)/=sym) cycle
                    if(extent>size(argument_bindings(j)%values,kind=int64)) then
                        call runtime_error('dummy storage exceeds actual argument',0,0);return
                    end if
                    refs(sym)%array%data=argument_bindings(j)%values(:int(extent))
                    if(prog%symbols(sym)%typ==ty_character) then
                        refs(sym)%array%character_len=len(refs(sym)%value%s)
                        do k=1,int(extent)
                            if(.not.argument_bindings(j)%initialized(k)) cycle
                            call fit_character(refs(sym)%array%data(k),sym,0,0)
                            if(diag%code/=0) return
                        end do
                    end if
                    if(prog%symbols(sym)%dummy_intent/=2) &
                        refs(sym)%array%flags=argument_bindings(j)%initialized(:int(extent))
                end do
            end if
        end subroutine
        subroutine validate_len_metadata(index)
            integer,intent(in)::index
            integer::a
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('LEN arguments missing',e%line,e%column);return
            end if
            if(e%kind/=ex_call.or.e%op/='len'.or.size(e%args)/=1.or.e%typ/=ty_integer.or.e%real_kind/=4.or.e%rank/=0.or.e%extent/=0.or.any(e%dims/=0).or. &
                       e%intrinsic_mask/=0.or.e%symbol/=0.or.e%left/=0.or.e%right/=0.or.e%stride/=0.or. &
                       e%left2/=0.or.e%right2/=0.or.e%stride2/=0.or.e%left3/=0.or.e%right3/=0.or. &
                       e%stride3/=0.or.e%third/=0.or.e%length_expr/=0.or.e%generic_id/=0.or. &
                       e%bound_type/=0.or.e%bound_binding/=0.or.e%character_len/=-1.or. &
                       e%constructor_kind_expr/=0.or.any(e%triplet.neqv.[.true.,.false.,.false.])) then
                call runtime_error('invalid LEN metadata',e%line,e%column);return
            end if
            a=e%args(1)
            if(.not.valid_expression(a)) return
            if(prog%expressions(a)%typ/=ty_character.or.prog%expressions(a)%real_kind/=4) then
                call runtime_error('LEN requires default CHARACTER',e%line,e%column);return
            end if
            if(prog%expressions(a)%kind==ex_variable) then
                if(.not.valid_symbol(prog%expressions(a)%symbol,allow_absent=.true.))return
                if(.not.valid_character_len_variable(prog,a))then
                    call runtime_error('invalid LEN variable metadata',e%line,e%column);return
                end if
            end if
            end associate
        end subroutine
        subroutine len_value(index,depth,value)
            integer,intent(in)::index,depth
            type(value_t),intent(out)::value
            integer::n
            call validate_len_metadata(index)
            if(diag%code/=0)return
            n=character_length(prog%expressions(index)%args(1),depth+1)
            if(diag%code==0) value=value_t(tag=ty_integer,i=int(n,int64))
        end subroutine
        recursive integer function character_length(index,depth,checked) result(n)
            integer,intent(in)::index,depth
            logical,intent(in),optional::checked
            integer::s,k,j,lo,hi,status
            integer,allocatable::marks(:)
            type(value_t)::value
            type(diagnostic_t)::constant_diag
            n=-1
            if(depth>512) then
                call runtime_error('CHARACTER length nesting limit exceeded',0,0);return
            end if
            if(.not.valid_expression(index)) return
            if(.not.present(checked)) then
                allocate(marks(prog%ne),source=0,stat=status)
                if(status/=0) then
                    call runtime_error('CHARACTER length validation allocation failed',0,0);return
                end if
                call validate_kind_tree(index,marks,0)
                if(diag%code/=0) return
            end if
            associate(e=>prog%expressions(index))
            if(e%typ/=ty_character) then
                call runtime_error('LEN requires CHARACTER',e%line,e%column);return
            end if
            select case(e%kind)
            case(ex_component)
                k=prog%expressions(e%left)%typ-ty_derived_base
                n=prog%derived_types(k)%component_lengths(e%symbol)
                if(n<0.or.n>65536.or.e%character_len/=n) then
                    call runtime_error('invalid CHARACTER component length',e%line,e%column);return
                end if
            case(ex_substring)
                call substring_bounds(index,lo,hi,depth+1)
                if(diag%code/=0) return
                n=max(0,hi-lo+1)
            case(ex_variable,ex_element,ex_section,ex_gather_rows)
                s=e%symbol
                if(.not.valid_symbol(s)) return
                if(e%typ/=prog%symbols(s)%typ.or.e%character_len/=prog%symbols(s)%character_len) then
                    call runtime_error('CHARACTER expression length differs from declaration',e%line,e%column);return
                end if
                n=prog%symbols(s)%character_len
                if(prog%symbols(s)%deferred_character) then
                    if(.not.array_available(s,e%line,e%column)) return
                    n=refs(s)%array%character_len
                else if(n<0) then
                    ! Runtime-fixed local and assumed-length dummy parameters
                    ! are frozen independently of allocation status. Only a
                    ! genuinely deferred LEN requires allocated array storage.
                    if(allocated(refs(s)%value%s)) n=len(refs(s)%value%s)
                    if(n<0.and.prog%symbols(s)%rank>0) n=refs(s)%array%character_len
                end if
            case(ex_literal)
                if(.not.allocated(e%value%s)) then
                    call runtime_error('CHARACTER literal length is missing',e%line,e%column);return
                end if
                n=len(e%value%s)
                if(n/=e%character_len) then
                    call runtime_error('CHARACTER literal length cache differs',e%line,e%column);return
                end if
            case(ex_constructor_do,ex_constructor)
                if(.not.valid_constructor_character_metadata(prog,index)) then
                    call runtime_error('invalid CHARACTER constructor length metadata',e%line,e%column);return
                end if
                if(e%kind==ex_constructor.and.constructor_materializations==0) then
                    if(.not.valid_constructor_tree(prog,index)) then
                        call runtime_error('invalid constructor tree or lexical ownership',e%line,e%column);return
                    end if
                end if
                n=e%character_len
                if(e%op=='character') then
                    if(e%kind==ex_constructor) then
                        k=1
                        if(e%length_expr/=0) then
                            call evaluate_constant(prog,e%length_expr,value,constant_diag)
                            if(constant_diag%code/=0.or.value%tag/=ty_integer) then
                                call runtime_error('invalid constructor length expression',e%line,e%column);return
                            end if
                            if(value%i>65536) then
                                call runtime_error('constructor length limit exceeded',e%line,e%column);return
                            end if
                            k=int(max(0_int64,value%i))
                        end if
                        if(k/=n) then
                            call runtime_error('constructor length cache differs',e%line,e%column);return
                        end if
                    end if
                else if(shape_state(index)>0.and.expression_cache(index)%character_len>=0) then
                    ! Preparation freezes this descriptor before loop controls
                    ! or item values. Later LEN sees that same activation.
                    n=expression_cache(index)%character_len
                else
                    n=-1
                    do j=1,size(e%args)
                        call consume(e%line,e%column);if(diag%code/=0) return
                        k=character_length(e%args(j),depth+1,.true.)
                        if(diag%code/=0) return
                        if(n>=0.and.k/=n) then
                            call runtime_error('CHARACTER constructor item lengths differ',e%line,e%column);return
                        end if
                        n=k
                    end do
                    if(e%character_len>=0.and.e%character_len/=n) then
                        call runtime_error('constructor length cache differs',e%line,e%column);return
                    end if
                end if
            case(ex_binary)
                if(e%op/='//') then
                    call runtime_error('invalid CHARACTER length operator',e%line,e%column);return
                end if
                n=character_length(e%left,depth+1,.true.)
                if(diag%code/=0) return
                k=character_length(e%right,depth+1,.true.)
                if(diag%code/=0) return
                n=n+k
                if(e%character_len>=0.and.e%character_len/=n) then
                    call runtime_error('CHARACTER concatenation length cache differs',e%line,e%column);return
                end if
            case(ex_user_call)
                s=prog%procedures(e%symbol)%result_symbol
                if(e%character_len/=prog%symbols(s)%character_len) then
                    call runtime_error('function result length cache differs',e%line,e%column);return
                end if
                if(e%character_len>=0) then
                    n=e%character_len
                else if(e%rank>0) then
                    call prepare_expression(index,depth+1)
                    if(diag%code/=0) return
                    n=expression_cache(index)%character_len
                else
                    value=evaluate(index,depth+1)
                    if(diag%code/=0) return
                    if(allocated(value%s)) n=len(value%s)
                end if
            case(ex_call)
                if(e%op=='min'.or.e%op=='max') then
                    call validate_minmax(index,.false.)
                    if(diag%code/=0)return
                    n=0
                    do j=1,size(e%args)
                        k=character_length(e%args(j),depth+1,.true.)
                        if(diag%code/=0)return
                        n=max(n,k)
                    end do
                    if(e%character_len>=0.and.e%character_len/=n) &
                        call runtime_error('MIN/MAX result length cache differs',e%line,e%column)
                else if(e%op=='repeat') then
                    call validate_repeat_metadata(index)
                    if(diag%code/=0) return
                    k=character_length(e%args(1),depth+1,.true.)
                    if(diag%code/=0) return
                    value=evaluate(e%args(2),depth+1)
                    if(diag%code/=0) return
                    n=repeat_result_length(k,value%i,e%line,e%column)
                    if(diag%code/=0) return
                    if(e%character_len>=0.and.e%character_len/=n) &
                        call runtime_error('REPEAT length cache differs',e%line,e%column)
                else if(e%character_len>=0) then
                    n=e%character_len
                else if(e%op=='eoshift') then
                    call validate_eoshift(index)
                    if(diag%code/=0)return
                    n=character_length(e%args(1),depth+1,.true.)
                else if(e%op=='merge'.or.e%op=='pack'.or.e%op=='cshift'.or.e%op=='adjustl'.or.e%op=='adjustr') then
                    n=character_length(e%args(1),depth+1,.true.)
                else if(e%rank==0) then
                    value=evaluate(index,depth+1)
                    if(diag%code/=0) return
                    if(allocated(value%s)) n=len(value%s)
                end if
            end select
            if(n<0.or.n>65536) call runtime_error('invalid CHARACTER length descriptor',e%line,e%column)
            end associate
        end function
        subroutine dummy_bound(root,bound,default_lower,is_dynamic,cached)
            integer,intent(in)::root
            integer(int64),intent(out)::bound
            integer(int64),intent(in)::cached
            logical,intent(in)::default_lower,is_dynamic
            type(value_t)::value
            type(diagnostic_t)::constant_diag
            if(diag%code/=0) return
            if(root==0.and.default_lower) then
                bound=1_int64
                if(cached/=1_int64) call runtime_error('explicit-shape default lower bound cache differs',0,0)
                return
            end if
            if(.not.valid_expression(root)) return
            call evaluate_constant(prog,root,value,constant_diag)
            if(constant_diag%code==0) then
                if(value%tag/=ty_integer.or.prog%expressions(root)%rank/=0.or.value%i/=cached) then
                    call runtime_error('explicit-shape dummy bound cache differs',0,0);return
                end if
            else if(.not.is_dynamic.or..not.valid_dummy_bound(prog,root,scope)) then
                call runtime_error('unsupported explicit-shape dummy bound expression',0,0);return
            end if
            call automatic_bound(root,bound,default_lower)
        end subroutine
        subroutine automatic_bound(root,bound,default_lower)
            integer,intent(in)::root
            integer(int64),intent(out)::bound
            logical,intent(in)::default_lower
            type(value_t)::value
            type(diagnostic_t)::constant_diag
            if(diag%code/=0) return
            if(root==0.and.default_lower) then
                bound=1_int64;return
            end if
            if(.not.valid_expression(root)) return
            if(prog%expressions(root)%rank/=0.or.prog%expressions(root)%typ/=ty_integer) then
                call runtime_error('automatic bound must be scalar INTEGER',0,0);return
            end if
            if(.not.valid_automatic_bound(prog,root,scope)) then
                ! Existing constant expressions are also permitted in mixed
                ! constant/automatic declarations, with ordinary safety checks.
                call evaluate_constant(prog,root,value,constant_diag)
                if(constant_diag%code/=0.or.value%tag/=ty_integer) then
                    call runtime_error('unsupported automatic bound expression',0,0);return
                end if
            end if
            value=evaluate(root,0)
            if(diag%code/=0) return
            if(value%tag/=ty_integer) then
                call runtime_error('automatic bound is not INTEGER',0,0);return
            end if
            if(.not.check_integer(value%i,prog%expressions(root)%line,prog%expressions(root)%column)) return
            bound=value%i
        end subroutine
        recursive subroutine inquiry_value(index,depth,value)
            integer,intent(in)::index,depth
            type(value_t),intent(out)::value
            type(value_t)::dim
            integer::arg,sym,n,d
            integer(int64)::lo,extent
            associate(e=>prog%expressions(index))
            n=size(e%args)
            if(n<1.or.n>2.or.(e%op/='size'.and.n/=2)) then
                call runtime_error('invalid array inquiry arguments',e%line,e%column); return
            end if
            arg=e%args(1)
            if(.not.valid_expression(arg)) return
            if(prog%expressions(arg)%rank<1.or.e%rank/=0.or.e%typ/=ty_integer) then
                call runtime_error('array inquiry requires array and scalar INTEGER result',e%line,e%column); return
            end if
            d=1
            if(n==2) then
                dim=evaluate(e%args(2),depth+1)
                if(diag%code/=0) return
                if(dim%tag/=ty_integer.or.dim%i<1.or.dim%i>prog%expressions(arg)%rank) then
                    if(prog%expressions(arg)%rank==1) then
                        call runtime_error('array inquiry DIM must equal 1',e%line,e%column)
                    else
                        call runtime_error('array inquiry DIM outside array rank',e%line,e%column)
                    end if
                    return
                end if
            end if
            if(n==2) d=int(dim%i)
            call prepare_expression(arg,depth+1)
            if(diag%code/=0) return
            extent=shape_dims(d,arg); lo=1_int64
            if(n==1) extent=shape_extent(arg)
            if(prog%expressions(arg)%kind==ex_variable.and..not.prog%expressions(arg)%parenthesized.and.extent>0) then
                sym=prog%expressions(arg)%symbol
                if(.not.valid_symbol(sym)) return
                lo=refs(sym)%array%lower_bound
                if(d==2) lo=refs(sym)%array%lower_bound2
                if(d==3) lo=refs(sym)%array%lower_bound3
            end if
            value%tag=ty_integer
            select case(e%op)
            case('size'); value%i=extent
            case('lbound'); value%i=lo
            case('ubound'); value%i=lo+extent-1_int64
            end select
            if(.not.check_integer(value%i,e%line,e%column)) return
            end associate
        end subroutine
        subroutine runtime_error(message,lin,col)
            character(*), intent(in) :: message
            integer, intent(in) :: lin,col
            call fail(diag,message,lin,col,2)
        end subroutine
        subroutine consume(lin,col)
            integer, intent(in) :: lin,col
            if (budget<=0_int64) then
                call runtime_error('execution step limit exceeded',lin,col)
            else
                budget=budget-1_int64
            end if
        end subroutine
        logical function valid_optional_declaration(symbol) result(ok)
            integer,intent(in)::symbol
            type(value_t)::length_value
            type(diagnostic_t)::length_diag
            ok=.true.
            if(.not.prog%symbols(symbol)%is_optional) return
            associate(v=>prog%symbols(symbol))
            ok=v%is_dummy.and.v%scope>0.and.v%dummy_intent>=1.and.v%dummy_intent<=3.and. &
               .not.v%is_parameter.and..not.v%is_automatic.and.v%initializer_expr==0
            if(v%typ==ty_character) then
                ok=ok.and.v%rank>=0.and.v%rank<=3.and.v%character_len>=-1.and. &
                   v%character_len<=65536.and.v%real_kind==4
                if(v%character_len<0) ok=ok.and.v%length_expr==0
                if(v%length_expr/=0.and.ok) then
                    call evaluate_constant(prog,v%length_expr,length_value,length_diag)
                    ok=length_diag%code==0.and.length_value%tag==ty_integer
                    if(ok) ok=max(0_int64,length_value%i)==int(v%character_len,int64)
                end if
                if(v%rank==0) then
                    ok=ok.and..not.v%assumed_shape.and.(.not.v%deferred_character.or.v%is_allocatable)
                else
                    ok=ok.and.(v%assumed_shape.neqv.(v%is_allocatable.or.v%is_pointer))
                end if
                if(v%deferred_character) ok=ok.and.v%is_allocatable.and.v%character_len==-1
            else
                ok=ok.and.v%rank>=0.and.v%rank<=3.and.v%typ>=ty_integer.and.v%typ<=ty_logical.and. &
                   .not.v%deferred_character.and.v%length_expr==0.and.v%character_len==-1
                if(v%typ==ty_logical) then
                    ok=ok.and.v%real_kind==4
                else
                    ok=ok.and.(v%real_kind==4.or.v%real_kind==8)
                end if
                if(v%rank==0) then
                    ok=ok.and..not.v%assumed_shape.and..not.v%is_allocatable
                else
                    ok=ok.and.(v%assumed_shape.neqv.(v%is_allocatable.or.v%is_pointer))
                end if
            end if
            if(.not.ok) call runtime_error('invalid OPTIONAL dummy declaration',v%line,v%column)
            end associate
        end function
        logical function absent_actual(index,dummy) result(absent)
            integer,intent(in)::index,dummy
            integer::s,proc
            logical::unallocated_optional
            absent=index==0
            if(index<1.or.index>prog%ne) return
            if(prog%expressions(index)%kind/=ex_variable.or.prog%expressions(index)%parenthesized) return
            s=prog%expressions(index)%symbol
            if(s<1.or.s>prog%ns.or.dummy<1.or.dummy>prog%ns) return
            if(prog%symbols(s)%scope==scope.and.prog%symbols(s)%is_dummy.and. &
               prog%symbols(s)%is_optional) absent=.not.dummy_present(s)
            ! Whole unallocated actuals are absent for nonallocatable OPTIONAL
            ! dummies only. Sections, elements and expressions are evaluated.
            unallocated_optional=prog%symbols(dummy)%is_optional.and. &
                .not.prog%symbols(dummy)%is_allocatable.and.prog%symbols(s)%is_allocatable
            if(.not.absent.and..not.unallocated_optional) return
            if(prog%symbols(dummy)%is_allocatable.and..not.prog%symbols(s)%is_allocatable) then
                call runtime_error('absent ALLOCATABLE dummy requires allocatable actual',0,0);return
            end if
            if(prog%symbols(dummy)%is_allocatable.and. &
               (prog%symbols(dummy)%deferred_character.neqv.prog%symbols(s)%deferred_character)) then
                call runtime_error('absent ALLOCATABLE CHARACTER deferred length differs',0,0);return
            end if
            ! Absence still requires a structurally valid expression descriptor.
            if(.not.valid_expression(index)) return
            if(.not.valid_symbol(s,allow_absent=.true.)) return
            if(prog%expressions(index)%typ/=prog%symbols(s)%typ.or. &
               prog%expressions(index)%rank/=prog%symbols(s)%rank.or. &
               prog%expressions(index)%typ/=prog%symbols(dummy)%typ) then
                call runtime_error('invalid absent actual type or rank descriptor',0,0);return
            end if
            proc=prog%symbols(dummy)%scope
            if(proc<1.or.proc>prog%np) then
                call runtime_error('invalid absent actual dummy scope',0,0);return
            end if
            if(.not.prog%procedures(proc)%is_elemental.and. &
               prog%expressions(index)%rank/=prog%symbols(dummy)%rank) then
                call runtime_error('absent actual rank differs from dummy',0,0);return
            end if
            if(prog%expressions(index)%typ==ty_character) then
                if(prog%expressions(index)%character_len/=prog%symbols(s)%character_len) then
                    call runtime_error('absent CHARACTER actual length metadata differs',0,0);return
                end if
            else if(prog%expressions(index)%typ>=ty_integer.and.prog%expressions(index)%typ<=ty_logical) then
                if(prog%expressions(index)%real_kind/=prog%symbols(s)%real_kind.or. &
                   prog%expressions(index)%real_kind/=prog%symbols(dummy)%real_kind) then
                    call runtime_error('absent actual kind differs from dummy',0,0);return
                end if
            end if
            if(prog%symbols(s)%rank>0.and.(prog%symbols(s)%assumed_shape.or.prog%symbols(s)%is_allocatable.or.prog%symbols(s)%is_pointer)) then
                if(prog%expressions(index)%extent/=-1_int64.or. &
                   (prog%symbols(s)%rank>=2.and.any(prog%expressions(index)%dims/=-1_int64))) then
                    call runtime_error('invalid absent actual dynamic shape descriptor',0,0);return
                end if
            end if
            if(unallocated_optional) absent=absent.or..not.allocated(refs(s)%array%values)
        end function
        subroutine present_value(index,value)
            integer,intent(in)::index
            type(value_t),intent(out)::value
            integer::a,s
            associate(e=>prog%expressions(index))
            if(e%rank/=0.or.e%extent/=0.or.e%typ/=ty_logical.or.e%real_kind/=4) then
                call runtime_error('invalid PRESENT result metadata',e%line,e%column);return
            end if
            if(.not.allocated(e%args)) then
                call runtime_error('PRESENT argument missing',e%line,e%column);return
            end if
            if(size(e%args)/=1) then
                call runtime_error('PRESENT requires one optional dummy',e%line,e%column);return
            end if
            a=e%args(1)
            if(.not.valid_expression(a)) return
            if(prog%expressions(a)%kind/=ex_variable.or.prog%expressions(a)%parenthesized) then
                call runtime_error('PRESENT requires an optional dummy name',e%line,e%column);return
            end if
            s=prog%expressions(a)%symbol
            if(s<1.or.s>prog%ns) then
                call runtime_error('invalid PRESENT dummy reference',e%line,e%column);return
            end if
            if(present(constant_index).or.prog%symbols(s)%scope/=scope.or..not.prog%symbols(s)%is_dummy.or. &
               .not.prog%symbols(s)%is_optional) then
                call runtime_error('PRESENT requires a local optional dummy',e%line,e%column);return
            end if
            if(prog%expressions(a)%typ/=prog%symbols(s)%typ.or. &
               prog%expressions(a)%rank/=prog%symbols(s)%rank.or. &
               prog%expressions(a)%real_kind/=prog%symbols(s)%real_kind) then
                call runtime_error('PRESENT argument descriptor differs from dummy',e%line,e%column);return
            end if
            if(prog%symbols(s)%rank>0) then
                if(prog%expressions(a)%extent/=-1_int64.or. &
                   (prog%symbols(s)%rank>=2.and.any(prog%expressions(a)%dims/=-1_int64))) then
                    call runtime_error('PRESENT array argument shape differs from dummy',e%line,e%column);return
                end if
            end if
            value=value_t(tag=ty_logical,l=dummy_present(s))
            end associate
        end subroutine
        logical function valid_symbol(index,allow_absent)
            integer, intent(in) :: index
            logical,intent(in),optional::allow_absent
            valid_symbol=index>=1 .and. index<=prog%ns
            if (.not.valid_symbol) then
                call runtime_error('invalid symbol reference',0,0); return
            end if
            if(prog%symbols(index)%is_pointer.and.scope>0) then
                if(.not.present(allow_absent)) then
                    valid_symbol=.false.;call runtime_error('Pointer pointee access in procedures is unsupported', &
                        prog%symbols(index)%line,prog%symbols(index)%column);return
                else if(.not.allow_absent) then
                    valid_symbol=.false.;call runtime_error('Pointer pointee access in procedures is unsupported', &
                        prog%symbols(index)%line,prog%symbols(index)%column);return
                end if
            end if
            if(.not.present(constant_index)) then
                if(prog%symbols(index)%scope<0.and..not.prog%symbols(index)%is_parameter) then
                    if(.not.module_symbol_visible(prog,index,scope)) then
                        valid_symbol=.false.;call runtime_error('module variable is not visible in this scope',0,0);return
                    end if
                    if(scope>0) then
                        if(prog%procedures(scope)%is_simple) then
                            valid_symbol=.false.;call runtime_error('SIMPLE cannot reference mutable module data',0,0);return
                        end if
                    end if
                end if
                if(prog%symbols(index)%scope/=scope.and.prog%symbols(index)%scope>=0.and. &
                   .not.prog%symbols(index)%is_parameter) then
                    if(.not.host_symbol_visible(prog,index,scope).or..not.captured(index)) then
                        valid_symbol=.false.; call runtime_error('symbol is outside the active call frame or supported host',0,0);return
                    end if
                end if
                if(.not.dummy_present(index)) then
                    if(present(allow_absent)) then
                        if(allow_absent) return
                    end if
                    valid_symbol=.false.
                    call runtime_error('absent OPTIONAL dummy referenced: '//trim(prog%symbols(index)%name), &
                        prog%symbols(index)%line,prog%symbols(index)%column)
                end if
            end if
        end function
        function storage_dims(symbol) result(dims)
            integer,intent(in)::symbol
            integer(int64)::dims(3)
            dims=[max(0_int64,refs(symbol)%array%upper_bound-refs(symbol)%array%lower_bound+1_int64),1_int64,1_int64]
            if(prog%symbols(symbol)%rank>=2) &
                dims(2)=max(0_int64,refs(symbol)%array%upper_bound2-refs(symbol)%array%lower_bound2+1_int64)
            if(prog%symbols(symbol)%rank==3) &
                dims(3)=max(0_int64,refs(symbol)%array%upper_bound3-refs(symbol)%array%lower_bound3+1_int64)
        end function
        ! Map logical column-major section positions to frozen source storage.
        ! A scalar dimension has count one; compressed result ranks need no
        ! special case and both orientations of rank-reducing slices work.
        integer function section_offset(index,position) result(offset)
            integer,intent(in)::index,position
            integer::sym,d
            integer(int64)::q,i,mult,lb(3),sd(3)
            sym=prog%expressions(index)%symbol
            q=int(position-1,int64);offset=1;mult=1_int64
            lb=[refs(sym)%array%lower_bound,refs(sym)%array%lower_bound2,refs(sym)%array%lower_bound3]
            sd=storage_dims(sym)
            do d=1,prog%symbols(sym)%rank
                i=section_start(d,index)+modulo(q,section_count(d,index))*section_step(d,index)
                q=q/section_count(d,index)
                offset=offset+int((i-lb(d))*mult)
                mult=mult*sd(d)
            end do
        end function
        logical function check_integer(n,lin,col,rkind)
            integer(int64), intent(in) :: n
            integer, intent(in) :: lin,col
            integer,optional,intent(in)::rkind
            check_integer=n>=imin .and. n<=imax
            if(present(rkind)) then
                if(rkind==8) check_integer=.true.
                if(rkind/=4.and.rkind/=8) check_integer=.false.
            end if
            if (.not.check_integer) call runtime_error('integer overflow',lin,col)
        end function
        integer function internal_write_element_offset(root,s,lin,col) result(offset)
            integer,intent(in)::root,s,lin,col
            type(value_t)::subscripts(3)
            integer::children(3),r,j,e
            offset=0
            if(.not.valid_internal_write_element(prog,root,s,scope))then
                call runtime_error('invalid internal WRITE array element descriptor',lin,col);return
            end if
            r=prog%symbols(s)%rank
            associate(target=>prog%expressions(root))
            children=[target%left,target%right,target%third]
            end associate
            do j=1,r
                e=children(j)
                subscripts(j)=evaluate(e,1)
                if(diag%code/=0)return
                if(subscripts(j)%tag/=ty_integer.or.subscripts(j)%real_kind/=prog%expressions(e)%real_kind)then
                    call runtime_error('internal WRITE subscript value metadata differs',lin,col);return
                end if
                if(.not.check_integer(subscripts(j)%i,lin,col,subscripts(j)%real_kind))return
            end do
            offset=element_offset(s,subscripts(:r),lin,col)
        end function
        integer function element_expression_offset(symbol,first,second,third,depth,lin,col) result(offset)
            integer,intent(in)::symbol,first,second,third,depth,lin,col
            type(value_t)::subs(3)
            integer::children(3),d,r
            offset=0
            if(.not.valid_symbol(symbol)) return
            r=prog%symbols(symbol)%rank
            children=[first,second,third]
            if(r<1.or.r>3) then
                call runtime_error('subscript requires a rank-one/two/three array',lin,col);return
            end if
            if(any(children(:r)==0).or.any(children(r+1:)/=0)) then
                call runtime_error('array subscript count differs from rank',lin,col);return
            end if
            do d=1,r
                if(.not.valid_expression(children(d))) return
                if(prog%expressions(children(d))%rank/=0.or.prog%expressions(children(d))%typ/=ty_integer) then
                    call runtime_error('array subscript must be INTEGER scalar',lin,col);return
                end if
                subs(d)=evaluate(children(d),depth+1)
                if(diag%code/=0) return
            end do
            offset=element_offset(symbol,subs(:r),lin,col)
        end function
        integer function element_offset(symbol,subscripts,lin,col) result(offset)
            integer,intent(in)::symbol,lin,col
            type(value_t),intent(in)::subscripts(:)
            integer::d,r
            integer(int64)::lb(3),ub(3),mult
            character(32)::index_text,lower_text,upper_text
            offset=0
            if(.not.valid_symbol(symbol)) return
            if(.not.prog%symbols(symbol)%is_parameter) then
                if(.not.array_available(symbol,lin,col)) return
            end if
            r=prog%symbols(symbol)%rank
            if(r<1.or.r>3.or.size(subscripts)/=r) then
                call runtime_error('array subscript count differs from rank',lin,col);return
            end if
            if(.not.allocated(arrays)) then
                call runtime_error('array elements are not constant expressions',lin,col);return
            end if
            lb=[refs(symbol)%array%lower_bound,refs(symbol)%array%lower_bound2,refs(symbol)%array%lower_bound3]
            ub=[refs(symbol)%array%upper_bound,refs(symbol)%array%upper_bound2,refs(symbol)%array%upper_bound3]
            offset=1;mult=1_int64
            do d=1,r
                if(subscripts(d)%tag/=ty_integer) then
                    call runtime_error('array subscript must be INTEGER',lin,col);return
                end if
                if(subscripts(d)%i<lb(d).or.subscripts(d)%i>ub(d)) then
                    write(index_text,'(i0)') subscripts(d)%i
                    write(lower_text,'(i0)') lb(d);write(upper_text,'(i0)') ub(d)
                    call runtime_error('array subscript '//trim(index_text)//' out of bounds for '// &
                        trim(prog%symbols(symbol)%name)//' ('//trim(lower_text)//':'//trim(upper_text)//')',lin,col);return
                end if
                offset=offset+int((subscripts(d)%i-lb(d))*mult)
                mult=mult*max(0_int64,ub(d)-lb(d)+1_int64)
            end do
        end function
        subroutine fit_character(value,symbol,lin,col)
            type(value_t),intent(inout)::value
            integer,intent(in)::symbol,lin,col
            integer::n
            if(value%tag/=ty_character.or..not.allocated(value%s)) then
                call runtime_error('invalid CHARACTER assignment',lin,col);return
            end if
            n=prog%symbols(symbol)%character_len
            if(n<0) then
                if(allocated(refs(symbol)%value%s)) n=len(refs(symbol)%value%s)
            end if
            if(n<0.or.n>65536) then
                call runtime_error('invalid CHARACTER length',lin,col);return
            end if
            value%s=value%s(:min(n,len(value%s)))//repeat(' ',max(0,n-len(value%s)))
        end subroutine
        function parameter_element(symbol,position,lin,col) result(value)
            integer,intent(in)::symbol,position,lin,col
            type(value_t)::value
            if(.not.prog%symbols(symbol)%parameter_ready.or..not.allocated(prog%symbols(symbol)%constant_values)) then
                call runtime_error('array PARAMETER value is not defined',lin,col);return
            end if
            if(position<1.or.position>size(prog%symbols(symbol)%constant_values)) then
                call runtime_error('array PARAMETER position out of bounds',lin,col);return
            end if
            if(size(prog%symbols(symbol)%constant_values,kind=int64)/=shape_size(storage_dims(symbol))) then
                call runtime_error('array PARAMETER cache shape differs',lin,col);return
            end if
            value=prog%symbols(symbol)%constant_values(position)
            if(value%tag/=prog%symbols(symbol)%typ) then
                call runtime_error('array PARAMETER cache type differs',lin,col);return
            end if
            if(value%tag==ty_integer) then
                if(value%real_kind/=prog%symbols(symbol)%real_kind) then
                    call runtime_error("INTEGER parameter array kind mismatch",lin,col);return
                end if
                if(.not.check_integer(value%i,lin,col,value%real_kind)) return
            else if(value%tag==ty_real) then
                if(value%real_kind/=prog%symbols(symbol)%real_kind.or..not.ieee_is_finite(value%r)) &
                    call runtime_error('array PARAMETER cache kind/value differs',lin,col)
            end if
        end function
        function convert(v,typ,lin,col,real_kind) result(out)
            type(value_t), intent(in) :: v
            integer, intent(in) :: typ,lin,col
            integer, intent(in), optional :: real_kind
            type(value_t) :: out
            real(real64) :: wide
            integer :: rk
            out=v
            rk=4
            if(present(real_kind)) rk=real_kind
            if(typ==ty_real) then
                if(rk/=4.and.rk/=8) then
                    call runtime_error('unsupported REAL kind',lin,col); return
                end if
                out%tag=ty_real; out%real_kind=rk
                if(v%tag==ty_integer) then
                    out%r=real(v%i,real64)
                else if(v%tag/=ty_real) then
                    call runtime_error('unsupported value conversion',lin,col); return
                end if
                if(rk==4) out%r=real(real(out%r,real32),real64)
                if(.not.ieee_is_finite(out%r)) call runtime_error('non-finite real conversion',lin,col)
                return
            end if
            if(typ==ty_integer) then
                out%tag=ty_integer; out%real_kind=rk
                if(rk/=4.and.rk/=8) then
                    call runtime_error('unsupported INTEGER kind',lin,col); return
                end if
                if(v%tag==ty_integer) then
                    if(.not.check_integer(v%i,lin,col,rk)) return
                    return
                end if
            end if
            if(v%tag==typ) return
            out%tag=typ
            if(typ==ty_integer.and.v%tag==ty_real) then
                wide=v%r
                if(.not.ieee_is_finite(wide)) then
                    call runtime_error('non-finite real-to-integer conversion',lin,col); return
                end if
                if((rk==4.and.(wide<real(imin,real64).or.wide>=2147483648.0_real64)).or. &
                   (rk==8.and.(wide<real(min64,real64).or.wide>=9223372036854775808.0_real64))) then
                    call runtime_error('integer overflow in real conversion',lin,col); return
                end if
                out%i=int(v%r,int64)
            else
                call runtime_error('unsupported value conversion',lin,col)
            end if
        end function
        logical function valid_expression(index)
            integer, intent(in) :: index
            valid_expression=.false.
            if (index<1.or.index>prog%ne) then
                call runtime_error('invalid expression reference',0,0)
                return
            end if
            associate(e=>prog%expressions(index))
            if(e%kind==ex_output_do) then
                call runtime_error('output implied-DO cannot be used as a value',e%line,e%column);return
            end if
            if(e%kind/=ex_constructor_index.and.e%constructor_owner/=0) then
                call runtime_error('unexpected constructor index ownership',e%line,e%column);return
            end if
            if(e%kind==ex_constructor_index) then
                if(.not.valid_constructor_index(prog,index)) then
                    call runtime_error('invalid constructor index metadata',e%line,e%column);return
                end if
            end if
            if(e%kind/=ex_constructor.and.e%constructor_kind_expr/=0) then
                call runtime_error('unexpected constructor KIND selector',e%line,e%column);return
            end if
            if(.not.present(constant_index)) then
                if(e%scope/=scope) then
                    call runtime_error('expression is outside the active call frame',e%line,e%column); return
                end if
            end if
            if((e%kind/=ex_element.and.e%kind/=ex_substring.and.e%third/=0).or. &
               (e%kind/=ex_section.and.e%kind/=ex_gather_rows.and. &
                (e%left3/=0.or.e%right3/=0.or.e%stride3/=0.or.e%triplet(3)))) then
                call runtime_error('unexpected third subscript metadata',e%line,e%column);return
            end if
            if(e%kind==ex_variable.and.e%symbol>=1.and.e%symbol<=prog%ns) then
                if(prog%symbols(e%symbol)%is_allocatable.and.prog%symbols(e%symbol)%rank==0) then
                    if(.not.valid_symbol(e%symbol,allow_absent=.true.)) return
                    if(e%typ/=ty_character.or.e%real_kind/=4.or.e%rank/=0.or.e%extent/=0.or. &
                       any(e%dims/=0).or.e%character_len/=prog%symbols(e%symbol)%character_len.or. &
                       e%left/=0.or.e%right/=0.or.e%stride/=0.or.e%left2/=0.or.e%right2/=0.or. &
                       e%stride2/=0.or.e%left3/=0.or.e%right3/=0.or.e%stride3/=0.or.e%third/=0.or. &
                       e%length_expr/=0.or.e%generic_id/=0.or.e%bound_type/=0.or.e%bound_binding/=0.or. &
                       e%intrinsic_mask/=0.or.len_trim(e%op)/=0.or.allocated(e%args).or. &
                       any(e%triplet.neqv.[.true.,.false.,.false.])) then
                        call runtime_error('invalid scalar ALLOCATABLE CHARACTER expression descriptor',e%line,e%column);return
                    end if
                end if
            end if
            if (e%rank<0.or.e%rank>3.or.e%extent< -1_int64.or.e%extent>max_array_elements) then
                call runtime_error('invalid expression shape',e%line,e%column)
                return
            end if
            if(e%rank>0.and.(e%kind==ex_literal.or.e%kind==ex_element)) then
                call runtime_error('invalid expression shape',e%line,e%column); return
            end if
            if (e%extent<0.and.(e%rank==0.or.e%kind==ex_literal.or.e%kind==ex_element)) then
                call runtime_error('invalid expression shape',e%line,e%column)
                return
            end if
            if(e%kind==ex_variable.and.e%extent<0) then
                ! Shape metadata validation must not dereference OPTIONAL data;
                ! PRESENT/KIND and direct absence forwarding use this path too.
                if(.not.valid_symbol(e%symbol,allow_absent=.true.)) return
                if(.not.prog%symbols(e%symbol)%assumed_shape.and..not.prog%symbols(e%symbol)%is_automatic.and..not.prog%symbols(e%symbol)%is_allocatable.and..not.prog%symbols(e%symbol)%is_pointer) then
                    call runtime_error('invalid expression shape',e%line,e%column); return
                end if
            end if
            if(e%rank>=2) then
                if(any(e%dims< -1_int64).or.any(e%dims>imax)) then
                    call runtime_error('invalid array dimension extents',e%line,e%column); return
                end if
                if(e%extent>=0) then
                    if(any(e%dims<0)) then
                        call runtime_error('invalid array shape cache',e%line,e%column); return
                    end if
                    if(shape_size(e%dims)/=e%extent) then
                        call runtime_error('array extent differs from dimensions',e%line,e%column); return
                    end if
                end if
            end if
            if (e%rank==0.and.e%extent/=0) then
                call runtime_error('invalid scalar expression extent',e%line,e%column)
                return
            end if
            end associate
            valid_expression=.true.
        end function
        subroutine validate_row_gather(index,inquiry,axis,vector)
            integer,intent(in)::index
            logical,intent(in)::inquiry
            integer,intent(out),optional::axis,vector
            integer::sym,child,rank,d,selectors(3)
            if(present(axis))axis=0
            if(present(vector))vector=0
            associate(e=>prog%expressions(index))
            sym=e%symbol
            if(.not.valid_symbol(sym,allow_absent=inquiry)) return
            rank=prog%symbols(sym)%rank
            if(rank<1.or.rank>3) then
                call runtime_error('invalid row gather metadata',e%line,e%column);return
            end if
            if(count(e%triplet(:rank))/=rank-1.or. &
               (rank==2.and.any(e%triplet.neqv.[.false.,.true.,.false.])).or. &
               (rank==1.and.any(e%triplet))) then
                call runtime_error('invalid row gather axis metadata',e%line,e%column);return
            end if
            do d=1,rank
                if(.not.e%triplet(d))exit
            end do
            selectors=[e%left,e%left2,e%left3]
            if(selectors(d)<=0.or.count(selectors/=0)/=1) then
                call runtime_error('invalid row gather selector metadata',e%line,e%column);return
            end if
            if(prog%symbols(sym)%is_pointer.or. &
               (rank==1.and.e%typ/=ty_character.and.e%typ/=ty_integer.and.e%typ/=ty_real).or. &
               (rank/=1.and.e%typ/=ty_integer.and.e%typ/=ty_real).or.e%typ/=prog%symbols(sym)%typ.or. &
               e%real_kind/=prog%symbols(sym)%real_kind.or.(e%real_kind/=4.and.e%real_kind/=8).or. &
               e%rank/=rank.or.e%extent/=-1_int64.or.any(e%dims/=-1_int64).or. &
               e%right/=0.or.e%stride/=0.or.e%right2/=0.or.e%stride2/=0.or. &
               e%right3/=0.or.e%stride3/=0.or.e%third/=0.or. &
               e%length_expr/=0.or.e%generic_id/=0.or.e%bound_type/=0.or.e%bound_binding/=0.or. &
               e%intrinsic_mask/=0.or. &
               (e%typ/=ty_character.and.e%character_len/=-1).or. &
               (e%typ==ty_character.and.(e%real_kind/=4.or.e%character_len< -1.or.e%character_len>65536.or. &
                e%character_len/=prog%symbols(sym)%character_len)).or. &
               len_trim(e%op)/=0.or.allocated(e%args)) then
                call runtime_error('invalid row gather metadata',e%line,e%column);return
            end if
            child=selectors(d)
            if(.not.valid_expression(child)) return
            if(prog%expressions(child)%typ/=ty_integer.or.prog%expressions(child)%rank/=1.or. &
               (prog%expressions(child)%real_kind/=4.and.prog%expressions(child)%real_kind/=8)) then
                call runtime_error('row gather index must be an INTEGER vector',e%line,e%column);return
            end if
            if(present(axis))axis=d
            if(present(vector))vector=child
            end associate
        end subroutine
        recursive subroutine prepare_row_gather(index,depth)
            integer,intent(in)::index,depth
            integer::sym,child,j,d,axis,status,offset,at,charlen
            integer(int64)::nr,total,base_dims(3),result_dims(3),lb,ub,q,coordinate,mult,offset64
            integer(int64),allocatable::rows(:)
            type(value_t)::value
            associate(e=>prog%expressions(index))
            call validate_row_gather(index,.false.,axis,child)
            if(diag%code/=0) return
            if(present(constant_index)) then
                call runtime_error('row gathering is not a supported constant expression',e%line,e%column);return
            end if
            sym=e%symbol
            call prepare_expression(child,depth+1)
            if(diag%code/=0) return
            nr=shape_extent(child)
            if(nr<0.or.nr>max_array_elements-cached_elements) then
                call runtime_error('row gather index temporary element limit exceeded',e%line,e%column);return
            end if
            allocate(rows(int(nr)),stat=status)
            if(status/=0) then
                call runtime_error('unable to allocate row index temporary',e%line,e%column);return
            end if
            ! Each index expression element is evaluated exactly once, even
            ! for a result empty along another dimension. No base values are read in this pass.
            do j=1,int(nr)
                value=evaluate(child,depth+1,j)
                if(diag%code/=0) return
                if(value%tag/=ty_integer.or.value%real_kind/=prog%expressions(child)%real_kind) then
                    call runtime_error('invalid row index value metadata',e%line,e%column);return
                end if
                if(.not.check_integer(value%i,e%line,e%column,value%real_kind)) return
                rows(j)=value%i
            end do
            if(.not.prog%symbols(sym)%is_parameter) then
                if(.not.array_available(sym,e%line,e%column)) return
            end if
            base_dims=storage_dims(sym);result_dims=base_dims;result_dims(axis)=nr
            lb=refs(sym)%array%lower_bound;ub=refs(sym)%array%upper_bound
            if(axis==2) then
                lb=refs(sym)%array%lower_bound2;ub=refs(sym)%array%upper_bound2
            else if(axis==3) then
                lb=refs(sym)%array%lower_bound3;ub=refs(sym)%array%upper_bound3
            end if
            do j=1,int(nr)
                if(rows(j)<lb.or.rows(j)>ub) then
                    call runtime_error('vector row index out of bounds',e%line,e%column);return
                end if
            end do
            total=shape_size(result_dims)
            if(total<0.or.total>max_array_elements) then
                call runtime_error('row gather result element limit exceeded',e%line,e%column);return
            end if
            if(nr>max_array_elements-cached_elements.or. &
               total>max_array_elements-cached_elements-nr) then
                call runtime_error('row gather temporary element limit exceeded',e%line,e%column);return
            end if
            charlen=-1
            if(e%typ==ty_character)then
                charlen=character_length(index,depth+1)
                if(diag%code/=0)return
                if(charlen<0.or.charlen>65536)then
                    call runtime_error('invalid gathered CHARACTER length',e%line,e%column);return
                end if
                if(total*int(charlen,int64)>16777216_int64-cached_gather_character_bytes)then
                    call runtime_error('CHARACTER gather temporary byte limit exceeded (16777216)',e%line,e%column);return
                end if
                expression_cache(index)%gather_character_bytes=total*int(charlen,int64)
                cached_gather_character_bytes=cached_gather_character_bytes+expression_cache(index)%gather_character_bytes
            end if
            allocate(expression_cache(index)%values(int(total)),stat=status)
            if(status/=0) then
                call runtime_error('unable to allocate row gather temporary',e%line,e%column);return
            end if
            cached_elements=cached_elements+total
            do at=1,int(total)
                    call consume(e%line,e%column)
                    if(diag%code/=0) return
                    ! Result and source retain Fortran's first-axis-fast order.
                    ! Only the selected coordinate is replaced by its vector value.
                    q=int(at-1,int64);mult=1_int64;offset64=1_int64
                    do d=1,e%rank
                        coordinate=modulo(q,result_dims(d));q=q/result_dims(d)
                        if(d==axis)coordinate=rows(int(coordinate)+1)-lb
                        offset64=offset64+coordinate*mult;mult=mult*base_dims(d)
                    end do
                    offset=int(offset64)
                    if(e%typ==ty_character)then
                        if(prog%symbols(sym)%is_parameter)then
                            if(.not.allocated(prog%symbols(sym)%constant_values))then
                                call runtime_error('gathered CHARACTER parameter cache missing',e%line,e%column);return
                            end if
                            if(offset<1.or.offset>size(prog%symbols(sym)%constant_values))then
                                call runtime_error('gathered CHARACTER parameter position invalid',e%line,e%column);return
                            end if
                            call check_gather_character(prog%symbols(sym)%constant_values(offset),charlen,e%line,e%column)
                        else
                            if(.not.refs(sym)%array%flags(offset))then
                                call runtime_error('read of uninitialized gathered array element',e%line,e%column);return
                            end if
                            call check_gather_character(refs(sym)%array%data(offset),charlen,e%line,e%column)
                        end if
                        if(diag%code/=0)return
                    end if
                    if(prog%symbols(sym)%is_parameter) then
                        value=parameter_element(sym,offset,e%line,e%column)
                    else
                        if(.not.refs(sym)%array%flags(offset)) then
                            call runtime_error('read of uninitialized gathered array element',e%line,e%column);return
                        end if
                        value=refs(sym)%array%data(offset)
                    end if
                    if(diag%code/=0) return
                    if(value%tag/=e%typ.or.value%real_kind/=e%real_kind) then
                        call runtime_error('invalid gathered array value metadata',e%line,e%column);return
                    end if
                    if(e%typ==ty_integer) then
                        if(.not.check_integer(value%i,e%line,e%column,e%real_kind)) return
                    else if(e%typ==ty_real.and..not.ieee_is_finite(value%r)) then
                        call runtime_error('non-finite gathered array value',e%line,e%column);return
                    end if
                    expression_cache(index)%values(at)=value
            end do
            shape_dims(:,index)=result_dims;shape_extent(index)=total
            end associate
        end subroutine
        subroutine check_gather_character(value,charlen,lin,col)
            type(value_t),intent(in)::value
            integer,intent(in)::charlen,lin,col
            if(value%tag/=ty_character.or.value%real_kind/=4.or.allocated(value%record).or. &
               .not.allocated(value%s))then
                call runtime_error('invalid gathered CHARACTER payload metadata',lin,col);return
            end if
            if(len(value%s)/=charlen)call runtime_error('gathered CHARACTER payload differs from declaration',lin,col)
        end subroutine
        recursive subroutine prepare_array_function(index,depth)
            integer,intent(in)::index,depth
            integer::proc,sym
            integer(int64)::count,dims(3)
            associate(e=>prog%expressions(index))
            proc=e%symbol;sym=prog%procedures(proc)%result_symbol
            if(sym<1.or.sym>prog%ns) then
                call runtime_error('invalid array function result symbol',e%line,e%column);return
            end if
            if(prog%procedures(proc)%is_subroutine.or.prog%procedures(proc)%is_elemental.or. &
               prog%symbols(sym)%scope/=proc.or.prog%symbols(sym)%is_dummy.or.prog%symbols(sym)%is_parameter.or. &
               prog%symbols(sym)%rank/=e%rank.or.e%rank<1.or.e%rank>3.or.e%extent/=-1_int64.or. &
               e%typ<ty_integer.or.e%typ>ty_character.or.e%typ/=prog%symbols(sym)%typ.or. &
               e%real_kind/=prog%symbols(sym)%real_kind) then
                call runtime_error('invalid array function result metadata',e%line,e%column);return
            end if
            if(e%rank>=2.and.any(e%dims/=-1_int64)) then
                call runtime_error('invalid array function result dimensions',e%line,e%column);return
            end if
            if(scope>0) then
                if(prog%procedures(scope)%is_pure.and..not.prog%procedures(proc)%is_pure) then
                    call runtime_error('impure function call inside a PURE procedure',e%line,e%column);return
                end if
            end if
            if(.not.allocated(expression_cache(index)%values)) then
                call invoke_procedure(proc,e%args,e%line,e%column,depth+1,array_result=expression_cache(index))
                if(diag%code/=0) return
                if(.not.allocated(expression_cache(index)%values)) then
                    call runtime_error('array function returned no descriptor',e%line,e%column);return
                end if
                count=size(expression_cache(index)%values,kind=int64)
                if(count>max_array_elements-cached_elements) then
                    call runtime_error('function result temporary element limit exceeded',e%line,e%column);return
                end if
                cached_elements=cached_elements+count
            end if
            dims=[max(0_int64,expression_cache(index)%upper_bound-expression_cache(index)%lower_bound+1_int64),1_int64,1_int64]
            if(e%rank>=2) dims(2)=max(0_int64, &
                expression_cache(index)%upper_bound2-expression_cache(index)%lower_bound2+1_int64)
            if(e%rank==3) dims(3)=max(0_int64, &
                expression_cache(index)%upper_bound3-expression_cache(index)%lower_bound3+1_int64)
            if(shape_size(dims)/=size(expression_cache(index)%values,kind=int64)) then
                call runtime_error('array function result descriptor differs',e%line,e%column);return
            end if
            shape_dims(:,index)=dims;shape_extent(index)=shape_size(dims)
            end associate
        end subroutine
        logical function valid_elemental_call(index) result(ok)
            integer,intent(in)::index
            integer::proc,j,dummy,actual,sym
            ok=.false.
            associate(e=>prog%expressions(index))
            proc=e%symbol
            if(prog%procedures(proc)%is_subroutine) then
                call runtime_error('invalid ELEMENTAL function declaration',e%line,e%column); return
            end if
            if(prog%procedures(proc)%is_pure.eqv.prog%procedures(proc)%has_impure_prefix) then
                call runtime_error('inconsistent ELEMENTAL purity designation',e%line,e%column);return
            end if
            if(prog%procedures(proc)%has_impure_prefix.and. &
               (prog%procedures(proc)%has_pure_prefix.or.prog%procedures(proc)%is_simple)) then
                call runtime_error('conflicting ELEMENTAL purity prefixes',e%line,e%column);return
            end if
            if(.not.allocated(prog%procedures(proc)%args)) then
                call runtime_error('missing ELEMENTAL function dummies',e%line,e%column); return
            end if
            if(size(e%args)/=size(prog%procedures(proc)%args)) then
                call runtime_error('ELEMENTAL argument count mismatch',e%line,e%column); return
            end if
            sym=prog%procedures(proc)%result_symbol
            if(sym<1.or.sym>prog%ns) then
                call runtime_error('invalid ELEMENTAL result symbol',e%line,e%column); return
            end if
            if(prog%symbols(sym)%rank/=0.or.prog%symbols(sym)%scope/=proc.or. &
               prog%symbols(sym)%typ/=e%typ.or.prog%symbols(sym)%is_dummy.or.prog%symbols(sym)%is_parameter) then
                call runtime_error('invalid ELEMENTAL scalar result declaration',e%line,e%column); return
            end if
            if((e%typ==ty_real.or.e%typ==ty_integer).and.e%real_kind/=prog%symbols(sym)%real_kind) then
                call runtime_error('ELEMENTAL result kind mismatch',e%line,e%column); return
            end if
            do j=1,size(e%args)
                dummy=prog%procedures(proc)%args(j);actual=e%args(j)
                if(dummy<1.or.dummy>prog%ns) then
                    call runtime_error('invalid ELEMENTAL dummy symbol',e%line,e%column); return
                end if
                if(actual==0) then
                    if(.not.prog%symbols(dummy)%is_optional) then
                        call runtime_error('missing required ELEMENTAL argument',e%line,e%column);return
                    end if
                    cycle
                end if
                if(.not.valid_expression(actual)) return
                if(.not.prog%symbols(dummy)%is_dummy.or.prog%symbols(dummy)%scope/=proc.or. &
                   prog%symbols(dummy)%rank/=0.or.prog%symbols(dummy)%dummy_intent/=1) then
                    call runtime_error('ELEMENTAL dummy must be scalar INTENT(IN)',e%line,e%column); return
                end if
                if(prog%expressions(actual)%typ/=prog%symbols(dummy)%typ) then
                    call runtime_error('ELEMENTAL argument type mismatch',e%line,e%column); return
                end if
                if((prog%symbols(dummy)%typ>=ty_integer.and.prog%symbols(dummy)%typ<=ty_logical).and. &
                   prog%expressions(actual)%real_kind/=prog%symbols(dummy)%real_kind) then
                    call runtime_error('ELEMENTAL argument kind mismatch',e%line,e%column); return
                end if
            end do
            end associate
            ok=.true.
        end function
        ! Prepare shape descriptors and cache value-dependent array calls.
        ! This validates even empty expressions and freezes section bounds
        ! and PACK selection before assignment.
        recursive subroutine prepare_expression(index,depth)
            integer, intent(in) :: index,depth
            type(value_t) :: inquiry
            integer :: child,j,sym,d,r,operands(3),source_rank
            logical :: missing
            integer(int64) :: lo,hi,step,n,last_index,lower_bound,upper_bound
            if (diag%code/=0) return
            if (.not.valid_expression(index)) return
            if(prog%expressions(index)%kind==ex_constructor_do) then
                call runtime_error('constructor implied-DO requires its constructor context', &
                    prog%expressions(index)%line,prog%expressions(index)%column);return
            end if
            if (depth>512) then
                call runtime_error('expression nesting limit exceeded',0,0)
                return
            end if
            if (shape_state(index)==2) return
            if (shape_state(index)==1) then
                call runtime_error('cyclic expression shape',0,0)
                return
            end if
            ! Static shapes have already been proved by the adapter; do not
            ! traverse unevaluated scalar data inside a zero-sized expression.
            ! Keep variable/cache checks for direct IR callers. Dynamic shape
            ! work is charged even when it produces no data elements.
            associate(e=>prog%expressions(index))
            if (e%extent>=0.and.e%kind/=ex_section.and.e%kind/=ex_gather_rows.and.e%kind/=ex_variable.and. &
                e%kind/=ex_user_call.and.e%kind/=ex_constructor.and. &
                .not.(e%kind==ex_call.and.(is_array_transform(e%op).or.e%op=='associated'.or.e%op=='kind'.or.e%op=='new_line'.or.is_numeric_model_inquiry(e%op).or.e%op=='len'.or. &
                    e%op=='sinh'.or.e%op=='cosh'.or.e%op=='tanh'.or. &
                    e%op=='sin'.or.e%op=='cos'.or.e%op=='tan'.or.e%op=='log10'.or. &
                    e%op=='dprod'.or.e%op=='tand'.or. &
                    is_bit_intrinsic(e%op).or.e%op=='min'.or.e%op=='max'.or.is_lexical_intrinsic(e%op).or.is_degree_trig(e%op).or.e%op=='rrspacing'.or.e%op=='asin'.or.e%op=='atan'.or.e%op=='atan2'.or.e%op=='acos'.or.e%op=='real'.or.e%op=='aint'.or.e%op=='anint'.or.e%op=='asinh'.or.e%op=='acosh'.or. &
                    e%op=='dim'.or.e%op=='sign'.or.e%op=='log_gamma'.or.e%op=='isnan'.or.is_erf_bessel(e%op).or.e%op=='erfc_scaled'.or.e%op=='spacing'.or.e%op=='nearest'.or. &
                    e%op=='fraction'.or.e%op=='exponent'.or.e%op=='set_exponent'.or.e%op=='iachar'.or. &
                    e%op=='nint'.or.e%op=='floor'.or.e%op=='ceiling'.or.e%op=='repeat'.or.e%op=='char'.or.e%op=='achar'.or.is_character_intrinsic(e%op)))) then
                ! Empty enclosing expressions do not evaluate their operands,
                ! but direct IR callers still need intrinsic metadata checked.
                if(e%rank>0.and.e%extent==0) then
                    if(.not.allocated(empty_trig_marks)) allocate(empty_trig_marks(prog%ne),source=0)
                    call validate_empty_trig_tree(index,0)
                    if(diag%code/=0) return
                end if
                shape_extent(index)=e%extent; shape_state(index)=2
                shape_dims(:,index)=[e%extent,1_int64,1_int64]
                if(e%rank>=2) shape_dims(:,index)=e%dims
                return
            end if
            if (e%extent<0) call consume(e%line,e%column)
            end associate
            if (diag%code/=0) return
            shape_state(index)=1
            associate(e=>prog%expressions(index))
            shape_extent(index)=0_int64
            select case(e%kind)
            case(ex_gather_rows)
                call prepare_row_gather(index,depth)
                if(diag%code/=0) return
            case(ex_constructor)
                call validate_empty_constructor(index)
                if(diag%code/=0)return
                if(e%rank/=1.or.(e%typ/=ty_integer.and.e%typ/=ty_real.and.e%typ/=ty_logical.and.e%typ/=ty_character).or. &
                    .not.allocated(e%args)) then
                    call runtime_error('invalid array constructor',e%line,e%column);return
                end if
                if((e%typ==ty_real.or.e%typ==ty_integer).and.e%real_kind/=4.and.e%real_kind/=8) then
                    call runtime_error('unsupported constructor REAL kind',e%line,e%column);return
                end if
                if(e%typ==ty_character) then
                    if(.not.valid_constructor_character_metadata(prog,index)) then
                        call runtime_error('invalid CHARACTER constructor length/type',e%line,e%column);return
                    end if
                    expression_cache(index)%character_len=character_length(index,depth+1)
                    if(diag%code/=0) return
                end if
                if(size(e%args)>max_expressions) then
                    call runtime_error('invalid constructor item count',e%line,e%column);return
                end if
                if(constructor_has_loop(index,0)) then
                    if(e%extent/=-1_int64.or.any(e%dims/=0)) then
                        call runtime_error('invalid implied-DO constructor shape cache',e%line,e%column);return
                    end if
                    call materialize_constructor(index,depth)
                    if(diag%code/=0) return
                    shape_state(index)=2;return
                end if
                n=0_int64
                do j=1,size(e%args)
                    call consume(e%line,e%column)
                    if(diag%code/=0) return
                    child=e%args(j)
                    if(.not.valid_expression(child)) return
                    if(prog%expressions(child)%rank<0.or.prog%expressions(child)%rank>1.or. &
                       prog%expressions(child)%typ/=e%typ.or. &
                       ((e%typ==ty_real.or.e%typ==ty_integer).and.prog%expressions(child)%real_kind/=e%real_kind)) then
                        call runtime_error('constructor item type, kind or rank mismatch',e%line,e%column);return
                    end if
                    call prepare_expression(child,depth+1)
                    if(diag%code/=0) return
                    lo=1_int64
                    if(prog%expressions(child)%rank>0) lo=shape_extent(child)
                    if(lo<0.or.lo>max_array_elements-n) then
                        call runtime_error('constructor element limit exceeded',e%line,e%column);return
                    end if
                    n=n+lo
                end do
                shape_extent(index)=n;shape_dims(:,index)=[n,1_int64,1_int64]
                if(any(e%dims/=0)) then
                    call runtime_error('invalid constructor dimensions',e%line,e%column);return
                end if
            case(ex_variable)
                if (.not.valid_symbol(e%symbol)) return
                if (e%rank>0) then
                    if(present(constant_index).and..not.prog%symbols(e%symbol)%is_parameter) then
                        call runtime_error('array is not a constant expression',e%line,e%column);return
                    end if
                    if(.not.allocated(arrays)) then
                        call runtime_error('arrays are not constant expressions',e%line,e%column); return
                    end if
                    if(e%rank/=prog%symbols(e%symbol)%rank) then
                        call runtime_error('expression rank differs from symbol',e%line,e%column); return
                    end if
                    if(.not.prog%symbols(e%symbol)%is_parameter) then
                        if(.not.array_available(e%symbol,e%line,e%column)) return
                    end if
                    shape_dims(:,index)=storage_dims(e%symbol)
                    shape_extent(index)=shape_size(shape_dims(:,index))
                    if(e%rank>=2.and.e%extent>=0) then
                        if(any(e%dims/=shape_dims(:,index))) then
                            call runtime_error('expression dimensions differ from symbol',e%line,e%column); return
                        end if
                    end if
                    if (e%extent>=0.and.e%extent/=shape_extent(index)) then
                        call runtime_error('array expression shape differs from symbol',e%line,e%column)
                        return
                    end if
                end if
            case(ex_section)
                sym=e%symbol
                if (.not.valid_symbol(sym)) return
                if(.not.prog%symbols(sym)%is_parameter) then
                    if(.not.array_available(sym,e%line,e%column)) return
                end if
                source_rank=prog%symbols(sym)%rank
                if (source_rank<1.or.source_rank>3.or.e%extent/=-1_int64.or. &
                    e%typ/=prog%symbols(sym)%typ) then
                    call runtime_error('invalid section expression shape',e%line,e%column); return
                end if
                if(e%rank/=sum(merge(1,0,e%triplet(:source_rank))).or.e%rank<1) then
                    call runtime_error('invalid section rank',e%line,e%column);return
                end if
                if(source_rank<3.and.(e%triplet(3).or.e%left3/=0.or.e%right3/=0.or.e%stride3/=0)) then
                    call runtime_error('unexpected third section dimension',e%line,e%column);return
                end if
                if(source_rank==1.and.(e%triplet(2).or.e%left2/=0.or.e%right2/=0.or.e%stride2/=0)) then
                    call runtime_error('unexpected second section dimension',e%line,e%column);return
                end if
                shape_dims(:,index)=1_int64; r=0
                do d=1,source_rank
                    operands=[e%left,e%right,e%stride]
                    lower_bound=refs(sym)%array%lower_bound; upper_bound=refs(sym)%array%upper_bound
                    if(d==2) then
                        operands=[e%left2,e%right2,e%stride2]
                        lower_bound=refs(sym)%array%lower_bound2; upper_bound=refs(sym)%array%upper_bound2
                    else if(d==3) then
                        operands=[e%left3,e%right3,e%stride3]
                        lower_bound=refs(sym)%array%lower_bound3; upper_bound=refs(sym)%array%upper_bound3
                    end if
                    lo=lower_bound; hi=upper_bound; step=1_int64; n=1_int64
                    if(e%triplet(d)) then
                        if(operands(3)/=0) call triplet_value(operands(3),step,depth+1)
                        if(diag%code/=0) return
                        if(step==0_int64) then
                            call runtime_error('section stride is zero',e%line,e%column);return
                        end if
                        ! Declared lower/upper defaults apply to BOTH stride signs.
                        if(operands(1)/=0) call triplet_value(operands(1),lo,depth+1)
                        if(operands(2)/=0) call triplet_value(operands(2),hi,depth+1)
                        if(diag%code/=0) return
                        n=0_int64
                        if((step>0_int64.and.lo<=hi).or.(step<0_int64.and.lo>=hi)) n=(hi-lo)/step+1_int64
                        r=r+1; shape_dims(r,index)=n
                    else
                        if(operands(1)==0.or.any(operands(2:)/=0)) then
                            call runtime_error('invalid scalar section subscript',e%line,e%column);return
                        end if
                        call triplet_value(operands(1),lo,depth+1)
                        if(diag%code/=0) return
                    end if
                    if(n>0_int64) then
                        last_index=lo+(n-1_int64)*step
                        if(min(lo,last_index)<lower_bound.or.max(lo,last_index)>upper_bound) then
                            call runtime_error('section subscript out of bounds',e%line,e%column);return
                        end if
                    end if
                    section_start(d,index)=lo; section_step(d,index)=step; section_count(d,index)=n
                end do
                shape_extent(index)=shape_size(shape_dims(:,index))
                if(shape_extent(index)>max_array_elements) then
                    call runtime_error('section element limit exceeded',e%line,e%column);return
                end if
            case(ex_element)
                call prepare_expression(e%left,depth+1)
                if(e%right/=0) call prepare_expression(e%right,depth+1)
                if(e%third/=0) call prepare_expression(e%third,depth+1)
            case(ex_unary,ex_binary)
                call prepare_expression(e%left,depth+1)
                if (diag%code/=0) return
                call merge_runtime_shape(index,e%left)
                if (e%kind==ex_binary) then
                    call prepare_expression(e%right,depth+1)
                    if (diag%code/=0) return
                    call merge_runtime_shape(index,e%right,e%left)
                end if
            case(ex_user_call)
                if(e%symbol<1.or.e%symbol>prog%np.or..not.allocated(e%args)) then
                    call runtime_error('invalid function reference',e%line,e%column); return
                end if
                if(prog%procedures(e%symbol)%is_elemental) then
                    if(.not.valid_elemental_call(index)) return
                    child=0; r=0
                    do j=1,size(e%args)
                        missing=absent_actual(e%args(j),prog%procedures(e%symbol)%args(j))
                        if(diag%code/=0) return
                        if(missing) cycle
                        call prepare_expression(e%args(j),depth+1)
                        if(diag%code/=0) return
                        call merge_runtime_shape(index,e%args(j),child)
                        if(prog%expressions(e%args(j))%rank>0) then
                            child=e%args(j); r=prog%expressions(child)%rank
                        end if
                    end do
                    if(e%rank/=r) then
                        call runtime_error('ELEMENTAL result rank differs from arguments',e%line,e%column); return
                    end if
                    if(e%rank>=2.and.e%extent>=0) then
                        if(any(e%dims/=shape_dims(:,index))) then
                            call runtime_error('ELEMENTAL result dimensions differ from arguments',e%line,e%column); return
                        end if
                    end if
                else if(e%rank>0) then
                    call prepare_array_function(index,depth+1)
                    if(diag%code/=0) return
                else if(e%extent/=0) then
                    call runtime_error('invalid scalar function extent',e%line,e%column);return
                end if
            case(ex_call)
                if (.not.allocated(e%args)) then
                    call runtime_error('missing intrinsic arguments',e%line,e%column)
                    return
                end if
                call validate_utility_intrinsic(index)
                if(diag%code/=0) return
                if(e%op=='selected_real_kind') then
                    if(e%rank/=0.or.e%extent/=0.or.e%typ/=ty_integer.or.e%real_kind/=4.or. &
                       e%intrinsic_mask<0.or.e%intrinsic_mask>7.or.size(e%args)>3) then
                        call runtime_error('invalid SELECTED_REAL_KIND metadata',e%line,e%column);return
                    end if
                    if(popcnt(e%intrinsic_mask)/=size(e%args)) then
                        call runtime_error('invalid SELECTED_REAL_KIND slots',e%line,e%column);return
                    end if
                    do j=1,size(e%args)
                        child=e%args(j)
                        if(child<1.or.child>prog%ne) then
                            call runtime_error('invalid SELECTED_REAL_KIND child',e%line,e%column);return
                        end if
                        if(prog%expressions(child)%rank/=0.or.prog%expressions(child)%typ/=ty_integer) then
                            call runtime_error('SELECTED_REAL_KIND requires scalar INTEGER',e%line,e%column);return
                        end if
                    end do
                end if
                if(e%op=='associated') then
                    call associated_value(index,inquiry)
                    shape_state(index)=2;return
                end if
                if(e%op=='allocated') then
                    call allocated_value(index,inquiry)
                    shape_state(index)=2;return
                end if
                if(e%op=='present') then
                    call present_value(index,inquiry)
                    shape_state(index)=2
                    return
                end if
                if(e%op=='len') then
                    call len_value(index,depth,inquiry)
                    shape_state(index)=2
                    return
                end if
                if(e%op=='new_line') then
                    call new_line_value(index,inquiry)
                    shape_state(index)=2;return
                end if
                if(is_numeric_model_inquiry(e%op)) then
                    call numeric_model_value(index,inquiry)
                    shape_state(index)=2;return
                end if
                if(e%op=='kind') then
                    call kind_value(index,inquiry)
                    shape_state(index)=2
                    return
                end if
                if(is_array_transform(e%op)) then
                    call prepare_array_call(index,depth)
                    if(diag%code/=0) return
                    shape_state(index)=2
                    return
                end if
                child=0
                do j=1,size(e%args)
                    if(is_character_search_intrinsic(e%op).and.j==3.and.btest(e%intrinsic_mask,2)) then
                        if(absent_character_search_back(e%args(j))) then
                            if(prog%expressions(e%args(j))%rank>0.and.child==0) then
                                call runtime_error('absent array Character search BACK requires an array STRING or SUBSTRING/SET', &
                                    e%line,e%column);return
                            end if
                            cycle
                        end if
                        if(diag%code/=0) return
                    end if
                    call prepare_expression(e%args(j),depth+1)
                    if (diag%code/=0) return
                    call merge_runtime_shape(index,e%args(j),child)
                    if (prog%expressions(e%args(j))%rank>0) child=e%args(j)
                end do
            case(ex_literal)
            case default
                call runtime_error('invalid expression opcode',e%line,e%column)
            end select
            if (diag%code/=0) return
            if (e%extent>=0.and.e%extent/=shape_extent(index)) &
                call runtime_error('expression extent differs from evaluated shape',e%line,e%column)
            end associate
            shape_state(index)=2
        end subroutine
        recursive subroutine validate_empty_trig_tree(index,depth)
            integer,intent(in)::index,depth
            integer::j,children(10),n
            type(value_t)::inquiry
            if(diag%code/=0) return
            if(.not.valid_expression(index)) return
            if(depth>512.or.empty_trig_marks(index)==1) then
                call runtime_error('cyclic or excessive empty intrinsic expression',0,0);return
            end if
            if(empty_trig_marks(index)==2) return
            empty_trig_marks(index)=1
            associate(e=>prog%expressions(index))
            call consume(e%line,e%column)
            if(diag%code/=0) return
            children=0;n=0
            select case(e%kind)
            case(ex_unary)
                n=1;children(1)=e%left
            case(ex_binary,ex_element,ex_substring)
                n=3;children(:3)=[e%left,e%right,e%third]
            case(ex_section)
                n=10;children=[e%left,e%right,e%stride,e%left2,e%right2,e%stride2, &
                        e%left3,e%right3,e%stride3,e%third]
            case(ex_gather_rows)
                ! Empty parents skip values, not the gather descriptor or index tree.
                call validate_row_gather(index,.true.,vector=children(1))
                if(diag%code/=0) return
                n=1
            case(ex_call,ex_user_call,ex_constructor)
                if(e%kind==ex_constructor) then
                    call validate_empty_constructor(index)
                    if(diag%code/=0)return
                end if
                if(e%kind==ex_call) then
                    select case(e%op)
                    case('associated')
                        call validate_associated_metadata(index)
                        if(diag%code/=0) return
                    case('new_line')
                        call new_line_value(index,inquiry)
                        if(diag%code/=0)return
                    case('lbound','ubound')
                        call validate_bounds_inquiry(index)
                        if(diag%code/=0)return
                    case('transpose','norm2')
                        call validate_matrix_call(index)
                        if(diag%code/=0)return
                    case('len')
                        call validate_len_metadata(index)
                        if(diag%code/=0)return
                    case('digits','epsilon','radix','tiny','huge','minexponent','maxexponent')
                        call numeric_model_value(index,inquiry)
                        if(diag%code/=0) return
                    case('iand','ior','ieor','not','btest','bit_size','leadz','trailz','maskl','maskr','shiftr','min','max','lge','lgt','lle','llt','acosd','asind','sind','cosd','rrspacing','asin','atan','atan2','acos','real','dprod','tand','aint','anint','asinh','acosh','fraction','exponent','set_exponent','iachar','isnan','erf','bessel_j0','bessel_j1','bessel_jn','bessel_y0','bessel_y1','bessel_yn','erfc_scaled','spacing','nearest','dim','sign','log_gamma','sin','cos','tan','sinh','cosh','tanh','log10','nint','floor','ceiling','shape','repeat','index','scan','verify','len_trim','adjustl','adjustr')
                        call validate_utility_intrinsic(index)
                        if(diag%code/=0) return
                    end select
                end if
                if(allocated(e%args)) then
                    if(size(e%args)>max_expressions) then
                        call runtime_error('excessive empty intrinsic arguments',e%line,e%column);return
                    end if
                    do j=1,size(e%args)
                        if(e%args(j)==0) cycle
                        call validate_empty_trig_tree(e%args(j),depth+1)
                        if(diag%code/=0) return
                    end do
                end if
            end select
            do j=1,n
                if(children(j)==0) cycle
                call validate_empty_trig_tree(children(j),depth+1)
                if(diag%code/=0) return
            end do
            end associate
            empty_trig_marks(index)=2
        end subroutine
        integer function repeat_result_length(n,copies,lin,col) result(length)
            integer,intent(in)::n,lin,col
            integer(int64),intent(in)::copies
            length=0
            if(n<0.or.n>65536) then
                call runtime_error('REPEAT STRING length outside supported range',lin,col);return
            end if
            if(copies<0) then
                call runtime_error('REPEAT NCOPIES must be nonnegative',lin,col);return
            end if
            if(n==0.or.copies==0) return
            if(copies>65536_int64/int(n,int64)) then
                call runtime_error('REPEAT CHARACTER length limit exceeded (65536)',lin,col);return
            end if
            length=n*int(copies)
        end function
        recursive subroutine validate_repeat_metadata(index)
            integer,intent(in)::index
            integer::a,b,n,wanted,sym
            type(value_t)::count
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing REPEAT arguments',e%line,e%column);return
            end if
            if(size(e%args)/=2.or.e%intrinsic_mask/=0) then
                call runtime_error('invalid REPEAT arguments/slots',e%line,e%column);return
            end if
            a=e%args(1);b=e%args(2)
            if(.not.valid_expression(a).or..not.valid_expression(b)) return
            if(a==index.or.b==index) then
                call runtime_error('cyclic REPEAT argument',e%line,e%column);return
            end if
            if(prog%expressions(a)%typ/=ty_character.or.prog%expressions(a)%rank/=0.or.prog%expressions(a)%real_kind/=4.or. &
               prog%expressions(b)%typ/=ty_integer.or.prog%expressions(b)%rank/=0.or. &
               (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8)) then
                call runtime_error('invalid REPEAT operand type/kind/rank',e%line,e%column);return
            end if
            ! Zero copies do not excuse a forged STRING descriptor. Validate
            ! stored literal/declaration lengths without reading STRING data.
            select case(prog%expressions(a)%kind)
            case(ex_literal)
                if(.not.allocated(prog%expressions(a)%value%s)) then
                    call runtime_error('REPEAT literal STRING value is missing',e%line,e%column);return
                end if
                if(prog%expressions(a)%character_len/=len(prog%expressions(a)%value%s)) then
                    call runtime_error('REPEAT literal STRING length differs',e%line,e%column);return
                end if
            case(ex_variable,ex_element,ex_section)
                sym=prog%expressions(a)%symbol
                if(.not.valid_symbol(sym,allow_absent=.true.)) return
                if(prog%expressions(a)%character_len/=prog%symbols(sym)%character_len) then
                    call runtime_error('REPEAT STRING length differs from declaration',e%line,e%column);return
                end if
            end select
            wanted=-1
            if(bound_constant_expression(prog,b,0)) then
                if(.not.safe_location_kind(b,0,.false.)) then
                    call runtime_error('invalid REPEAT constant NCOPIES structure',e%line,e%column);return
                end if
                count=evaluate(b,0)
                if(diag%code/=0) return
                if(count%i<0) then
                    call runtime_error('REPEAT NCOPIES must be nonnegative',e%line,e%column);return
                end if
                n=prog%expressions(a)%character_len
                if(count%i==0) then
                    wanted=0
                else if(n>=0) then
                    wanted=repeat_result_length(n,count%i,e%line,e%column)
                    if(diag%code/=0) return
                end if
            end if
            if(e%typ/=ty_character.or.e%real_kind/=4.or.e%rank/=0.or.e%extent/=0.or.any(e%dims/=0).or. &
               e%character_len/=wanted) then
                call runtime_error('REPEAT result type/kind/shape/length differs',e%line,e%column);return
            end if
            end associate
        end subroutine
        recursive subroutine validate_model_decomposition(index)
            integer,intent(in)::index
            integer::a,b,n,j,t,k,r,last
            integer(int64)::extent,dims(3)
            type(value_t)::kv
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing model decomposition arguments',e%line,e%column);return
            end if
            n=size(e%args)
            if(e%intrinsic_mask/=0.or.(e%op=='set_exponent'.and.n/=2).or. &
               (e%op=='iachar'.and.(n<1.or.n>2)).or. &
               ((e%op=='fraction'.or.e%op=='exponent').and.n/=1)) then
                call runtime_error('invalid model decomposition count/slots',e%line,e%column);return
            end if
            do j=1,n
                if(.not.valid_expression(e%args(j)))return
                if(e%args(j)==index) then
                    call runtime_error('cyclic model decomposition argument',e%line,e%column);return
                end if
                associate(x=>prog%expressions(e%args(j)))
                if(x%kind==ex_literal) then
                    if(x%value%tag/=x%typ.or.x%value%real_kind/=x%real_kind) then
                        call runtime_error('model decomposition literal type/kind differs',e%line,e%column);return
                    end if
                    if(x%typ==ty_character) then
                        if(.not.allocated(x%value%s)) then
                            call runtime_error('IACHAR literal storage is missing',e%line,e%column);return
                        end if
                        if(x%character_len/=len(x%value%s)) then
                            call runtime_error('IACHAR literal length differs',e%line,e%column);return
                        end if
                    end if
                else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section) then
                    if(.not.valid_symbol(x%symbol,allow_absent=.true.)) return
                    if(x%typ/=prog%symbols(x%symbol)%typ.or.x%real_kind/=prog%symbols(x%symbol)%real_kind) then
                        call runtime_error('model decomposition operand declaration differs',e%line,e%column);return
                    end if
                    if(x%typ==ty_character.and.x%character_len/=prog%symbols(x%symbol)%character_len) then
                        call runtime_error('IACHAR operand declaration length differs',e%line,e%column);return
                    end if
                end if
                end associate
            end do
            a=e%args(1);k=prog%expressions(a)%real_kind;t=ty_real;last=1
            if(e%op=='iachar') then
                if(prog%expressions(a)%typ/=ty_character.or.k/=4.or.prog%expressions(a)%character_len< -1) then
                    call runtime_error('IACHAR requires default CHARACTER C',e%line,e%column);return
                end if
                if(prog%expressions(a)%character_len>=0.and.prog%expressions(a)%character_len/=1) then
                    call runtime_error('IACHAR C must have length one',e%line,e%column);return
                end if
                t=ty_integer;k=4
                if(n==2) then
                    b=e%args(2)
                    if(prog%expressions(b)%typ/=ty_integer.or.prog%expressions(b)%rank/=0.or. &
                       prog%expressions(b)%extent/=0.or.any(prog%expressions(b)%dims/=0).or. &
                       (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8)) then
                        call runtime_error('IACHAR KIND must be scalar INTEGER',e%line,e%column);return
                    end if
                    if(.not.safe_location_kind(b,0,.false.)) then
                        call runtime_error('IACHAR KIND must be constant',e%line,e%column);return
                    end if
                    kv=evaluate(b,0)
                    if(diag%code/=0)return
                    if(kv%tag/=ty_integer.or.(kv%i/=4.and.kv%i/=8)) then
                        call runtime_error('IACHAR supports INTEGER kinds 4 and 8',e%line,e%column);return
                    end if
                    k=int(kv%i)
                end if
            else
                if(prog%expressions(a)%typ/=ty_real.or.(k/=4.and.k/=8)) then
                    call runtime_error('model decomposition requires REAL4/8 X',e%line,e%column);return
                end if
                if(e%op=='exponent') then
                    t=ty_integer;k=4
                end if
                if(e%op=='set_exponent') then
                    b=e%args(2);last=2
                    if(prog%expressions(b)%typ/=ty_integer.or. &
                       (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8)) then
                        call runtime_error('SET_EXPONENT requires INTEGER4/8 I',e%line,e%column);return
                    end if
                end if
            end if
            r=0;extent=0_int64;dims=0_int64
            do j=1,last
                associate(x=>prog%expressions(e%args(j)))
                if(x%rank<0.or.x%rank>3) then
                    call runtime_error('invalid model decomposition operand rank',e%line,e%column);return
                end if
                if(x%rank==0) then
                    if(x%extent/=0.or.any(x%dims/=0)) then
                        call runtime_error('invalid model decomposition scalar shape',e%line,e%column);return
                    end if
                    cycle
                end if
                if(r>0) then
                    if(r/=x%rank.or.(extent>=0.and.x%extent>=0.and.extent/=x%extent)) then
                        call runtime_error('model decomposition operands do not conform',e%line,e%column);return
                    end if
                    if(r>=2) then
                        if(any(dims>=0.and.x%dims>=0.and.dims/=x%dims)) then
                            call runtime_error('model decomposition dimensions differ',e%line,e%column);return
                        end if
                        where(dims<0.or.x%dims<0)dims=-1_int64
                    end if
                    if(extent<0.or.x%extent<0) then
                        extent=-1_int64;cycle
                    end if
                end if
                r=x%rank;extent=x%extent;dims=x%dims
                end associate
            end do
            if(e%typ/=t.or.e%real_kind/=k.or.e%rank/=r.or.e%extent/=extent.or.any(e%dims/=dims)) &
                call runtime_error('model decomposition result type/kind/shape differs',e%line,e%column)
            end associate
        end subroutine
        recursive subroutine validate_real_conversion(index,walk_tree)
            integer,intent(in)::index
            logical,optional,intent(in)::walk_tree
            integer::n,j,a,b,k
            integer,allocatable::marks(:)
            type(value_t)::kv
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing REAL conversion arguments',e%line,e%column);return
            end if
            n=size(e%args)
            if(n<1.or.n>2.or.e%intrinsic_mask/=0) then
                call runtime_error('invalid REAL conversion count/slots',e%line,e%column);return
            end if
            do j=1,n
                if(.not.valid_expression(e%args(j)))return
                if(e%args(j)==index) then
                    call runtime_error('cyclic REAL conversion argument',e%line,e%column);return
                end if
                associate(x=>prog%expressions(e%args(j)))
                if(x%kind==ex_literal) then
                    if(x%value%tag/=x%typ.or.x%value%real_kind/=x%real_kind) then
                        call runtime_error('REAL conversion literal metadata differs',e%line,e%column);return
                    end if
                else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section) then
                    if(.not.valid_symbol(x%symbol,allow_absent=.true.))return
                    if(x%typ/=prog%symbols(x%symbol)%typ.or.x%real_kind/=prog%symbols(x%symbol)%real_kind) then
                        call runtime_error('REAL conversion declaration differs',e%line,e%column);return
                    end if
                end if
                end associate
            end do
            a=e%args(1);k=prog%expressions(a)%real_kind
            associate(x=>prog%expressions(a))
            if((x%typ/=ty_real.and.x%typ/=ty_integer).or.(k/=4.and.k/=8).or.x%rank<0.or.x%rank>3) then
                call runtime_error('REAL requires INTEGER4/8 or REAL4/8 argument',e%line,e%column);return
            end if
            if(x%rank==0.and.(x%extent/=0.or.any(x%dims/=0))) then
                call runtime_error('invalid REAL conversion scalar shape',e%line,e%column);return
            end if
            if(e%rank/=x%rank.or.e%extent/=x%extent.or.any(e%dims/=x%dims)) then
                call runtime_error('REAL conversion result shape differs',e%line,e%column);return
            end if
            end associate
            k=4
            if(n==2) then
                b=e%args(2)
                associate(x=>prog%expressions(b))
                if(x%typ/=ty_integer.or.(x%real_kind/=4.and.x%real_kind/=8).or. &
                   x%rank/=0.or.x%extent/=0.or.any(x%dims/=0)) then
                    call runtime_error('REAL KIND must be scalar INTEGER',e%line,e%column);return
                end if
                end associate
                if(.not.safe_location_kind(b,0,.false.)) then
                    call runtime_error('REAL KIND must be constant',e%line,e%column);return
                end if
                kv=evaluate(b,0)
                if(diag%code/=0)return
                if(kv%tag/=ty_integer.or.(kv%i/=4.and.kv%i/=8)) then
                    call runtime_error('REAL support result kinds 4 and 8',e%line,e%column);return
                end if
                k=int(kv%i)
            end if
            if(e%typ/=ty_real.or.e%real_kind/=k) &
                call runtime_error('REAL conversion result type/kind differs',e%line,e%column)
            end associate
            if(diag%code/=0)return
            if(present(walk_tree)) then
                if(.not.walk_tree)return
            end if
            ! A selected output kind can hide an inconsistent kind inside a
            ! unary/binary input. Validate the entire unevaluated operand tree
            ! once; its dispatch re-enters only the local guard above.
            allocate(marks(prog%ne),source=0)
            call validate_kind_tree(index,marks,0)
        end subroutine
        recursive subroutine validate_degree_trig(index,walk_tree)
            integer,intent(in)::index
            logical,optional,intent(in)::walk_tree
            integer::a
            integer,allocatable::marks(:)
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing degree trig operand',e%line,e%column);return
            end if
            if(size(e%args)/=1.or.e%intrinsic_mask/=0) then
                call runtime_error('invalid degree trig count/slots',e%line,e%column);return
            end if
            a=e%args(1)
            if(.not.valid_expression(a))return
            if(a==index) then
                call runtime_error('cyclic degree trig operand',e%line,e%column);return
            end if
            associate(x=>prog%expressions(a))
            if(x%typ/=ty_real.or.(x%real_kind/=4.and.x%real_kind/=8).or.x%rank<0.or.x%rank>3) then
                call runtime_error('degree trig requires REAL4/8 operand',e%line,e%column);return
            end if
            if(x%rank==0.and.(x%extent/=0.or.any(x%dims/=0))) then
                call runtime_error('invalid degree trig scalar shape',e%line,e%column);return
            end if
            if(e%typ/=ty_real.or.e%real_kind/=x%real_kind.or.e%rank/=x%rank.or. &
               e%extent/=x%extent.or.any(e%dims/=x%dims)) then
                call runtime_error('degree trig result metadata differs',e%line,e%column);return
            end if
            if(x%kind==ex_literal) then
                if(x%value%tag/=x%typ.or.x%value%real_kind/=x%real_kind) then
                    call runtime_error('degree trig literal cache differs',e%line,e%column);return
                end if
            else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section) then
                if(.not.valid_symbol(x%symbol,allow_absent=.true.))return
                if(x%typ/=prog%symbols(x%symbol)%typ.or.x%real_kind/=prog%symbols(x%symbol)%real_kind) then
                    call runtime_error('degree trig declaration differs',e%line,e%column);return
                end if
            end if
            end associate
            end associate
            if(present(walk_tree)) then
                if(.not.walk_tree)return
            end if
            allocate(marks(prog%ne),source=0)
            call validate_kind_tree(index,marks,0)
        end subroutine
        recursive subroutine validate_acos(index,walk_tree)
            integer,intent(in)::index
            logical,optional,intent(in)::walk_tree
            integer::a
            integer,allocatable::marks(:)
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing ACOS/RRSPACING operand',e%line,e%column);return
            end if
            if(size(e%args)/=1.or.e%intrinsic_mask/=0) then
                call runtime_error('invalid ACOS/RRSPACING count/slots',e%line,e%column);return
            end if
            a=e%args(1)
            if(.not.valid_expression(a))return
            if(a==index) then
                call runtime_error('cyclic ACOS/RRSPACING operand',e%line,e%column);return
            end if
            associate(x=>prog%expressions(a))
            if(x%typ/=ty_real.or.(x%real_kind/=4.and.x%real_kind/=8).or.x%rank<0.or.x%rank>3) then
                call runtime_error('ACOS/RRSPACING requires REAL4/8 operand',e%line,e%column);return
            end if
            if(x%rank==0.and.(x%extent/=0.or.any(x%dims/=0))) then
                call runtime_error('invalid ACOS/RRSPACING scalar shape',e%line,e%column);return
            end if
            if(e%typ/=ty_real.or.e%real_kind/=x%real_kind.or.e%rank/=x%rank.or. &
               e%extent/=x%extent.or.any(e%dims/=x%dims)) then
                call runtime_error('ACOS/RRSPACING result metadata differs',e%line,e%column);return
            end if
            if(x%kind==ex_literal) then
                if(x%value%tag/=x%typ.or.x%value%real_kind/=x%real_kind) then
                    call runtime_error('ACOS/RRSPACING literal cache differs',e%line,e%column);return
                end if
            else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section) then
                if(.not.valid_symbol(x%symbol,allow_absent=.true.))return
                if(x%typ/=prog%symbols(x%symbol)%typ.or.x%real_kind/=prog%symbols(x%symbol)%real_kind) then
                    call runtime_error('ACOS/RRSPACING declaration differs',e%line,e%column);return
                end if
            end if
            end associate
            end associate
            if(present(walk_tree)) then
                if(.not.walk_tree)return
            end if
            allocate(marks(prog%ne),source=0)
            call validate_kind_tree(index,marks,0)
        end subroutine
        recursive subroutine validate_real_round_inverse(index,walk_tree)
            integer,intent(in)::index
            logical,optional,intent(in)::walk_tree
            integer::n,j,a,b,k
            integer,allocatable::marks(:)
            type(value_t)::kv
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing real rounding/inverse arguments',e%line,e%column);return
            end if
            n=size(e%args)
            if(n<1.or.n>2.or.e%intrinsic_mask/=0.or. &
               ((e%op=='asinh'.or.e%op=='acosh').and.n/=1)) then
                call runtime_error('invalid real rounding/inverse count/slots',e%line,e%column);return
            end if
            do j=1,n
                if(.not.valid_expression(e%args(j)))return
                if(e%args(j)==index) then
                    call runtime_error('cyclic real rounding/inverse argument',e%line,e%column);return
                end if
                associate(x=>prog%expressions(e%args(j)))
                if(x%kind==ex_literal) then
                    if(x%value%tag/=x%typ.or.x%value%real_kind/=x%real_kind) then
                        call runtime_error('real rounding/inverse literal metadata differs',e%line,e%column);return
                    end if
                else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section) then
                    if(.not.valid_symbol(x%symbol,allow_absent=.true.))return
                    if(x%typ/=prog%symbols(x%symbol)%typ.or.x%real_kind/=prog%symbols(x%symbol)%real_kind) then
                        call runtime_error('real rounding/inverse declaration differs',e%line,e%column);return
                    end if
                end if
                end associate
            end do
            a=e%args(1);k=prog%expressions(a)%real_kind
            associate(x=>prog%expressions(a))
            if(x%typ/=ty_real.or.(k/=4.and.k/=8).or.x%rank<0.or.x%rank>3) then
                call runtime_error('real rounding/inverse requires REAL4/8 argument',e%line,e%column);return
            end if
            if(x%rank==0.and.(x%extent/=0.or.any(x%dims/=0))) then
                call runtime_error('invalid real rounding/inverse scalar shape',e%line,e%column);return
            end if
            if(e%rank/=x%rank.or.e%extent/=x%extent.or.any(e%dims/=x%dims)) then
                call runtime_error('real rounding/inverse result shape differs',e%line,e%column);return
            end if
            end associate
            if(n==2) then
                b=e%args(2)
                associate(x=>prog%expressions(b))
                if(x%typ/=ty_integer.or.(x%real_kind/=4.and.x%real_kind/=8).or. &
                   x%rank/=0.or.x%extent/=0.or.any(x%dims/=0)) then
                    call runtime_error('AINT/ANINT KIND must be scalar INTEGER',e%line,e%column);return
                end if
                end associate
                if(.not.safe_location_kind(b,0,.false.)) then
                    call runtime_error('AINT/ANINT KIND must be constant',e%line,e%column);return
                end if
                kv=evaluate(b,0)
                if(diag%code/=0)return
                if(kv%tag/=ty_integer.or.(kv%i/=4.and.kv%i/=8)) then
                    call runtime_error('AINT/ANINT support result kinds 4 and 8',e%line,e%column);return
                end if
                k=int(kv%i)
            end if
            if(e%typ/=ty_real.or.e%real_kind/=k) &
                call runtime_error('real rounding/inverse result type/kind differs',e%line,e%column)
            end associate
            if(diag%code/=0)return
            if(present(walk_tree)) then
                if(.not.walk_tree)return
            end if
            ! A selected output kind can hide an inconsistent kind inside a
            ! unary/binary input. Validate the entire unevaluated operand tree
            ! once; its dispatch re-enters only the local guard above.
            allocate(marks(prog%ne),source=0)
            call validate_kind_tree(index,marks,0)
        end subroutine
        recursive subroutine validate_minmax(index,walk_tree)
            integer,intent(in)::index
            logical,optional,intent(in)::walk_tree
            integer,allocatable::marks(:)
            integer::j,a,n,t,k,r,clen
            integer(int64)::extent,dims(3)
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing MIN/MAX arguments',e%line,e%column);return
            end if
            n=size(e%args)
            if(n<2.or.n>16.or.e%intrinsic_mask/=0.or.e%symbol/=0.or.e%left/=0.or.e%right/=0.or. &
               e%stride/=0.or.e%left2/=0.or.e%right2/=0.or.e%stride2/=0.or.e%left3/=0.or. &
               e%right3/=0.or.e%stride3/=0.or.e%third/=0.or.e%length_expr/=0.or. &
               e%constructor_kind_expr/=0.or.e%generic_id/=0.or.e%bound_type/=0.or.e%bound_binding/=0.or. &
               any(e%triplet.neqv.[.true.,.false.,.false.])) then
                call runtime_error('invalid MIN/MAX count or metadata',e%line,e%column);return
            end if
            t=e%typ;k=e%real_kind;r=0;extent=0_int64;dims=0_int64;clen=-1
            if((t/=ty_integer.and.t/=ty_real.and.t/=ty_character).or.(k/=4.and.k/=8).or. &
               (t==ty_character.and.k/=4)) then
                call runtime_error('invalid MIN/MAX result type/kind',e%line,e%column);return
            end if
            if(t==ty_character)clen=0
            do j=1,n
                a=e%args(j)
                if(.not.valid_expression(a))return
                if(a==index)then
                    call runtime_error('cyclic MIN/MAX operand',e%line,e%column);return
                end if
                associate(x=>prog%expressions(a))
                if(x%typ/=t.or.x%real_kind/=k.or.x%rank<0.or.x%rank>3)then
                    call runtime_error('MIN/MAX operand type/kind/rank differs',e%line,e%column);return
                end if
                if(x%kind==ex_literal)then
                    if(x%value%tag/=t.or.x%value%real_kind/=k)then
                        call runtime_error('MIN/MAX literal type/kind differs',e%line,e%column);return
                    end if
                else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section)then
                    if(.not.valid_symbol(x%symbol,allow_absent=.true.))return
                    if(prog%symbols(x%symbol)%typ/=t.or.prog%symbols(x%symbol)%real_kind/=k)then
                        call runtime_error('MIN/MAX declaration type/kind differs',e%line,e%column);return
                    end if
                end if
                if(t==ty_character)then
                    if(x%character_len< -1.or.x%character_len>65536)then
                        call runtime_error('MIN/MAX CHARACTER length limit exceeded',e%line,e%column);return
                    end if
                    if(clen<0.or.x%character_len<0)then
                        clen=-1
                    else
                        clen=max(clen,x%character_len)
                    end if
                end if
                if(x%rank==0)then
                    if(x%extent/=0.or.any(x%dims/=0))then
                        call runtime_error('invalid MIN/MAX scalar shape',e%line,e%column);return
                    end if
                    cycle
                end if
                if(r>0)then
                    if(r/=x%rank.or.(extent>=0.and.x%extent>=0.and.extent/=x%extent))then
                        call runtime_error('MIN/MAX operands do not conform',e%line,e%column);return
                    end if
                    if(r>=2)then
                        if(any(dims>=0.and.x%dims>=0.and.dims/=x%dims))then
                            call runtime_error('MIN/MAX dimensions do not conform',e%line,e%column);return
                        end if
                        where(dims<0.or.x%dims<0)dims=-1_int64
                    end if
                    if(extent<0.or.x%extent<0)then
                        extent=-1_int64;cycle
                    end if
                end if
                r=x%rank;extent=x%extent;dims=x%dims
                end associate
            end do
            if(e%rank/=r.or.e%extent/=extent.or.any(e%dims/=dims).or.e%character_len/=clen)then
                call runtime_error('MIN/MAX result shape/length differs',e%line,e%column);return
            end if
            end associate
            if(t/=ty_character)return
            allocate(marks(prog%ne),source=0)
            call validate_minmax_character_tree(index,marks,0)
            if(diag%code/=0)return
            if(present(walk_tree))then
                if(.not.walk_tree)return
            end if
            marks=0
            call validate_kind_tree(index,marks,0)
        end subroutine
        recursive subroutine validate_minmax_character_tree(index,marks,depth)
            integer,intent(in)::index,depth
            integer,intent(inout)::marks(:)
            integer::j,s,result,children(10)
            if(diag%code/=0)return
            if(.not.valid_expression(index))return
            if(depth>512.or.marks(index)==1)then
                call runtime_error('cyclic MIN/MAX operand',0,0);return
            end if
            if(marks(index)==2)return
            marks(index)=1
            associate(x=>prog%expressions(index))
            if(x%typ==ty_character)then
                if(x%real_kind/=4.or.x%character_len < -1.or.x%character_len>65536)then
                    call runtime_error('MIN/MAX CHARACTER kind/length metadata differs',x%line,x%column);return
                end if
                if(x%kind==ex_literal)then
                    if(.not.allocated(x%value%s))then
                        call runtime_error('missing MIN/MAX CHARACTER literal',x%line,x%column);return
                    end if
                    if(x%value%real_kind/=4.or.x%character_len/=len(x%value%s))then
                        call runtime_error('MIN/MAX CHARACTER literal cache differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_user_call)then
                    s=x%symbol
                    if(s<1.or.s>prog%np)then
                        call runtime_error('invalid MIN/MAX function reference',x%line,x%column);return
                    end if
                    result=prog%procedures(s)%result_symbol
                    if(result<1.or.result>prog%ns)then
                        call runtime_error('invalid MIN/MAX function result',x%line,x%column);return
                    end if
                    if(prog%symbols(result)%typ/=ty_character.or.prog%symbols(result)%real_kind/=4)then
                        call runtime_error('MIN/MAX function result kind differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section)then
                    s=x%symbol
                    if(.not.valid_symbol(s,allow_absent=.true.))return
                    if(prog%symbols(s)%real_kind/=4.or.prog%symbols(s)%character_len/=x%character_len)then
                        call runtime_error('MIN/MAX CHARACTER declaration kind differs',x%line,x%column);return
                    end if
                end if
            end if
            children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third]
            do j=1,size(children)
                if(children(j)==0)cycle
                call validate_minmax_character_tree(children(j),marks,depth+1)
                if(diag%code/=0)return
            end do
            if(allocated(x%args))then
                do j=1,size(x%args)
                    if(x%args(j)==0.and.x%kind==ex_user_call)cycle
                    call validate_minmax_character_tree(x%args(j),marks,depth+1)
                    if(diag%code/=0)return
                end do
            end if
            end associate
            marks(index)=2
        end subroutine
        recursive subroutine validate_bit_intrinsic(index,walk_tree)
            integer,intent(in)::index
            logical,optional,intent(in)::walk_tree
            integer,allocatable::marks(:)
            integer::selector,k
            type(value_t)::kv
            if(.not.valid_bit_intrinsic(prog,index))then
                call runtime_error('invalid bit intrinsic metadata',0,0);return
            end if
            allocate(marks(prog%ne),source=0)
            call validate_bit_integer_tree(index,marks,0)
            if(diag%code/=0)return
            associate(e=>prog%expressions(index))
            if(e%op=='maskl'.or.e%op=='maskr')then
                k=4
                if(size(e%args)==2)then
                    selector=e%args(2)
                    if(.not.safe_location_kind(selector,0,.false.))then
                        call runtime_error('MASKL/MASKR KIND must be constant',e%line,e%column);return
                    end if
                    kv=evaluate(selector,0)
                    if(diag%code/=0)return
                    if(kv%tag/=ty_integer.or.(kv%i/=4.and.kv%i/=8))then
                        call runtime_error('MASKL/MASKR support result kinds 4 and 8',e%line,e%column);return
                    end if
                    k=int(kv%i)
                end if
                if(e%real_kind/=k)then
                    call runtime_error('MASKL/MASKR result KIND cache differs',e%line,e%column);return
                end if
            end if
            end associate
            if(present(walk_tree))then
                if(.not.walk_tree)return
            end if
            marks=0
            call validate_kind_tree(index,marks,0)
        end subroutine
        recursive subroutine validate_bit_integer_tree(index,marks,depth)
            integer,intent(in)::index,depth
            integer,intent(inout)::marks(:)
            integer::j,s,r,children(12)
            integer(int64)::extent,dims(3),lo(3),hi(3)
            if(diag%code/=0)return
            if(.not.valid_expression(index))return
            if(depth>512.or.marks(index)==1)then
                call runtime_error('cyclic or excessive bit intrinsic operands',0,0);return
            end if
            if(marks(index)==2)return
            marks(index)=1
            associate(x=>prog%expressions(index))
            if(x%typ==ty_integer)then
                if(x%character_len/=-1.or.(x%real_kind/=4.and.x%real_kind/=8))then
                    call runtime_error('invalid bit intrinsic INTEGER metadata',x%line,x%column);return
                end if
                if(x%kind==ex_literal)then
                    if(x%value%tag/=ty_integer.or.x%value%real_kind/=x%real_kind.or. &
                       x%rank/=0.or.x%extent/=0.or.any(x%dims/=0))then
                        call runtime_error('bit intrinsic literal metadata differs',x%line,x%column);return
                    end if
                    if(.not.check_integer(x%value%i,x%line,x%column,x%real_kind))return
                else if(x%kind==ex_variable)then
                    if(.not.valid_bit_variable(prog,index))then
                        call runtime_error('bit intrinsic declaration metadata differs',x%line,x%column);return
                    end if
                    s=x%symbol;r=x%rank;extent=0_int64;dims=0_int64
                    if(prog%symbols(s)%is_parameter.and.r==0)then
                        associate(v=>prog%symbols(s))
                        if(.not.v%parameter_ready.or.allocated(v%constant_values).or. &
                           v%constant_value%tag/=ty_integer.or.v%constant_value%real_kind/=v%real_kind)then
                            call runtime_error('bit intrinsic PARAMETER kind/type cache differs',x%line,x%column);return
                        end if
                        if(.not.check_integer(v%constant_value%i,x%line,x%column,v%real_kind))return
                        end associate
                    end if
                    if(r<0.or.r>3)then
                        call runtime_error('invalid bit intrinsic declaration rank',x%line,x%column);return
                    end if
                    associate(v=>prog%symbols(s))
                    if(r>0)then
                        if(v%is_allocatable.or.v%is_pointer.or.v%assumed_shape.or.v%is_automatic)then
                            extent=-1_int64
                            if(r>=2)dims=-1_int64
                        else
                            lo=[v%lower_bound,v%lower_bound2,v%lower_bound3]
                            hi=[v%upper_bound,v%upper_bound2,v%upper_bound3]
                            if(any(lo(:r)<imin).or.any(lo(:r)>imax).or.any(hi(:r)<imin).or.any(hi(:r)>imax))then
                                call runtime_error('invalid bit intrinsic declaration bounds',x%line,x%column);return
                            end if
                            dims=1_int64;dims(:r)=max(0_int64,hi(:r)-lo(:r)+1_int64)
                            if(any(dims>imax))then
                                call runtime_error('excessive bit intrinsic declaration extent',x%line,x%column);return
                            end if
                            extent=shape_size(dims)
                            if(extent>max_array_elements)then
                                call runtime_error('bit intrinsic declaration exceeds array limit',x%line,x%column);return
                            end if
                            if(r==1)dims=0_int64
                        end if
                    end if
                    end associate
                    if(x%extent/=extent.or.any(x%dims/=dims))then
                        call runtime_error('bit intrinsic declaration shape differs',x%line,x%column);return
                    end if
                end if
            end if
            children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2, &
                x%left3,x%right3,x%stride3,x%third,x%length_expr,x%constructor_kind_expr]
            do j=1,size(children)
                if(children(j)==0)cycle
                call validate_bit_integer_tree(children(j),marks,depth+1)
                if(diag%code/=0)return
            end do
            if(allocated(x%args))then
                do j=1,size(x%args)
                    if(x%args(j)==0.and.x%kind==ex_user_call)cycle
                    call validate_bit_integer_tree(x%args(j),marks,depth+1)
                    if(diag%code/=0)return
                end do
            end if
            end associate
            marks(index)=2
        end subroutine
        recursive subroutine validate_lexical_intrinsic(index,walk_tree)
            integer,intent(in)::index
            logical,optional,intent(in)::walk_tree
            integer,allocatable::marks(:)
            integer::j,a,n,t,k,r
            integer(int64)::extent,dims(3)
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing lexical comparison arguments',e%line,e%column);return
            end if
            n=size(e%args);k=4;r=0;extent=0_int64;dims=0_int64
            if(n/=2.or.e%intrinsic_mask/=0.or.e%typ/=ty_logical.or.e%real_kind/=4.or.e%character_len/=-1) then
                call runtime_error('invalid lexical comparison result/count metadata',e%line,e%column);return
            end if
            do j=1,n
                a=e%args(j)
                if(.not.valid_expression(a)) return
                if(a==index) then
                    call runtime_error('cyclic lexical comparison argument',e%line,e%column);return
                end if
                associate(x=>prog%expressions(a))
                t=ty_character
                if(x%kind==ex_literal) then
                    if(x%value%tag/=x%typ.or.x%value%real_kind/=x%real_kind) then
                        call runtime_error('lexical comparison literal cache differs',e%line,e%column);return
                    end if
                else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section) then
                    if(.not.valid_symbol(x%symbol,allow_absent=.true.))return
                    if(x%typ/=prog%symbols(x%symbol)%typ.or.x%real_kind/=prog%symbols(x%symbol)%real_kind) then
                        call runtime_error('lexical comparison declaration differs',e%line,e%column);return
                    end if
                end if
                if(x%typ/=t.or.(x%real_kind/=4.and.x%real_kind/=8).or. &
                   x%real_kind/=k.or.x%rank<0.or.x%rank>3) then
                    call runtime_error('lexical comparison operand type/kind/rank differs',e%line,e%column);return
                end if
                if(x%rank==0) then
                    if(x%extent/=0.or.any(x%dims/=0)) then
                        call runtime_error('invalid lexical comparison scalar shape',e%line,e%column);return
                    end if
                    cycle
                end if
                if(r>0) then
                    if(r/=x%rank.or.(extent>=0.and.x%extent>=0.and.extent/=x%extent)) then
                        call runtime_error('lexical comparison operands do not conform',e%line,e%column);return
                    end if
                    if(r>=2) then
                        if(any(dims>=0.and.x%dims>=0.and.dims/=x%dims)) then
                            call runtime_error('lexical comparison dimensions do not conform',e%line,e%column);return
                        end if
                        where(dims<0.or.x%dims<0) dims=-1_int64
                    end if
                    if(extent<0.or.x%extent<0) then
                        extent=-1_int64;cycle
                    end if
                end if
                r=x%rank;extent=x%extent;dims=x%dims
                end associate
            end do
            if(e%rank/=r.or.e%extent/=extent.or.any(e%dims/=dims)) &
                call runtime_error('lexical comparison result shape differs',e%line,e%column)
            end associate
            if(diag%code/=0)return
            allocate(marks(prog%ne),source=0)
            call validate_lexical_character_tree(index,marks,0)
            if(diag%code/=0)return
            if(present(walk_tree)) then
                if(.not.walk_tree)return
            end if
            marks=0
            call validate_kind_tree(index,marks,0)
        end subroutine
        recursive subroutine validate_lexical_character_tree(index,marks,depth)
            integer,intent(in)::index,depth
            integer,intent(inout)::marks(:)
            integer::j,s,result,children(10)
            if(diag%code/=0)return
            if(.not.valid_expression(index))return
            if(depth>512.or.marks(index)==1)then
                call runtime_error('cyclic lexical comparison operand',0,0);return
            end if
            if(marks(index)==2)return
            marks(index)=1
            associate(x=>prog%expressions(index))
            if(x%typ==ty_character)then
                if(x%real_kind/=4.or.x%character_len < -1.or.x%character_len>65536)then
                    call runtime_error('lexical comparison CHARACTER kind/length metadata differs',x%line,x%column);return
                end if
                if(x%kind==ex_literal)then
                    if(.not.allocated(x%value%s))then
                        call runtime_error('missing lexical comparison CHARACTER literal',x%line,x%column);return
                    end if
                    if(x%value%real_kind/=4.or.x%character_len/=len(x%value%s))then
                        call runtime_error('lexical comparison CHARACTER literal cache differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_user_call)then
                    s=x%symbol
                    if(s<1.or.s>prog%np)then
                        call runtime_error('invalid lexical comparison function reference',x%line,x%column);return
                    end if
                    result=prog%procedures(s)%result_symbol
                    if(result<1.or.result>prog%ns)then
                        call runtime_error('invalid lexical comparison function result',x%line,x%column);return
                    end if
                    if(prog%symbols(result)%typ/=ty_character.or.prog%symbols(result)%real_kind/=4)then
                        call runtime_error('lexical comparison function result kind differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section)then
                    s=x%symbol
                    if(.not.valid_symbol(s,allow_absent=.true.))return
                    if(prog%symbols(s)%real_kind/=4.or.prog%symbols(s)%character_len/=x%character_len)then
                        call runtime_error('lexical comparison CHARACTER declaration kind differs',x%line,x%column);return
                    end if
                end if
            end if
            children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third]
            do j=1,size(children)
                if(children(j)==0)cycle
                call validate_lexical_character_tree(children(j),marks,depth+1)
                if(diag%code/=0)return
            end do
            if(allocated(x%args))then
                do j=1,size(x%args)
                    if(x%args(j)==0.and.x%kind==ex_user_call)cycle
                    call validate_lexical_character_tree(x%args(j),marks,depth+1)
                    if(diag%code/=0)return
                end do
            end if
            end associate
            marks(index)=2
        end subroutine
        recursive subroutine validate_inverse_trig(index,walk_tree)
            integer,intent(in)::index
            logical,optional,intent(in)::walk_tree
            integer,allocatable::marks(:)
            integer::j,a,n,t,k,r
            integer(int64)::extent,dims(3)
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing inverse trig arguments',e%line,e%column);return
            end if
            n=size(e%args)
            if(n<1.or.n>2.or.(e%op=='asin'.and.n/=1).or.(e%op=='atan2'.and.n/=2).or. &
               e%intrinsic_mask/=0) then
                call runtime_error('invalid inverse trig count/slots',e%line,e%column);return
            end if
            t=e%typ;k=e%real_kind;r=0;extent=0_int64;dims=0_int64
            if(t/=ty_real.or.(k/=4.and.k/=8)) then
                call runtime_error('invalid inverse trig type/kind',e%line,e%column);return
            end if
            do j=1,n
                a=e%args(j)
                if(.not.valid_expression(a)) return
                if(a==index) then
                    call runtime_error('cyclic inverse trig argument',e%line,e%column);return
                end if
                associate(x=>prog%expressions(a))
                t=ty_real
                if(x%kind==ex_literal) then
                    if(x%value%tag/=x%typ.or.x%value%real_kind/=x%real_kind) then
                        call runtime_error('inverse trig literal cache differs',e%line,e%column);return
                    end if
                else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section) then
                    if(.not.valid_symbol(x%symbol,allow_absent=.true.))return
                    if(x%typ/=prog%symbols(x%symbol)%typ.or.x%real_kind/=prog%symbols(x%symbol)%real_kind) then
                        call runtime_error('inverse trig declaration differs',e%line,e%column);return
                    end if
                end if
                if(x%typ/=t.or.(x%real_kind/=4.and.x%real_kind/=8).or. &
                   x%real_kind/=k.or.x%rank<0.or.x%rank>3) then
                    call runtime_error('inverse trig operand type/kind/rank differs',e%line,e%column);return
                end if
                if(x%rank==0) then
                    if(x%extent/=0.or.any(x%dims/=0)) then
                        call runtime_error('invalid inverse trig scalar shape',e%line,e%column);return
                    end if
                    cycle
                end if
                if(r>0) then
                    if(r/=x%rank.or.(extent>=0.and.x%extent>=0.and.extent/=x%extent)) then
                        call runtime_error('inverse trig operands do not conform',e%line,e%column);return
                    end if
                    if(r>=2) then
                        if(any(dims>=0.and.x%dims>=0.and.dims/=x%dims)) then
                            call runtime_error('inverse trig dimensions do not conform',e%line,e%column);return
                        end if
                        where(dims<0.or.x%dims<0) dims=-1_int64
                    end if
                    if(extent<0.or.x%extent<0) then
                        extent=-1_int64;cycle
                    end if
                end if
                r=x%rank;extent=x%extent;dims=x%dims
                end associate
            end do
            if(e%rank/=r.or.e%extent/=extent.or.any(e%dims/=dims)) &
                call runtime_error('inverse trig result shape differs',e%line,e%column)
            end associate
            if(diag%code/=0)return
            if(present(walk_tree)) then
                if(.not.walk_tree)return
            end if
            allocate(marks(prog%ne),source=0)
            call validate_kind_tree(index,marks,0)
        end subroutine
        recursive subroutine validate_dprod_tand(index,walk_tree)
            integer,intent(in)::index
            logical,optional,intent(in)::walk_tree
            integer,allocatable::marks(:)
            integer::j,a,n,t,k,r
            integer(int64)::extent,dims(3)
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing DPROD/TAND arguments',e%line,e%column);return
            end if
            n=1
            if(e%op=='dprod') n=2
            if(size(e%args)/=n.or.e%intrinsic_mask/=0) then
                call runtime_error('invalid DPROD/TAND count/slots',e%line,e%column);return
            end if
            t=e%typ;k=e%real_kind;r=0;extent=0_int64;dims=0_int64
            if(t/=ty_real.or.(k/=4.and.k/=8)) then
                call runtime_error('invalid DPROD/TAND type/kind',e%line,e%column);return
            end if
            do j=1,n
                a=e%args(j)
                if(.not.valid_expression(a)) return
                if(a==index) then
                    call runtime_error('cyclic DPROD/TAND argument',e%line,e%column);return
                end if
                associate(x=>prog%expressions(a))
                t=ty_real
                if(e%op=='dprod'.and.(x%real_kind/=4.or.k/=8)) then
                    call runtime_error('DPROD requires REAL4 operands and REAL8 result',e%line,e%column);return
                end if
                if(x%kind==ex_literal) then
                    if(x%value%tag/=x%typ.or.x%value%real_kind/=x%real_kind) then
                        call runtime_error('DPROD/TAND literal cache differs',e%line,e%column);return
                    end if
                else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section) then
                    if(.not.valid_symbol(x%symbol,allow_absent=.true.))return
                    if(x%typ/=prog%symbols(x%symbol)%typ.or.x%real_kind/=prog%symbols(x%symbol)%real_kind) then
                        call runtime_error('DPROD/TAND declaration differs',e%line,e%column);return
                    end if
                end if
                if(x%typ/=t.or.(x%real_kind/=4.and.x%real_kind/=8).or. &
                   (e%op=='tand'.and.x%real_kind/=k).or.x%rank<0.or.x%rank>3) then
                    call runtime_error('DPROD/TAND operand type/kind/rank differs',e%line,e%column);return
                end if
                if(x%rank==0) then
                    if(x%extent/=0.or.any(x%dims/=0)) then
                        call runtime_error('invalid DPROD/TAND scalar shape',e%line,e%column);return
                    end if
                    cycle
                end if
                if(r>0) then
                    if(r/=x%rank.or.(extent>=0.and.x%extent>=0.and.extent/=x%extent)) then
                        call runtime_error('DPROD/TAND operands do not conform',e%line,e%column);return
                    end if
                    if(r>=2) then
                        if(any(dims>=0.and.x%dims>=0.and.dims/=x%dims)) then
                            call runtime_error('DPROD/TAND dimensions do not conform',e%line,e%column);return
                        end if
                        where(dims<0.or.x%dims<0) dims=-1_int64
                    end if
                    if(extent<0.or.x%extent<0) then
                        extent=-1_int64;cycle
                    end if
                end if
                r=x%rank;extent=x%extent;dims=x%dims
                end associate
            end do
            if(e%rank/=r.or.e%extent/=extent.or.any(e%dims/=dims)) &
                call runtime_error('DPROD/TAND result shape differs',e%line,e%column)
            end associate
            if(diag%code/=0)return
            if(present(walk_tree)) then
                if(.not.walk_tree)return
            end if
            allocate(marks(prog%ne),source=0)
            call validate_kind_tree(index,marks,0)
        end subroutine
        subroutine validate_erf_bessel(index)
            integer,intent(in)::index
            integer::j,a,n,t,k,r
            integer(int64)::extent,dims(3)
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing ERF/Bessel arguments',e%line,e%column);return
            end if
            n=1
            if(e%op=='bessel_jn'.or.e%op=='bessel_yn') n=2
            if(size(e%args)/=n.or.e%intrinsic_mask/=0) then
                call runtime_error('invalid ERF/Bessel count/slots',e%line,e%column);return
            end if
            t=e%typ;k=e%real_kind;r=0;extent=0_int64;dims=0_int64
            if(t/=ty_real.or.(k/=4.and.k/=8)) then
                call runtime_error('invalid ERF/Bessel type/kind',e%line,e%column);return
            end if
            do j=1,n
                a=e%args(j)
                if(.not.valid_expression(a)) return
                if(a==index) then
                    call runtime_error('cyclic ERF/Bessel argument',e%line,e%column);return
                end if
                associate(x=>prog%expressions(a))
                t=ty_real
                if(n==2.and.j==1) t=ty_integer
                if(x%typ/=t.or.(x%real_kind/=4.and.x%real_kind/=8).or. &
                   (j==n.and.x%real_kind/=k).or.x%rank<0.or.x%rank>3) then
                    call runtime_error('ERF/Bessel operand type/kind/rank differs',e%line,e%column);return
                end if
                if(x%rank==0) then
                    if(x%extent/=0.or.any(x%dims/=0)) then
                        call runtime_error('invalid ERF/Bessel scalar shape',e%line,e%column);return
                    end if
                    cycle
                end if
                if(r>0) then
                    if(r/=x%rank.or.(extent>=0.and.x%extent>=0.and.extent/=x%extent)) then
                        call runtime_error('ERF/Bessel operands do not conform',e%line,e%column);return
                    end if
                    if(r>=2) then
                        if(any(dims>=0.and.x%dims>=0.and.dims/=x%dims)) then
                            call runtime_error('ERF/Bessel dimensions do not conform',e%line,e%column);return
                        end if
                        where(dims<0.or.x%dims<0) dims=-1_int64
                    end if
                    if(extent<0.or.x%extent<0) then
                        extent=-1_int64;cycle
                    end if
                end if
                r=x%rank;extent=x%extent;dims=x%dims
                end associate
            end do
            if(e%rank/=r.or.e%extent/=extent.or.any(e%dims/=dims)) &
                call runtime_error('ERF/Bessel result shape differs',e%line,e%column)
            end associate
        end subroutine
        subroutine validate_erfc_scaled(index)
            integer,intent(in)::index
            integer::arg
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing ERFC_SCALED argument',e%line,e%column);return
            end if
            if(size(e%args)/=1.or.e%intrinsic_mask/=0.or.e%typ/=ty_real.or. &
               (e%real_kind/=4.and.e%real_kind/=8)) then
                call runtime_error('invalid ERFC_SCALED count/result metadata',e%line,e%column);return
            end if
            arg=e%args(1)
            if(.not.valid_expression(arg)) return
            if(arg==index) then
                call runtime_error('cyclic ERFC_SCALED argument',e%line,e%column);return
            end if
            associate(a=>prog%expressions(arg))
            if(a%typ/=ty_real.or.a%real_kind/=e%real_kind.or.a%rank<0.or.a%rank>3) then
                call runtime_error('ERFC_SCALED requires matching REAL kind 4 or 8',e%line,e%column);return
            end if
            if(e%rank/=a%rank.or.e%extent/=a%extent.or.any(e%dims/=a%dims)) &
                call runtime_error('ERFC_SCALED result shape differs',e%line,e%column)
            end associate
            end associate
        end subroutine
        subroutine validate_isnan(index)
            integer,intent(in)::index
            integer::arg
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing ISNAN argument',e%line,e%column);return
            end if
            if(size(e%args)/=1.or.e%intrinsic_mask/=0.or.e%typ/=ty_logical.or.e%real_kind/=4) then
                call runtime_error('invalid ISNAN count/result metadata',e%line,e%column);return
            end if
            arg=e%args(1)
            if(.not.valid_expression(arg)) return
            if(arg==index) then
                call runtime_error('cyclic ISNAN argument',e%line,e%column);return
            end if
            associate(a=>prog%expressions(arg))
            if(a%typ/=ty_real.or.(a%real_kind/=4.and.a%real_kind/=8).or.a%rank<0.or.a%rank>3) then
                call runtime_error('ISNAN requires REAL kind 4 or 8',e%line,e%column);return
            end if
            if(e%rank/=a%rank.or.e%extent/=a%extent.or.any(e%dims/=a%dims)) &
                call runtime_error('ISNAN result shape differs',e%line,e%column)
            end associate
            end associate
        end subroutine
        subroutine validate_spacing_nearest(index)
            integer,intent(in)::index
            integer::j,a,n,t,k,r
            integer(int64)::extent,dims(3)
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing SPACING/NEAREST arguments',e%line,e%column);return
            end if
            n=2
            if(e%op=='spacing') n=1
            if(size(e%args)/=n.or.e%intrinsic_mask/=0) then
                call runtime_error('invalid SPACING/NEAREST count/slots',e%line,e%column);return
            end if
            t=e%typ;k=e%real_kind;r=0;extent=0_int64;dims=0_int64
            if(t/=ty_real.or.(k/=4.and.k/=8)) then
                call runtime_error('invalid SPACING/NEAREST type/kind',e%line,e%column);return
            end if
            do j=1,n
                a=e%args(j)
                if(.not.valid_expression(a)) return
                if(a==index) then
                    call runtime_error('cyclic SPACING/NEAREST argument',e%line,e%column);return
                end if
                associate(x=>prog%expressions(a))
                if(x%typ/=ty_real.or.(x%real_kind/=4.and.x%real_kind/=8).or. &
                   (j==1.and.x%real_kind/=k).or.x%rank<0.or.x%rank>3) then
                    call runtime_error('SPACING/NEAREST operand type/kind/rank differs',e%line,e%column);return
                end if
                if(x%rank==0) then
                    if(x%extent/=0.or.any(x%dims/=0)) then
                        call runtime_error('invalid SPACING/NEAREST scalar shape',e%line,e%column);return
                    end if
                    cycle
                end if
                if(r>0) then
                    if(r/=x%rank.or.(extent>=0.and.x%extent>=0.and.extent/=x%extent)) then
                        call runtime_error('SPACING/NEAREST operands do not conform',e%line,e%column);return
                    end if
                    if(r>=2) then
                        if(any(dims>=0.and.x%dims>=0.and.dims/=x%dims)) then
                            call runtime_error('SPACING/NEAREST dimensions do not conform',e%line,e%column);return
                        end if
                        where(dims<0.or.x%dims<0) dims=-1_int64
                    end if
                    if(extent<0.or.x%extent<0) then
                        extent=-1_int64;cycle
                    end if
                end if
                r=x%rank;extent=x%extent;dims=x%dims
                end associate
            end do
            if(e%rank/=r.or.e%extent/=extent.or.any(e%dims/=dims)) &
                call runtime_error('SPACING/NEAREST result shape differs',e%line,e%column)
            end associate
        end subroutine
        subroutine validate_elementary_math(index)
            integer,intent(in)::index
            integer::j,a,n,t,k,r
            integer(int64)::extent,dims(3)
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing elementary math arguments',e%line,e%column);return
            end if
            n=2
            if(e%op=='log_gamma') n=1
            if(size(e%args)/=n.or.e%intrinsic_mask/=0) then
                call runtime_error('invalid elementary math count/slots',e%line,e%column);return
            end if
            t=e%typ;k=e%real_kind;r=0;extent=0_int64;dims=0_int64
            if((t/=ty_integer.and.t/=ty_real).or.(e%op=='log_gamma'.and.t/=ty_real).or.(k/=4.and.k/=8)) then
                call runtime_error('invalid elementary math type/kind',e%line,e%column);return
            end if
            do j=1,n
                a=e%args(j)
                if(.not.valid_expression(a)) return
                if(a==index) then
                    call runtime_error('cyclic elementary math argument',e%line,e%column);return
                end if
                associate(x=>prog%expressions(a))
                if(x%typ/=t.or.x%real_kind/=k.or.x%rank<0.or.x%rank>3) then
                    call runtime_error('elementary math operand type/kind/rank differs',e%line,e%column);return
                end if
                if(x%rank==0) then
                    if(x%extent/=0.or.any(x%dims/=0)) then
                        call runtime_error('invalid elementary math scalar shape',e%line,e%column);return
                    end if
                    cycle
                end if
                if(r>0) then
                    if(r/=x%rank.or.(extent>=0.and.x%extent>=0.and.extent/=x%extent)) then
                        call runtime_error('elementary math operands do not conform',e%line,e%column);return
                    end if
                    if(r>=2) then
                        if(any(dims>=0.and.x%dims>=0.and.dims/=x%dims)) then
                            call runtime_error('elementary math dimensions do not conform',e%line,e%column);return
                        end if
                        where(dims<0.or.x%dims<0) dims=-1_int64
                    end if
                    if(extent<0.or.x%extent<0) then
                        extent=-1_int64;cycle
                    end if
                end if
                r=x%rank;extent=x%extent;dims=x%dims
                end associate
            end do
            if(e%rank/=r.or.e%extent/=extent.or.any(e%dims/=dims)) &
                call runtime_error('elementary math result shape differs',e%line,e%column)
            end associate
        end subroutine
        recursive subroutine validate_utility_intrinsic(index)
            integer,intent(in)::index
            integer::n,j,a,b,t,r,k
            associate(e=>prog%expressions(index))
            if(e%op=='fraction'.or.e%op=='exponent'.or.e%op=='set_exponent'.or.e%op=='iachar') then
                call validate_model_decomposition(index)
                return
            end if
            if(e%op=='asin'.or.e%op=='atan'.or.e%op=='atan2') then
                call validate_inverse_trig(index)
                return
            end if
            if(is_degree_trig(e%op)) then
                call validate_degree_trig(index)
                return
            end if
            if(e%op=='acos'.or.e%op=='rrspacing') then
                call validate_acos(index)
                return
            end if
            if(e%op=='real') then
                call validate_real_conversion(index)
                return
            end if
            if(e%op=='dprod'.or.e%op=='tand') then
                call validate_dprod_tand(index)
                return
            end if
            if(e%op=='aint'.or.e%op=='anint'.or.e%op=='asinh'.or.e%op=='acosh') then
                call validate_real_round_inverse(index)
                return
            end if
            if(is_erf_bessel(e%op)) then
                call validate_erf_bessel(index)
                return
            end if
            if(e%op=='erfc_scaled') then
                call validate_erfc_scaled(index)
                return
            end if
            if(e%op=='isnan') then
                call validate_isnan(index)
                return
            end if
            if(e%op=='spacing'.or.e%op=='nearest') then
                call validate_spacing_nearest(index)
                return
            end if
            if(e%op=='dim'.or.e%op=='sign'.or.e%op=='log_gamma') then
                call validate_elementary_math(index)
                return
            end if
            if(e%op=='repeat') then
                call validate_repeat_metadata(index)
                return
            end if
            if(e%op=='shape') then
                call validate_shape_intrinsic(index)
                return
            end if
            if(e%op=='nint'.or.e%op=='floor'.or.e%op=='ceiling') then
                call validate_rounding_intrinsic(index)
                return
            end if
            if(e%op=='min'.or.e%op=='max')then
                call validate_minmax(index)
                return
            end if
            if(is_bit_intrinsic(e%op))then
                call validate_bit_intrinsic(index)
                return
            end if
            if(is_lexical_intrinsic(e%op)) then
                call validate_lexical_intrinsic(index)
                return
            end if
            if(is_character_intrinsic(e%op)) then
                call validate_character_intrinsic(index)
                return
            end if
            if(e%op=='char'.or.e%op=='achar') then
                call validate_character_code(index)
                return
            end if
            if(is_location_reduction(e%op)) then
                call validate_location_metadata(index)
                return
            end if
            if(is_bounds_inquiry(e%op))then
                call validate_bounds_inquiry(index)
                return
            end if
            if(e%op=='transpose'.or.e%op=='norm2')then
                call validate_matrix_call(index)
                return
            end if
            if(e%op=='eoshift') then
                call validate_eoshift(index)
                return
            end if
            if(e%op=='cshift') then
                call validate_cshift(index)
                return
            end if
            if(e%op=='pack') then
                call validate_pack_metadata(index)
                return
            end if
            if(e%op/='merge'.and.e%op/='dble'.and..not.is_logical_reduction(e%op).and. &
               e%op/='sinh'.and.e%op/='cosh'.and.e%op/='tanh'.and. &
               e%op/='sin'.and.e%op/='cos'.and.e%op/='tan'.and.e%op/='log10') return
            if(.not.allocated(e%args)) then
                call runtime_error('missing utility intrinsic arguments',e%line,e%column);return
            end if
            n=size(e%args)
            if(n<1.or.n>3) then
                call runtime_error('invalid utility intrinsic argument count',e%line,e%column);return
            end if
            do j=1,n
                if(.not.valid_expression(e%args(j))) return
                if(e%args(j)==index) then
                    call runtime_error('cyclic utility intrinsic argument',e%line,e%column);return
                end if
            end do
            a=e%args(1);t=prog%expressions(a)%typ;r=prog%expressions(a)%rank;k=prog%expressions(a)%real_kind
            if(e%op=='merge') then
                if(n/=3) then
                    call runtime_error('MERGE requires three arguments',e%line,e%column);return
                end if
                b=e%args(2)
                if(t<ty_integer.or.t>ty_character.or.prog%expressions(b)%typ/=t.or. &
                   prog%expressions(b)%real_kind/=k.or.prog%expressions(e%args(3))%typ/=ty_logical) then
                    call runtime_error('MERGE source type/kind or MASK differs',e%line,e%column);return
                end if
                if(t==ty_character) then
                    if(prog%expressions(a)%character_len>=0.and.prog%expressions(b)%character_len>=0.and. &
                       prog%expressions(a)%character_len/=prog%expressions(b)%character_len) then
                        call runtime_error('MERGE CHARACTER source lengths must match',e%line,e%column);return
                    end if
                    if(e%character_len/=prog%expressions(a)%character_len) then
                        call runtime_error('MERGE CHARACTER result length differs',e%line,e%column);return
                    end if
                end if
                do j=2,n
                    b=e%args(j)
                    if(r>0.and.prog%expressions(b)%rank>0.and.r/=prog%expressions(b)%rank) then
                        call runtime_error('MERGE argument ranks do not conform',e%line,e%column);return
                    end if
                    r=max(r,prog%expressions(b)%rank)
                end do
            else if(e%op=='sinh'.or.e%op=='cosh'.or.e%op=='tanh'.or. &
                    e%op=='sin'.or.e%op=='cos'.or.e%op=='tan'.or.e%op=='log10') then
                if(n/=1.or.t/=ty_real.or.(k/=4.and.k/=8)) then
                    call runtime_error('trigonometric/hyperbolic intrinsic requires one REAL argument',e%line,e%column);return
                end if
                if(e%extent/=prog%expressions(a)%extent.or.any(e%dims/=prog%expressions(a)%dims)) then
                    call runtime_error('trigonometric/hyperbolic intrinsic result shape differs',e%line,e%column);return
                end if
            else if(e%op=='dble') then
                if(n/=1.or.(t/=ty_integer.and.t/=ty_real).or.(k/=4.and.k/=8)) then
                    call runtime_error('DBLE requires one numeric argument',e%line,e%column);return
                end if
                t=ty_real;k=8
            else
                if(t/=ty_logical.or.k/=4.or.r<1.or.r>2.or.e%intrinsic_mask<1.or.e%intrinsic_mask>7.or. &
                   .not.btest(e%intrinsic_mask,0).or.popcnt(e%intrinsic_mask)/=n.or. &
                   (e%op/='count'.and.btest(e%intrinsic_mask,2))) then
                    call runtime_error('invalid logical reduction MASK/slots',e%line,e%column);return
                end if
                r=0
                if(btest(e%intrinsic_mask,1)) r=prog%expressions(a)%rank-1
                k=4
                if(e%op=='count') then
                    t=ty_integer
                    if(btest(e%intrinsic_mask,2)) k=e%real_kind
                end if
                do j=2,n
                    b=e%args(j)
                    if(prog%expressions(b)%typ/=ty_integer.or.prog%expressions(b)%rank/=0) then
                        call runtime_error('logical reduction DIM/KIND must be scalar INTEGER',e%line,e%column);return
                    end if
                end do
            end if
            if(e%typ/=t.or.e%real_kind/=k.or.e%rank/=r.or.r<0.or.r>3.or.(k/=4.and.k/=8)) then
                call runtime_error('utility intrinsic result type/kind/rank differs',e%line,e%column);return
            end if
            end associate
        end subroutine
        recursive subroutine validate_rounding_intrinsic(index)
            integer,intent(in)::index
            integer::a,b,n,k
            type(value_t)::kind_value
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing rounding intrinsic arguments',e%line,e%column);return
            end if
            n=size(e%args)
            if(n<1.or.n>2) then
                call runtime_error('rounding intrinsic needs A and optional KIND',e%line,e%column);return
            end if
            a=e%args(1)
            if(.not.valid_expression(a)) return
            if(a==index) then
                call runtime_error('cyclic rounding intrinsic argument',e%line,e%column);return
            end if
            if(prog%expressions(a)%typ/=ty_real.or. &
               (prog%expressions(a)%real_kind/=4.and.prog%expressions(a)%real_kind/=8).or. &
               e%typ/=ty_integer.or.(e%real_kind/=4.and.e%real_kind/=8).or. &
               e%rank/=prog%expressions(a)%rank.or.e%rank<0.or.e%rank>3.or. &
               e%extent/=prog%expressions(a)%extent.or.any(e%dims/=prog%expressions(a)%dims)) then
                call runtime_error('invalid rounding intrinsic type or shape metadata',e%line,e%column);return
            end if
            k=4
            if(n==2) then
                b=e%args(2)
                if(.not.valid_expression(b)) return
                if(b==index.or.prog%expressions(b)%typ/=ty_integer.or.prog%expressions(b)%rank/=0) then
                    call runtime_error('rounding KIND must be scalar INTEGER',e%line,e%column);return
                end if
                if(.not.safe_location_kind(b,0,.false.)) then
                    call runtime_error('rounding KIND must be constant',e%line,e%column);return
                end if
                kind_value=evaluate(b,0)
                if(diag%code/=0) return
                if(kind_value%tag/=ty_integer.or.(kind_value%i/=4_int64.and.kind_value%i/=8_int64)) then
                    call runtime_error('rounding supports INTEGER kinds 4 and 8',e%line,e%column);return
                end if
                k=int(kind_value%i)
            end if
            if(e%real_kind/=k) call runtime_error('rounding result kind differs',e%line,e%column)
            end associate
        end subroutine
        logical function absent_character_search_back(index) result(absent)
            integer,intent(in)::index
            integer::s
            absent=.false.
            if(.not.valid_expression(index)) return
            associate(e=>prog%expressions(index))
            if(e%kind/=ex_variable.or.e%parenthesized) return
            s=e%symbol
            if(.not.valid_symbol(s,allow_absent=.true.)) return
            if(prog%symbols(s)%scope/=scope.or..not.prog%symbols(s)%is_dummy.or. &
               .not.prog%symbols(s)%is_optional) return
            ! Character search intrinsics have no declared dummy symbol. OPTIONAL LOGICAL
            ! scalars/arrays may be absent; their binding remains validated.
            if(e%typ/=ty_logical.or.e%rank/=prog%symbols(s)%rank.or.e%real_kind/=4.or. &
               prog%symbols(s)%typ/=ty_logical.or.prog%symbols(s)%real_kind/=4) then
                call runtime_error('invalid absent Character search BACK descriptor',e%line,e%column);return
            end if
            if(.not.valid_optional_declaration(s)) return
            if((e%rank==0.and.(e%extent/=0.or.any(e%dims/=0))).or. &
               (e%rank>0.and.e%extent/=-1_int64).or. &
               (e%rank>=2.and.any(e%dims/=-1_int64))) then
                call runtime_error('invalid absent Character search BACK shape descriptor',e%line,e%column);return
            end if
            absent=.not.dummy_present(s)
            end associate
        end function
        recursive subroutine validate_character_intrinsic(index)
            integer,intent(in)::index
            integer::n,j,a,last_data,kind_arg,wanted_type,wanted_kind,r
            integer(int64)::extent,dims(3)
            type(value_t)::kv
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing character intrinsic arguments',e%line,e%column);return
            end if
            n=size(e%args);kind_arg=0;last_data=n;wanted_type=ty_integer;wanted_kind=4
            if(is_character_search_intrinsic(e%op)) then
                if(n<2.or.n>4.or.e%intrinsic_mask<3.or.e%intrinsic_mask>15) then
                    call runtime_error('invalid character search arguments',e%line,e%column);return
                end if
                if(iand(e%intrinsic_mask,3)/=3.or.popcnt(e%intrinsic_mask)/=n) then
                    call runtime_error('invalid character search slots',e%line,e%column);return
                end if
                if(btest(e%intrinsic_mask,3)) then
                    kind_arg=e%args(n);last_data=n-1
                end if
            else if(e%op=='len_trim') then
                if(n<1.or.n>2.or.e%intrinsic_mask/=0) then
                    call runtime_error('invalid LEN_TRIM arguments',e%line,e%column);return
                end if
                if(n==2) kind_arg=e%args(2)
                last_data=1
            else
                wanted_type=ty_character
                if(n/=1.or.e%intrinsic_mask/=0) then
                    call runtime_error('invalid ADJUSTL/ADJUSTR arguments',e%line,e%column);return
                end if
            end if
            r=0;extent=0_int64;dims=0_int64
            do j=1,n
                a=e%args(j)
                if(.not.valid_expression(a)) return
                if(a==index) then
                    call runtime_error('cyclic character intrinsic argument',e%line,e%column);return
                end if
                if(j>last_data) cycle
                if(is_character_search_intrinsic(e%op).and.j==3) then
                    if(prog%expressions(a)%typ/=ty_logical.or.prog%expressions(a)%real_kind/=4) then
                        call runtime_error('Character search BACK must be default LOGICAL',e%line,e%column);return
                    end if
                else if(prog%expressions(a)%typ/=ty_character.or.prog%expressions(a)%real_kind/=4) then
                    call runtime_error('character intrinsic requires default CHARACTER',e%line,e%column);return
                end if
                if(prog%expressions(a)%rank<0.or.prog%expressions(a)%rank>3) then
                    call runtime_error('invalid character intrinsic argument rank',e%line,e%column);return
                end if
                if(prog%expressions(a)%rank==0) cycle
                if(r==0) then
                    r=prog%expressions(a)%rank;extent=prog%expressions(a)%extent;dims=prog%expressions(a)%dims
                else
                    if(r/=prog%expressions(a)%rank) then
                        call runtime_error('character intrinsic ranks do not conform',e%line,e%column);return
                    end if
                    if(extent>=0.and.prog%expressions(a)%extent>=0.and.extent/=prog%expressions(a)%extent) then
                        call runtime_error('character intrinsic extents do not conform',e%line,e%column);return
                    end if
                    if(extent<0.or.prog%expressions(a)%extent<0) extent=-1
                    if(r==2) then
                        if(any(dims>=0.and.prog%expressions(a)%dims>=0.and.dims/=prog%expressions(a)%dims)) then
                            call runtime_error('character intrinsic shapes do not conform',e%line,e%column);return
                        end if
                        where(dims<0.or.prog%expressions(a)%dims<0) dims=-1
                    end if
                end if
            end do
            if(kind_arg/=0) then
                if(prog%expressions(kind_arg)%typ/=ty_integer.or.prog%expressions(kind_arg)%rank/=0) then
                    call runtime_error('character intrinsic KIND must be scalar INTEGER',e%line,e%column);return
                end if
                if(.not.safe_location_kind(kind_arg,0,.false.)) then
                    call runtime_error('character intrinsic KIND must be constant',e%line,e%column);return
                end if
                kv=evaluate(kind_arg,0)
                if(diag%code/=0) return
                if(kv%tag/=ty_integer.or.(kv%i/=4.and.kv%i/=8)) then
                    call runtime_error('character intrinsic supports INTEGER kinds 4 and 8',e%line,e%column);return
                end if
                wanted_kind=int(kv%i)
            end if
            if(e%typ/=wanted_type.or.e%real_kind/=wanted_kind.or.e%rank/=r.or.e%extent/=extent.or.any(e%dims/=dims)) then
                call runtime_error('character intrinsic result type/kind/shape differs',e%line,e%column);return
            end if
            if(wanted_type==ty_character) then
                if(e%character_len/=prog%expressions(e%args(1))%character_len) &
                    call runtime_error('character intrinsic result length differs',e%line,e%column)
            end if
            end associate
        end subroutine
        recursive subroutine validate_character_code(index)
            integer,intent(in)::index
            integer::a,b,n
            type(value_t)::kind_value
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing CHAR/ACHAR arguments',e%line,e%column);return
            end if
            n=size(e%args)
            if(n<1.or.n>2) then
                call runtime_error('CHAR/ACHAR require I and optional KIND',e%line,e%column);return
            end if
            a=e%args(1)
            if(.not.valid_expression(a)) return
            if(a==index) then
                call runtime_error('cyclic CHAR/ACHAR argument',e%line,e%column);return
            end if
            if(prog%expressions(a)%typ/=ty_integer.or. &
               (prog%expressions(a)%real_kind/=4.and.prog%expressions(a)%real_kind/=8).or. &
               e%typ/=ty_character.or.e%real_kind/=4.or.e%character_len/=1.or. &
               e%rank/=prog%expressions(a)%rank.or.e%rank<0.or.e%rank>3.or. &
               e%extent/=prog%expressions(a)%extent.or.any(e%dims/=prog%expressions(a)%dims)) then
                call runtime_error('invalid CHAR/ACHAR type, length or shape metadata',e%line,e%column);return
            end if
            if(n==2) then
                b=e%args(2)
                if(.not.valid_expression(b)) return
                if(b==index.or.prog%expressions(b)%typ/=ty_integer.or.prog%expressions(b)%rank/=0) then
                    call runtime_error('CHAR/ACHAR KIND must be scalar INTEGER',e%line,e%column);return
                end if
                if(.not.safe_location_kind(b,0,.false.)) then
                    call runtime_error('CHAR/ACHAR KIND must be constant',e%line,e%column);return
                end if
                kind_value=evaluate(b,0)
                if(diag%code/=0) return
                if(kind_value%tag/=ty_integer.or.kind_value%i/=1_int64) then
                    call runtime_error('CHAR/ACHAR support default CHARACTER kind 1 only',e%line,e%column);return
                end if
            end if
            end associate
        end subroutine
        ! PACK changes shape based on MASK values. Validate metadata even for
        ! empty results and KIND inquiries, without evaluating data for KIND.
        recursive logical function safe_location_kind(root,depth,inquiry) result(ok)
            integer,intent(in)::root,depth
            logical,intent(in)::inquiry
            integer::j,s,b,children(10),n
            logical::child_inquiry
            ok=.false.
            if(depth>512.or..not.valid_expression(root)) return
            associate(e=>prog%expressions(root))
            call consume(e%line,e%column)
            if(diag%code/=0) return
            children=0;n=0;child_inquiry=inquiry
            select case(e%kind)
            case(ex_literal)
                ok=.true.;return
            case(ex_variable,ex_element,ex_section,ex_substring)
                s=e%symbol
                if(e%kind==ex_substring.and.s==0) then
                    call validate_substring(root,.true.)
                    if(diag%code/=0) return
                else
                    if(.not.valid_symbol(s,allow_absent=inquiry)) return
                    if(.not.inquiry.and..not.prog%symbols(s)%is_parameter) return
                end if
                if(e%kind/=ex_variable) then
                    n=10;children=[e%left,e%right,e%stride,e%left2,e%right2,e%stride2, &
                        e%left3,e%right3,e%stride3,e%third]
                end if
            case(ex_unary)
                n=1;children(1)=e%left
            case(ex_binary)
                n=2;children(:2)=[e%left,e%right]
            case(ex_call,ex_constructor,ex_user_call)
                if(e%kind==ex_user_call.and..not.inquiry) return
                if(.not.allocated(e%args)) return
                if(e%kind==ex_call.and.(e%op=='kind'.or.e%op=='new_line'.or.is_numeric_model_inquiry(e%op))) child_inquiry=.true.
                do j=1,size(e%args)
                    if(e%args(j)==0.and.e%kind==ex_user_call) cycle
                    if(e%kind==ex_call.and.e%op=='shape'.and.j==1.and..not.child_inquiry) then
                        if(.not.valid_expression(e%args(j))) return
                        if(prog%expressions(e%args(j))%kind==ex_variable) then
                            b=prog%expressions(e%args(j))%symbol
                            if(b<1.or.b>prog%ns) return
                            if(.not.prog%symbols(b)%is_allocatable.and..not.prog%symbols(b)%assumed_shape.and. &
                               .not.prog%symbols(b)%is_automatic.and..not.prog%symbols(b)%is_dummy) then
                                if(.not.safe_location_kind(e%args(j),depth+1,.true.)) return
                                cycle
                            end if
                        end if
                    end if
                    if(.not.safe_location_kind(e%args(j),depth+1,child_inquiry)) return
                end do
            case default
                return
            end select
            do j=1,n
                if(children(j)==0.and.(e%kind==ex_element.or.e%kind==ex_section.or.e%kind==ex_substring)) cycle
                if(.not.safe_location_kind(children(j),depth+1,child_inquiry)) return
            end do
            end associate
            ok=.true.
        end function
        ! Metadata validation is also used for unevaluated KIND inquiries.
        recursive subroutine validate_location_metadata(index)
            integer,intent(in)::index
            integer::a,b,j,slot,r,k,s,off,t
            integer(int64)::extent
            type(value_t)::kind_value
            associate(e=>prog%expressions(index))
            off=merge(1,0,e%op=='findloc')
            if(.not.allocated(e%args)) then
                call runtime_error('missing location intrinsic arguments',e%line,e%column);return
            end if
            if(size(e%args)<1+off.or.size(e%args)>5+off.or.e%intrinsic_mask<1.or.e%intrinsic_mask>2**(5+off)-1) then
                call runtime_error('invalid location intrinsic argument count/slots',e%line,e%column);return
            end if
            if(iand(e%intrinsic_mask,2**(1+off)-1)/=2**(1+off)-1.or.popcnt(e%intrinsic_mask)/=size(e%args)) then
                call runtime_error('invalid location intrinsic argument association',e%line,e%column);return
            end if
            do j=1,size(e%args)
                if(.not.valid_expression(e%args(j))) return
                if(e%args(j)==index) then
                    call runtime_error('cyclic location intrinsic argument',e%line,e%column);return
                end if
            end do
            a=e%args(1);r=prog%expressions(a)%rank;k=prog%expressions(a)%real_kind;t=prog%expressions(a)%typ
            if(r<1.or.r>2.or.(t<ty_integer.or.t>merge(ty_character,ty_real,off==1)).or. &
               (k/=4.and.k/=8).or.(t>=ty_logical.and.k/=4)) then
                call runtime_error('location intrinsic ARRAY must be a supported rank-one/rank-two array',e%line,e%column);return
            end if
            if(off==1) then
                b=e%args(2);k=prog%expressions(b)%real_kind
                if(prog%expressions(b)%rank/=0.or.prog%expressions(b)%typ/=t.or. &
                   (k/=4.and.k/=8).or.(t>=ty_logical.and.k/=4)) then
                    call runtime_error('FINDLOC VALUE must be a supported scalar matching ARRAY type',e%line,e%column);return
                end if
            end if
            extent=int(r,int64)
            if(btest(e%intrinsic_mask,1+off)) then
                r=r-1;extent=0_int64
                if(r>0) extent=-1_int64
            else
                r=1
            end if
            k=4;j=1+off
            do slot=2,5
                if(.not.btest(e%intrinsic_mask,slot-1+off)) cycle
                j=j+1;b=e%args(j)
                if(prog%expressions(b)%kind==ex_variable.and..not.prog%expressions(b)%parenthesized) then
                    s=prog%expressions(b)%symbol
                    if(.not.valid_symbol(s)) return
                    if(prog%symbols(s)%is_optional) then
                        call runtime_error('location intrinsic direct OPTIONAL argument unsupported',e%line,e%column);return
                    end if
                end if
                select case(slot)
                case(2,4)
                    if(prog%expressions(b)%typ/=ty_integer.or.prog%expressions(b)%rank/=0.or. &
                       (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8)) then
                        call runtime_error('location intrinsic DIM/KIND must be scalar INTEGER',e%line,e%column);return
                    end if
                    if(slot==4) then
                        k=e%real_kind
                        if(.not.safe_location_kind(b,0,.false.)) then
                            call runtime_error('location intrinsic KIND must be an acyclic constant expression',e%line,e%column);return
                        end if
                        kind_value=evaluate(b,0)
                        if(diag%code/=0) return
                        if(kind_value%tag/=ty_integer.or.kind_value%i/=k) then
                            call runtime_error('location intrinsic KIND value differs',e%line,e%column);return
                        end if
                    end if
                case(3,5)
                    if(prog%expressions(b)%typ/=ty_logical.or.prog%expressions(b)%real_kind/=4.or. &
                       prog%expressions(b)%rank<0.or.prog%expressions(b)%rank>2) then
                        call runtime_error('location intrinsic MASK/BACK must be LOGICAL',e%line,e%column);return
                    end if
                    if(slot==5.and.prog%expressions(b)%rank/=0) then
                        call runtime_error('location intrinsic BACK must be scalar',e%line,e%column);return
                    end if
                    if(slot==3.and.prog%expressions(b)%rank>0) then
                        if(prog%expressions(b)%rank/=prog%expressions(a)%rank) then
                            call runtime_error('location intrinsic MASK rank differs',e%line,e%column);return
                        end if
                    end if
                end select
            end do
            if(e%typ/=ty_integer.or.e%real_kind/=k.or.(k/=4.and.k/=8).or.e%rank/=r.or. &
               e%extent/=extent.or.any(e%dims/=0).or.e%character_len/=-1) then
                call runtime_error('location intrinsic result metadata differs',e%line,e%column);return
            end if
            end associate
        end subroutine
        recursive subroutine prepare_location(index,depth)
            integer,intent(in)::index,depth
            integer::a,m,j,k,slot,dim,ar,n,result_size,groups,group,coordinate,status,best_position
            integer::slots(6),off
            type(value_t)::v,q,wanted
            type(value_t),allocatable::best(:)
            logical,allocatable::found(:)
            logical::selected,back,better
            call validate_location_metadata(index)
            if(diag%code/=0) return
            associate(e=>prog%expressions(index))
            off=merge(1,0,e%op=='findloc')
            slots=0;j=0
            do slot=1,5+off
                if(.not.btest(e%intrinsic_mask,slot-1)) cycle
                j=j+1;slots(slot)=e%args(j)
                call prepare_expression(slots(slot),depth+1)
                if(diag%code/=0) return
            end do
            if(off==1) then
                j=slots(2);slots(2:5)=slots(3:6);slots(6)=j
                wanted=evaluate(slots(6),depth+1)
                if(diag%code/=0) return
                if(wanted%tag/=prog%expressions(slots(1))%typ.or. &
                   wanted%real_kind/=prog%expressions(slots(6))%real_kind) then
                    call runtime_error('FINDLOC VALUE differs from its metadata',e%line,e%column);return
                end if
            end if
            a=slots(1);m=slots(3);ar=prog%expressions(a)%rank;dim=0;back=.false.
            if(slots(2)/=0) then
                v=evaluate(slots(2),depth+1)
                if(diag%code/=0) return
                if(v%tag/=ty_integer.or.v%i<1.or.v%i>ar) then
                    call runtime_error('location intrinsic DIM outside array rank',e%line,e%column);return
                end if
                dim=int(v%i)
            end if
            if(slots(4)/=0) then
                v=evaluate(slots(4),depth+1)
                if(diag%code/=0) return
                if(v%tag/=ty_integer.or.v%i/=e%real_kind) then
                    call runtime_error('location intrinsic KIND value differs',e%line,e%column);return
                end if
            end if
            if(slots(5)/=0) then
                v=evaluate(slots(5),depth+1)
                if(diag%code/=0) return
                if(v%tag/=ty_logical.or.v%real_kind/=4) then
                    call runtime_error('location intrinsic BACK value differs',e%line,e%column);return
                end if
                back=v%l
            end if
            selected=.true.
            if(m/=0) then
                if(prog%expressions(m)%rank>0) then
                    if(any(shape_dims(:,a)/=shape_dims(:,m))) then
                        call runtime_error('location intrinsic MASK shape does not conform',e%line,e%column);return
                    end if
                else
                    v=evaluate(m,depth+1)
                    if(diag%code/=0) return
                    if(v%tag/=ty_logical.or.v%real_kind/=4) then
                        call runtime_error('location intrinsic MASK value differs',e%line,e%column);return
                    end if
                    selected=v%l
                end if
            end if
            if(shape_extent(a)<0.or.shape_extent(a)>max_array_elements) then
                call runtime_error('location intrinsic ARRAY element limit exceeded',e%line,e%column);return
            end if
            n=int(shape_extent(a));groups=1;result_size=ar
            if(dim/=0) then
                result_size=1
                if(ar==2) result_size=int(shape_dims(3-dim,a))
                groups=result_size
            end if
            if(result_size>max_array_elements-cached_elements) then
                call runtime_error('location intrinsic temporary element limit exceeded',e%line,e%column);return
            end if
            cached_elements=cached_elements+result_size
            allocate(expression_cache(index)%values(result_size),best(merge(groups,0,off==0)),found(groups),stat=status)
            if(status/=0) then
                call runtime_error('location intrinsic result allocation failed',e%line,e%column);return
            end if
            expression_cache(index)%values=value_t(tag=ty_integer,real_kind=e%real_kind)
            found=.false.;best_position=0
            shape_extent(index)=0_int64;shape_dims(:,index)=[0_int64,1_int64,1_int64]
            if(e%rank>0) then
                shape_extent(index)=int(result_size,int64);shape_dims(:,index)=[int(result_size,int64),1_int64,1_int64]
            end if
            ! Freeze each selected value and each MASK element exactly once.
            ! Output locations refer to the expression's element order, not bounds.
            do k=1,n
                call consume(e%line,e%column)
                if(diag%code/=0) return
                if(m/=0) then
                    if(prog%expressions(m)%rank>0) then
                        q=evaluate(m,depth+1,k)
                        if(diag%code/=0) return
                        if(q%tag/=ty_logical.or.q%real_kind/=4) then
                            call runtime_error('location intrinsic MASK value differs',e%line,e%column);return
                        end if
                        selected=q%l
                    end if
                end if
                if(.not.selected) cycle
                group=1;coordinate=k
                if(ar==2.and.dim==1) then
                    group=(k-1)/int(shape_dims(1,a))+1;coordinate=mod(k-1,int(shape_dims(1,a)))+1
                else if(ar==2.and.dim==2) then
                    group=mod(k-1,int(shape_dims(1,a)))+1;coordinate=(k-1)/int(shape_dims(1,a))+1
                end if
                v=evaluate(a,depth+1,k)
                if(diag%code/=0) return
                if(v%tag/=prog%expressions(a)%typ.or.v%real_kind/=prog%expressions(a)%real_kind) then
                    call runtime_error('location intrinsic ARRAY value differs',e%line,e%column);return
                end if
                if(off==1) then
                    select case(v%tag)
                    case(ty_integer);better=v%i==wanted%i
                    case(ty_real);better=v%r==wanted%r
                    case(ty_logical);better=v%l.eqv.wanted%l
                    case(ty_character)
                        if(.not.allocated(v%s).or..not.allocated(wanted%s)) then
                            call runtime_error('FINDLOC CHARACTER value missing',e%line,e%column);return
                        end if
                        better=v%s==wanted%s
                    case default
                        call runtime_error('invalid FINDLOC comparison type',e%line,e%column);return
                    end select
                    better=better.and.(back.or..not.found(group))
                else
                    better=.not.found(group)
                    if(found(group)) then
                        if(v%tag==ty_integer) then
                            if(e%op=='minloc') better=v%i<best(group)%i
                            if(e%op=='maxloc') better=v%i>best(group)%i
                            if(back.and.v%i==best(group)%i) better=.true.
                        else
                            if(e%op=='minloc') better=v%r<best(group)%r
                            if(e%op=='maxloc') better=v%r>best(group)%r
                            if(back.and.v%r==best(group)%r) better=.true.
                        end if
                    end if
                end if
                if(.not.better) cycle
                ! FINDLOC keeps only coordinates, not a duplicate of selected CHARACTER data.
                if(off==0) best(group)=v
                found(group)=.true.
                if(dim==0) then
                    best_position=k
                else
                    expression_cache(index)%values(group)%i=int(coordinate,int64)
                end if
            end do
            if(dim==0.and.best_position>0) then
                expression_cache(index)%values(1)%i=int(best_position,int64)
                if(ar==2) then
                    expression_cache(index)%values(1)%i=mod(int(best_position-1,int64),shape_dims(1,a))+1
                    expression_cache(index)%values(2)%i=int(best_position-1,int64)/shape_dims(1,a)+1
                end if
            end if
            end associate
        end subroutine
        recursive subroutine validate_eoshift(index,walk_tree)
            integer,intent(in)::index
            logical,optional,intent(in)::walk_tree
            integer::a,b,n,j,t,k,d
            integer,allocatable::marks(:)
            if(.not.valid_expression(index))return
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing EOSHIFT arguments',e%line,e%column);return
            end if
            n=size(e%args)
            if(n<2.or.n>4.or.e%intrinsic_mask<3.or.e%intrinsic_mask>15) then
                call runtime_error('invalid EOSHIFT count/slots',e%line,e%column);return
            end if
            if(iand(e%intrinsic_mask,3)/=3.or.popcnt(e%intrinsic_mask)/=n.or. &
               e%symbol/=0.or.e%left/=0.or.e%right/=0.or.e%stride/=0.or. &
               e%left2/=0.or.e%right2/=0.or.e%stride2/=0.or.e%left3/=0.or.e%right3/=0.or. &
               e%stride3/=0.or.e%third/=0.or.e%length_expr/=0.or.e%constructor_kind_expr/=0.or. &
               e%generic_id/=0.or.e%bound_type/=0.or.e%bound_binding/=0.or.e%constructor_owner/=0.or. &
               any(e%triplet.neqv.[.true.,.false.,.false.])) then
                call runtime_error('invalid EOSHIFT slots or unused metadata',e%line,e%column);return
            end if
            do j=1,n
                if(.not.valid_expression(e%args(j)))return
                associate(arg=>prog%expressions(e%args(j)))
                if(arg%rank<2.and.any(arg%dims/=0))then
                    call runtime_error('invalid EOSHIFT scalar/vector dimension cache',e%line,e%column);return
                end if
                if(arg%typ/=ty_character.and.arg%character_len/=-1)then
                    call runtime_error('unexpected EOSHIFT operand CHARACTER length',e%line,e%column);return
                end if
                end associate
                if(e%args(j)==index) then
                    call runtime_error('cyclic EOSHIFT operand',e%line,e%column);return
                end if
            end do
            a=e%args(1);b=e%args(2);t=prog%expressions(a)%typ;k=prog%expressions(a)%real_kind
            if(prog%expressions(a)%rank<1.or.prog%expressions(a)%rank>2.or. &
               t<ty_integer.or.t>ty_character.or.(k/=4.and.k/=8).or. &
               ((t==ty_character.or.t==ty_logical).and.k/=4)) then
                call runtime_error('invalid EOSHIFT ARRAY type/kind/rank',e%line,e%column);return
            end if
            if(prog%expressions(b)%typ/=ty_integer.or. &
               (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8).or. &
               prog%expressions(b)%rank<0.or.prog%expressions(b)%rank>prog%expressions(a)%rank-1) then
                call runtime_error('invalid EOSHIFT SHIFT type/kind/rank',e%line,e%column);return
            end if
            if(btest(e%intrinsic_mask,2)) then
                b=e%args(3)
                if(prog%expressions(b)%typ/=t.or.prog%expressions(b)%real_kind/=k.or. &
                   prog%expressions(b)%rank<0.or.prog%expressions(b)%rank>prog%expressions(a)%rank-1.or. &
                   prog%expressions(b)%character_len/=prog%expressions(a)%character_len) then
                    call runtime_error('EOSHIFT BOUNDARY type/kind/length/rank differs',e%line,e%column);return
                end if
            end if
            d=1
            if(btest(e%intrinsic_mask,3)) then
                b=e%args(n);d=0
                if(prog%expressions(b)%typ/=ty_integer.or.prog%expressions(b)%rank/=0.or. &
                   (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8)) then
                    call runtime_error('invalid EOSHIFT DIM type/kind/rank',e%line,e%column);return
                end if
                if(prog%expressions(b)%kind==ex_variable.and..not.prog%expressions(b)%parenthesized) then
                    j=prog%expressions(b)%symbol
                    if(.not.valid_symbol(j,allow_absent=.true.))return
                    if(prog%symbols(j)%is_optional) then
                        call runtime_error('EOSHIFT direct OPTIONAL DIM unsupported',e%line,e%column);return
                    end if
                else if(prog%expressions(b)%kind==ex_literal) then
                    if(prog%expressions(b)%value%tag/=ty_integer.or.prog%expressions(b)%value%i<1.or. &
                       prog%expressions(b)%value%i>prog%expressions(a)%rank) then
                        call runtime_error('EOSHIFT DIM is outside ARRAY rank',e%line,e%column);return
                    end if
                    d=int(prog%expressions(b)%value%i)
                end if
            end if
            if(d>0) then
                do j=2,2+merge(1,0,btest(e%intrinsic_mask,2))
                    b=e%args(j)
                    if(prog%expressions(b)%rank/=1)cycle
                    if(prog%expressions(a)%dims(3-d)>=0.and.prog%expressions(b)%extent>=0.and. &
                       prog%expressions(a)%dims(3-d)/=prog%expressions(b)%extent) then
                        call runtime_error('EOSHIFT SHIFT/BOUNDARY shape differs',e%line,e%column);return
                    end if
                end do
            end if
            if(e%typ/=t.or.e%real_kind/=k.or.e%rank/=prog%expressions(a)%rank.or. &
               e%extent/=prog%expressions(a)%extent.or.any(e%dims/=prog%expressions(a)%dims).or. &
               e%character_len/=prog%expressions(a)%character_len) then
                call runtime_error('EOSHIFT result metadata differs from ARRAY',e%line,e%column);return
            end if
            if(t==ty_character) then
                if(e%character_len<0.or.e%character_len>65536) then
                    call runtime_error('EOSHIFT requires fixed CHARACTER length up to 65536',e%line,e%column);return
                end if
            else if(e%character_len/=-1) then
                call runtime_error('unexpected EOSHIFT noncharacter length',e%line,e%column);return
            end if
            end associate
            allocate(marks(prog%ne),source=0)
            call validate_eoshift_character_tree(index,marks,0)
            if(diag%code/=0)return
            if(present(walk_tree))then
                if(.not.walk_tree)return
            end if
            marks=0
            call validate_kind_tree(index,marks,0)
        end subroutine
        recursive subroutine prepare_eoshift(index,depth)
            integer,intent(in)::index,depth
            integer::a,b,c,n,j,k,d,nshift,nboundary,status,source,group,bgroup
            integer(int64)::axis,row,col,amount,coordinate,bytes
            integer(int64),allocatable::shifts(:)
            type(value_t),allocatable::boundaries(:)
            type(value_t)::v
            call validate_eoshift(index)
            if(diag%code/=0)return
            associate(e=>prog%expressions(index))
            call consume(e%line,e%column)
            if(diag%code/=0)return
            do j=1,size(e%args)
                call prepare_expression(e%args(j),depth+1)
                if(diag%code/=0)return
            end do
            a=e%args(1);b=e%args(2);c=0;d=1
            if(btest(e%intrinsic_mask,2))c=e%args(3)
            if(btest(e%intrinsic_mask,3)) then
                j=e%args(size(e%args));v=evaluate(j,depth+1)
                if(diag%code/=0)return
                if(v%tag/=ty_integer.or.v%real_kind/=prog%expressions(j)%real_kind.or. &
                   v%i<1.or.v%i>prog%expressions(a)%rank) then
                    call runtime_error('EOSHIFT DIM is outside ARRAY rank',e%line,e%column);return
                end if
                d=int(v%i)
            end if
            do j=2,2+merge(1,0,c/=0)
                k=e%args(j)
                if(prog%expressions(k)%rank/=1)cycle
                if(shape_extent(k)/=shape_dims(3-d,a)) then
                    call runtime_error('EOSHIFT SHIFT/BOUNDARY shape must match ARRAY with DIM removed',e%line,e%column);return
                end if
            end do
            if(shape_extent(a)<0.or.shape_extent(a)>max_array_elements.or. &
               shape_extent(a)>max_array_elements-cached_elements) then
                call runtime_error('EOSHIFT temporary element limit exceeded',e%line,e%column);return
            end if
            n=int(shape_extent(a));axis=shape_dims(d,a);nshift=1;nboundary=1
            if(prog%expressions(b)%rank==1)nshift=int(shape_extent(b))
            if(c/=0)then
                if(prog%expressions(c)%rank==1)nboundary=int(shape_extent(c))
            end if
            if(e%typ==ty_character) then
                bytes=(int(n,int64)+int(nboundary,int64))*int(e%character_len,int64)
                do j=1,prog%ne
                    if(.not.allocated(expression_cache(j)%values))cycle
                    do k=1,size(expression_cache(j)%values)
                        call consume(e%line,e%column)
                        if(diag%code/=0)return
                        if(allocated(expression_cache(j)%values(k)%s))bytes=bytes+len(expression_cache(j)%values(k)%s,kind=int64)
                    end do
                end do
                if(bytes>16777216_int64) then
                    call runtime_error('EOSHIFT CHARACTER temporary byte limit exceeded (16777216)',e%line,e%column);return
                end if
            end if
            allocate(shifts(nshift),boundaries(nboundary),stat=status)
            if(status/=0) then
                call runtime_error('EOSHIFT control storage allocation failed',e%line,e%column);return
            end if
            ! Freeze each control once. Saturate before adding to a position:
            ! even INTEGER(8)'s minimum negative value is a valid end shift.
            do j=1,nshift
                call consume(e%line,e%column)
                if(diag%code/=0)return
                if(prog%expressions(b)%rank==0)then
                    v=evaluate(b,depth+1)
                else
                    v=evaluate(b,depth+1,j)
                end if
                if(diag%code/=0)return
                if(v%tag/=ty_integer.or.v%real_kind/=prog%expressions(b)%real_kind) then
                    call runtime_error('EOSHIFT SHIFT value differs from type/kind',e%line,e%column);return
                end if
                if(.not.check_integer(v%i,e%line,e%column,v%real_kind))return
                shifts(j)=max(-axis,min(axis,v%i))
            end do
            do j=1,nboundary
                call consume(e%line,e%column)
                if(diag%code/=0)return
                v=value_t(tag=e%typ,real_kind=e%real_kind)
                if(e%typ==ty_character)v%s=repeat(' ',e%character_len)
                if(c/=0)then
                    if(prog%expressions(c)%rank==0)then
                        v=evaluate(c,depth+1)
                    else
                        v=evaluate(c,depth+1,j)
                    end if
                    if(diag%code/=0)return
                end if
                if(.not.valid_eoshift_value(v,index))return
                boundaries(j)=v
            end do
            allocate(expression_cache(index)%values(n),stat=status)
            if(status/=0) then
                call runtime_error('EOSHIFT result storage allocation failed',e%line,e%column);return
            end if
            cached_elements=cached_elements+int(n,int64)
            shape_extent(index)=shape_extent(a);shape_dims(:,index)=shape_dims(:,a)
            do j=1,n
                call consume(e%line,e%column)
                if(diag%code/=0)return
                row=modulo(int(j-1,int64),shape_dims(1,a));col=int(j-1,int64)/shape_dims(1,a)
                group=1;bgroup=1
                if(prog%expressions(b)%rank==1)then
                    if(d==1)group=int(col)+1
                    if(d==2)group=int(row)+1
                end if
                if(c/=0)then
                    if(prog%expressions(c)%rank==1)then
                        if(d==1)bgroup=int(col)+1
                        if(d==2)bgroup=int(row)+1
                    end if
                end if
                amount=shifts(group);coordinate=row
                if(d==2)coordinate=col
                coordinate=coordinate+amount
                if(coordinate<0.or.coordinate>=axis)then
                    v=boundaries(bgroup)
                else
                    if(d==1)row=coordinate
                    if(d==2)col=coordinate
                    source=int(row+col*shape_dims(1,a))+1
                    v=evaluate(a,depth+1,source)
                    if(diag%code/=0)return
                    if(.not.valid_eoshift_value(v,index))return
                end if
                expression_cache(index)%values(j)=v
            end do
            end associate
        end subroutine
        logical function valid_eoshift_value(v,index) result(ok)
            type(value_t),intent(in)::v
            integer,intent(in)::index
            ok=.false.
            associate(e=>prog%expressions(index))
            if(v%tag/=e%typ.or.v%real_kind/=e%real_kind)then
                call runtime_error('EOSHIFT value differs from ARRAY type/kind',e%line,e%column);return
            end if
            if(e%typ==ty_character)then
                if(.not.allocated(v%s))then
                    call runtime_error('EOSHIFT CHARACTER value is missing',e%line,e%column);return
                end if
                if(len(v%s)/=e%character_len)then
                    call runtime_error('EOSHIFT CHARACTER value length differs',e%line,e%column);return
                end if
            else if(e%typ==ty_integer)then
                if(.not.check_integer(v%i,e%line,e%column,e%real_kind))return
            else if(e%typ==ty_real)then
                if(.not.ieee_is_finite(v%r))then
                    call runtime_error('non-finite EOSHIFT REAL value',e%line,e%column);return
                end if
                if(e%real_kind==4)then
                    if(abs(v%r)>real(huge(0.0_real32),real64))then
                        call runtime_error('EOSHIFT REAL(4) value out of range',e%line,e%column);return
                    end if
                    if(real(real(v%r,real32),real64)/=v%r)then
                        call runtime_error('EOSHIFT REAL(4) value kind differs',e%line,e%column);return
                    end if
                end if
            end if
            end associate
            ok=.true.
        end function
        recursive subroutine validate_eoshift_character_tree(index,marks,depth)
            integer,intent(in)::index,depth
            integer,intent(inout)::marks(:)
            integer::j,s,result,children(10)
            if(diag%code/=0)return
            if(.not.valid_expression(index))return
            if(depth>512.or.marks(index)==1)then
                call runtime_error('cyclic EOSHIFT operand',0,0);return
            end if
            if(marks(index)==2)return
            marks(index)=1
            associate(x=>prog%expressions(index))
            if(x%typ==ty_character)then
                if(x%real_kind/=4.or.x%character_len < -1.or.x%character_len>65536)then
                    call runtime_error('EOSHIFT CHARACTER kind/length metadata differs',x%line,x%column);return
                end if
                if(x%kind==ex_literal)then
                    if(.not.allocated(x%value%s))then
                        call runtime_error('missing EOSHIFT CHARACTER literal',x%line,x%column);return
                    end if
                    if(x%value%real_kind/=4.or.x%character_len/=len(x%value%s))then
                        call runtime_error('EOSHIFT CHARACTER literal cache differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_user_call)then
                    s=x%symbol
                    if(s<1.or.s>prog%np)then
                        call runtime_error('invalid EOSHIFT function reference',x%line,x%column);return
                    end if
                    result=prog%procedures(s)%result_symbol
                    if(result<1.or.result>prog%ns)then
                        call runtime_error('invalid EOSHIFT function result',x%line,x%column);return
                    end if
                    if(prog%symbols(result)%typ/=ty_character.or.prog%symbols(result)%real_kind/=4)then
                        call runtime_error('EOSHIFT function result kind differs',x%line,x%column);return
                    end if
                else if(x%kind==ex_variable.or.x%kind==ex_element.or.x%kind==ex_section)then
                    s=x%symbol
                    if(.not.valid_symbol(s,allow_absent=.true.))return
                    if(prog%symbols(s)%real_kind/=4.or.prog%symbols(s)%character_len/=x%character_len)then
                        call runtime_error('EOSHIFT CHARACTER declaration kind differs',x%line,x%column);return
                    end if
                end if
            end if
            children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3,x%third]
            do j=1,size(children)
                if(children(j)==0)cycle
                call validate_eoshift_character_tree(children(j),marks,depth+1)
                if(diag%code/=0)return
            end do
            if(allocated(x%args))then
                do j=1,size(x%args)
                    if(x%args(j)==0.and.x%kind==ex_user_call)cycle
                    call validate_eoshift_character_tree(x%args(j),marks,depth+1)
                    if(diag%code/=0)return
                end do
            end if
            end associate
            marks(index)=2
        end subroutine
        subroutine validate_cshift(index)
            integer,intent(in)::index
            integer::a,b,n,j,t,k
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing CSHIFT arguments',e%line,e%column);return
            end if
            n=size(e%args)
            if(n<2.or.n>3) then
                call runtime_error('invalid CSHIFT count/slots',e%line,e%column);return
            end if
            if(e%intrinsic_mask/=2**n-1) then
                call runtime_error('invalid CSHIFT count/slots',e%line,e%column);return
            end if
            do j=1,n
                if(.not.valid_expression(e%args(j))) return
                if(e%args(j)==index) then
                    call runtime_error('cyclic CSHIFT argument',e%line,e%column);return
                end if
            end do
            a=e%args(1);b=e%args(2);t=prog%expressions(a)%typ;k=prog%expressions(a)%real_kind
            if(prog%expressions(a)%rank<1.or.prog%expressions(a)%rank>2.or. &
               t<ty_integer.or.t>ty_character.or.(k/=4.and.k/=8).or. &
               ((t==ty_logical.or.t==ty_character).and.k/=4)) then
                call runtime_error('invalid CSHIFT ARRAY type/kind/rank',e%line,e%column);return
            end if
            if(prog%expressions(b)%typ/=ty_integer.or. &
               (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8).or. &
               prog%expressions(b)%rank<0.or.prog%expressions(b)%rank>prog%expressions(a)%rank-1) then
                call runtime_error('invalid CSHIFT SHIFT type/kind/rank',e%line,e%column);return
            end if
            if(n==3) then
                b=e%args(3)
                if(prog%expressions(b)%typ/=ty_integer.or.prog%expressions(b)%rank/=0.or. &
                   (prog%expressions(b)%real_kind/=4.and.prog%expressions(b)%real_kind/=8)) then
                    call runtime_error('invalid CSHIFT DIM type/kind/rank',e%line,e%column);return
                end if
                if(prog%expressions(b)%kind==ex_variable.and..not.prog%expressions(b)%parenthesized) then
                    j=prog%expressions(b)%symbol
                    if(.not.valid_symbol(j,allow_absent=.true.)) return
                    if(prog%symbols(j)%is_optional) then
                        call runtime_error('CSHIFT direct OPTIONAL DIM unsupported',e%line,e%column);return
                    end if
                end if
            end if
            if(e%typ/=t.or.e%real_kind/=k.or.e%rank/=prog%expressions(a)%rank.or. &
               e%extent/=prog%expressions(a)%extent.or.any(e%dims/=prog%expressions(a)%dims)) then
                call runtime_error('CSHIFT result metadata differs from ARRAY',e%line,e%column);return
            end if
            if(t==ty_character) then
                if(e%character_len<0.or.e%character_len>65536.or.e%character_len/=prog%expressions(a)%character_len) then
                    call runtime_error('CSHIFT requires matching fixed CHARACTER length',e%line,e%column);return
                end if
            end if
            end associate
        end subroutine
        recursive subroutine prepare_cshift(index,depth)
            integer,intent(in)::index,depth
            integer::a,b,n,j,k,d,nshift,status,source,group
            integer(int64)::axis,row,col,amount,bytes
            integer(int64),allocatable::shifts(:)
            type(value_t)::v
            call validate_cshift(index)
            if(diag%code/=0) return
            associate(e=>prog%expressions(index))
            call consume(e%line,e%column)
            if(diag%code/=0) return
            do j=1,size(e%args)
                call prepare_expression(e%args(j),depth+1)
                if(diag%code/=0) return
            end do
            a=e%args(1);b=e%args(2);d=1
            if(size(e%args)==3) then
                v=evaluate(e%args(3),depth+1)
                if(diag%code/=0) return
                if(v%tag/=ty_integer.or.v%real_kind/=prog%expressions(e%args(3))%real_kind.or. &
                   v%i<1.or.v%i>prog%expressions(a)%rank) then
                    call runtime_error('CSHIFT DIM is outside ARRAY rank',e%line,e%column);return
                end if
                d=int(v%i)
            end if
            if(prog%expressions(b)%rank==1) then
                if(shape_extent(b)/=shape_dims(3-d,a)) then
                    call runtime_error('CSHIFT SHIFT shape must match ARRAY with DIM removed',e%line,e%column);return
                end if
            end if
            if(shape_extent(a)<0.or.shape_extent(a)>max_array_elements.or. &
               shape_extent(a)>max_array_elements-cached_elements) then
                call runtime_error('CSHIFT temporary element limit exceeded',e%line,e%column);return
            end if
            n=int(shape_extent(a));axis=shape_dims(d,a)
            nshift=1
            if(prog%expressions(b)%rank==1) nshift=int(shape_extent(b))
            allocate(shifts(nshift),stat=status)
            if(status/=0) then
                call runtime_error('CSHIFT shift storage allocation failed',e%line,e%column);return
            end if
            ! Freeze each shift once. Reduce before addition, never negate:
            ! INTEGER(8)'s minimum negative value is a valid shift amount.
            do j=1,nshift
                call consume(e%line,e%column)
                if(diag%code/=0) return
                if(prog%expressions(b)%rank==0) then
                    v=evaluate(b,depth+1)
                else
                    v=evaluate(b,depth+1,j)
                end if
                if(diag%code/=0) return
                if(v%tag/=ty_integer.or.v%real_kind/=prog%expressions(b)%real_kind) then
                    call runtime_error('CSHIFT SHIFT value differs from its type/kind',e%line,e%column);return
                end if
                if(.not.check_integer(v%i,e%line,e%column,v%real_kind)) return
                shifts(j)=0_int64
                if(axis>0) shifts(j)=modulo(v%i,axis)
            end do
            if(e%typ==ty_character) then
                bytes=int(n,int64)*int(e%character_len,int64)
                do j=1,prog%ne
                    if(.not.allocated(expression_cache(j)%values)) cycle
                    do k=1,size(expression_cache(j)%values)
                        call consume(e%line,e%column)
                        if(diag%code/=0) return
                        if(allocated(expression_cache(j)%values(k)%s)) &
                            bytes=bytes+len(expression_cache(j)%values(k)%s,kind=int64)
                    end do
                end do
                if(bytes>16777216_int64) then
                    call runtime_error('CSHIFT CHARACTER temporary byte limit exceeded (16777216)',e%line,e%column);return
                end if
            end if
            allocate(expression_cache(index)%values(n),stat=status)
            if(status/=0) then
                call runtime_error('CSHIFT result storage allocation failed',e%line,e%column);return
            end if
            cached_elements=cached_elements+int(n,int64)
            shape_extent(index)=shape_extent(a);shape_dims(:,index)=shape_dims(:,a)
            do j=1,n
                call consume(e%line,e%column)
                if(diag%code/=0) return
                row=modulo(int(j-1,int64),shape_dims(1,a));col=int(j-1,int64)/shape_dims(1,a)
                group=1
                if(prog%expressions(b)%rank==1) then
                    if(d==1) group=int(col)+1
                    if(d==2) group=int(row)+1
                end if
                amount=shifts(group)
                if(d==1) row=modulo(row+amount,axis)
                if(d==2) col=modulo(col+amount,axis)
                source=int(row+col*shape_dims(1,a))+1
                v=evaluate(a,depth+1,source)
                if(diag%code/=0) return
                if(v%tag/=e%typ.or.v%real_kind/=e%real_kind) then
                    call runtime_error('CSHIFT ARRAY value differs from its type/kind',e%line,e%column);return
                end if
                if(e%typ==ty_character) then
                    if(.not.allocated(v%s)) then
                        call runtime_error('CSHIFT CHARACTER value is missing',e%line,e%column);return
                    end if
                    if(len(v%s)/=e%character_len) then
                        call runtime_error('CSHIFT CHARACTER value length differs',e%line,e%column);return
                    end if
                end if
                expression_cache(index)%values(j)=v
            end do
            end associate
        end subroutine
        subroutine validate_pack_metadata(index)
            integer,intent(in)::index
            integer::a,m,v,j,t,k
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing PACK arguments',e%line,e%column);return
            end if
            if(size(e%args)<2.or.size(e%args)>3) then
                call runtime_error('PACK requires ARRAY, MASK and optional VECTOR',e%line,e%column);return
            end if
            do j=1,size(e%args)
                if(.not.valid_expression(e%args(j))) return
            end do
            a=e%args(1);m=e%args(2);t=prog%expressions(a)%typ;k=prog%expressions(a)%real_kind
            if(prog%expressions(a)%rank<1.or.prog%expressions(a)%rank>2.or.t<ty_integer.or.t>ty_character.or. &
               (k/=4.and.k/=8).or.((t==ty_logical.or.t==ty_character).and.k/=4)) then
                call runtime_error('PACK ARRAY type/kind/rank is invalid',e%line,e%column);return
            end if
            if(prog%expressions(m)%typ/=ty_logical.or.prog%expressions(m)%real_kind/=4.or. &
               prog%expressions(m)%rank<0.or.prog%expressions(m)%rank>2) then
                call runtime_error('PACK MASK must be LOGICAL',e%line,e%column);return
            end if
            if(prog%expressions(m)%rank>0) then
                if(prog%expressions(m)%rank/=prog%expressions(a)%rank) then
                    call runtime_error('PACK MASK rank does not conform',e%line,e%column);return
                end if
            end if
            if(t==ty_character) then
                if(prog%expressions(a)%character_len<0.or.prog%expressions(a)%character_len>65536) then
                    call runtime_error('PACK CHARACTER length is invalid',e%line,e%column);return
                end if
            end if
            if(size(e%args)==3) then
                v=e%args(3)
                if(prog%expressions(v)%rank/=1.or.prog%expressions(v)%typ/=t.or.prog%expressions(v)%real_kind/=k) then
                    call runtime_error('PACK VECTOR type/kind/rank differs from ARRAY',e%line,e%column);return
                end if
                if(t==ty_character.and.prog%expressions(v)%character_len/=prog%expressions(a)%character_len) then
                    call runtime_error('PACK VECTOR and ARRAY CHARACTER lengths must match',e%line,e%column);return
                end if
            end if
            if(e%rank/=1.or.e%typ/=t.or.e%real_kind/=k.or.e%extent/=-1_int64.or.any(e%dims/=0_int64).or. &
               e%character_len/=prog%expressions(a)%character_len) then
                call runtime_error('PACK result metadata differs from ARRAY',e%line,e%column);return
            end if
            end associate
        end subroutine
        recursive subroutine prepare_pack(index,depth)
            integer,intent(in)::index,depth
            integer::a,m,v,j,n,selected,result_size,status
            integer,allocatable::positions(:)
            type(value_t)::value
            logical::scalar_mask
            call validate_pack_metadata(index)
            if(diag%code/=0) return
            associate(e=>prog%expressions(index))
            call consume(e%line,e%column)
            if(diag%code/=0) return
            do j=1,size(e%args)
                call prepare_expression(e%args(j),depth+1)
                if(diag%code/=0) return
            end do
            a=e%args(1);m=e%args(2);v=0
            if(size(e%args)==3) v=e%args(3)
            if(prog%expressions(m)%rank>0) then
                if(any(shape_dims(:,a)/=shape_dims(:,m))) then
                    call runtime_error('PACK MASK shape does not conform',e%line,e%column);return
                end if
            end if
            if(shape_extent(a)<0.or.shape_extent(a)>max_array_elements) then
                call runtime_error('PACK ARRAY element limit exceeded',e%line,e%column);return
            end if
            n=int(shape_extent(a));selected=0
            ! Freeze the mask once. This is linear, supports impure elemental
            ! masks, and prevents a mask from changing between size and values.
            allocate(positions(n),stat=status)
            if(status/=0) then
                call runtime_error('PACK mask storage allocation failed',e%line,e%column);return
            end if
            scalar_mask=.true.
            if(prog%expressions(m)%rank==0) then
                value=evaluate(m,depth+1)
                if(diag%code/=0) return
                if(value%tag/=ty_logical.or.value%real_kind/=4) then
                    call runtime_error('PACK MASK value is not LOGICAL',e%line,e%column);return
                end if
                scalar_mask=value%l
            end if
            do j=1,n
                call consume(e%line,e%column)
                if(diag%code/=0) return
                if(prog%expressions(m)%rank>0) then
                    value=evaluate(m,depth+1,j)
                    if(diag%code/=0) return
                    if(value%tag/=ty_logical.or.value%real_kind/=4) then
                        call runtime_error('PACK MASK value is not LOGICAL',e%line,e%column);return
                    end if
                    scalar_mask=value%l
                end if
                if(.not.scalar_mask) cycle
                selected=selected+1;positions(selected)=j
            end do
            result_size=selected
            if(v/=0) then
                if(shape_extent(v)<selected) then
                    call runtime_error('PACK VECTOR has fewer elements than selected ARRAY',e%line,e%column);return
                end if
                if(shape_extent(v)>max_array_elements) then
                    call runtime_error('PACK VECTOR element limit exceeded',e%line,e%column);return
                end if
                result_size=int(shape_extent(v))
            end if
            if(result_size>max_array_elements-cached_elements) then
                call runtime_error('PACK temporary element limit exceeded',e%line,e%column);return
            end if
            cached_elements=cached_elements+result_size
            allocate(expression_cache(index)%values(result_size),stat=status)
            if(status/=0) then
                call runtime_error('PACK result storage allocation failed',e%line,e%column);return
            end if
            shape_extent(index)=int(result_size,int64)
            shape_dims(:,index)=[int(result_size,int64),1_int64,1_int64]
            do j=1,result_size
                call consume(e%line,e%column)
                if(diag%code/=0) return
                if(j<=selected) then
                    value=evaluate(a,depth+1,positions(j))
                else
                    value=evaluate(v,depth+1,j)
                end if
                if(diag%code/=0) return
                if(value%tag/=e%typ.or.value%real_kind/=e%real_kind) then
                    call runtime_error('PACK element type/kind differs',e%line,e%column);return
                end if
                if(e%typ==ty_character) then
                    if(.not.allocated(value%s)) then
                        call runtime_error('PACK CHARACTER element is missing',e%line,e%column);return
                    end if
                    if(len(value%s)/=e%character_len) then
                        call runtime_error('PACK CHARACTER element length differs',e%line,e%column);return
                    end if
                end if
                expression_cache(index)%values(j)=value
            end do
            end associate
        end subroutine
        subroutine validate_reshape(index)
            integer,intent(in)::index
            integer::n,a,b,j,r,t,k
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing RESHAPE arguments',e%line,e%column);return
            end if
            n=size(e%args)
            if(n<2.or.n>4.or.e%intrinsic_mask<3.or.e%intrinsic_mask>15) then
                call runtime_error('invalid RESHAPE arguments/slots',e%line,e%column);return
            end if
            if(iand(e%intrinsic_mask,3)/=3.or.popcnt(e%intrinsic_mask)/=n) then
                call runtime_error('invalid RESHAPE argument association',e%line,e%column);return
            end if
            do j=1,n
                if(.not.valid_expression(e%args(j))) return
                if(e%args(j)==index) then
                    call runtime_error('cyclic RESHAPE argument',e%line,e%column);return
                end if
            end do
            a=e%args(1);b=e%args(2)
            t=prog%expressions(a)%typ;k=prog%expressions(a)%real_kind
            if(prog%expressions(a)%rank<1.or.prog%expressions(a)%rank>2.or.t<ty_integer.or.t>ty_character.or. &
               (k/=4.and.k/=8).or.((t==ty_logical.or.t==ty_character).and.k/=4)) then
                call runtime_error('invalid RESHAPE SOURCE type/kind/rank',e%line,e%column);return
            end if
            if(prog%expressions(b)%rank/=1.or.prog%expressions(b)%typ/=ty_integer.or. &
               prog%expressions(b)%extent<1.or.prog%expressions(b)%extent>2) then
                call runtime_error('RESHAPE SHAPE requires INTEGER vector of known size 1 or 2',e%line,e%column);return
            end if
            r=int(prog%expressions(b)%extent)
            if(e%rank/=r.or.e%typ/=t.or.e%real_kind/=k.or.e%extent/=-1_int64.or. &
               (r==1.and.any(e%dims/=0)).or.(r==2.and.any(e%dims/=-1_int64))) then
                call runtime_error('invalid RESHAPE result type/kind/rank/shape metadata',e%line,e%column);return
            end if
            if(t==ty_character) then
                if(e%character_len<0.or.e%character_len>65536.or. &
                   e%character_len/=prog%expressions(a)%character_len) then
                    call runtime_error('invalid RESHAPE CHARACTER length',e%line,e%column);return
                end if
            end if
            if(btest(e%intrinsic_mask,2)) then
                b=e%args(3)
                if(prog%expressions(b)%rank<1.or.prog%expressions(b)%rank>2.or. &
                   prog%expressions(b)%typ/=t.or.prog%expressions(b)%real_kind/=k) then
                    call runtime_error('RESHAPE PAD type/kind/rank must match SOURCE',e%line,e%column);return
                end if
                if(t==ty_character.and.prog%expressions(b)%character_len/=e%character_len) then
                    call runtime_error('RESHAPE PAD CHARACTER length must match SOURCE',e%line,e%column);return
                end if
            end if
            if(btest(e%intrinsic_mask,3)) then
                b=e%args(n)
                if(prog%expressions(b)%rank/=1.or.prog%expressions(b)%typ/=ty_integer) then
                    call runtime_error('RESHAPE ORDER must be an INTEGER vector',e%line,e%column);return
                end if
            end if
            do j=3,n
                b=e%args(j)
                if(prog%expressions(b)%kind/=ex_variable.or.prog%expressions(b)%parenthesized) cycle
                a=prog%expressions(b)%symbol
                if(a<1.or.a>prog%ns) then
                    call runtime_error('invalid RESHAPE optional binding',e%line,e%column);return
                end if
                if(prog%symbols(a)%is_optional) then
                    call runtime_error('RESHAPE direct OPTIONAL PAD/ORDER unsupported',e%line,e%column);return
                end if
            end do
            end associate
        end subroutine
        recursive subroutine prepare_reshape(index,depth)
            integer,intent(in)::index,depth
            integer::j,a,b,n,r,first_order,ord
            integer(int64)::extents(3),total
            logical::seen(2)
            type(value_t)::v
            call validate_reshape(index)
            if(diag%code/=0) return
            associate(e=>prog%expressions(index))
            n=size(e%args);r=e%rank
            do j=1,n
                call prepare_expression(e%args(j),depth+1)
                if(diag%code/=0) return
            end do
            a=e%args(1);b=e%args(2)
            if(shape_extent(b)/=r) then
                call runtime_error('RESHAPE SHAPE size differs from result rank',e%line,e%column);return
            end if
            extents=1_int64
            do j=1,r
                v=evaluate(b,depth+1,j)
                if(diag%code/=0) return
                if(v%tag/=ty_integer.or.v%i<0) then
                    call runtime_error('RESHAPE SHAPE extents must be nonnegative INTEGER',e%line,e%column);return
                end if
                if(v%i>max_array_elements) then
                    call runtime_error('RESHAPE extent limit exceeded',e%line,e%column);return
                end if
                extents(j)=v%i
            end do
            ! Never multiply untrusted extents before the division guard. A zero
            ! extent is handled first; no result element or PAD is then read.
            total=0_int64
            if(all(extents>0)) then
                if(extents(1)>int(max_array_elements,int64)/extents(2)) then
                    call runtime_error('RESHAPE result element limit exceeded',e%line,e%column);return
                end if
                total=extents(1)*extents(2)
            end if
            first_order=1
            if(btest(e%intrinsic_mask,3)) then
                b=e%args(n)
                if(shape_extent(b)/=r) then
                    call runtime_error('RESHAPE ORDER size must match result rank',e%line,e%column);return
                end if
                seen=.false.
                do j=1,r
                    v=evaluate(b,depth+1,j)
                    if(diag%code/=0) return
                    if(v%tag/=ty_integer.or.v%i<1.or.v%i>r) then
                        call runtime_error('RESHAPE ORDER must be a permutation of result dimensions',e%line,e%column);return
                    end if
                    ord=int(v%i)
                    if(seen(ord)) then
                        call runtime_error('RESHAPE ORDER must be a permutation of result dimensions',e%line,e%column);return
                    end if
                    seen(ord)=.true.
                    if(j==1) first_order=ord
                end do
            end if
            if(total>shape_extent(a)) then
                if(.not.btest(e%intrinsic_mask,2)) then
                    call runtime_error('RESHAPE SOURCE too small without PAD',e%line,e%column);return
                end if
                if(shape_extent(e%args(3))==0) then
                    call runtime_error('RESHAPE requires nonempty PAD when SOURCE is too small',e%line,e%column);return
                end if
            end if
            shape_dims(:,index)=extents;shape_extent(index)=total
            reduction_dim(index)=first_order
            end associate
        end subroutine
        ! Transformational intrinsics have their own shape rules. Do not merge
        ! their operand shapes as if they were elemental operations. Every
        ! descriptor, DIM and conformance check is charged and frozen before
        ! evaluating values, including when the result has zero elements.
        recursive subroutine validate_shape_intrinsic(index)
            integer,intent(in)::index
            integer::n,a,b,r,k
            type(value_t)::kv
            associate(e=>prog%expressions(index))
            if(.not.allocated(e%args)) then
                call runtime_error('missing SHAPE arguments',e%line,e%column);return
            end if
            n=size(e%args)
            if(n<1.or.n>2.or.e%intrinsic_mask/=0) then
                call runtime_error('invalid SHAPE argument count/slots',e%line,e%column);return
            end if
            a=e%args(1)
            if(.not.valid_expression(a)) return
            if(a==index) then
                call runtime_error('cyclic SHAPE SOURCE',e%line,e%column);return
            end if
            r=prog%expressions(a)%rank;k=4
            if(r<0.or.r>3.or.prog%expressions(a)%typ<ty_integer.or.prog%expressions(a)%typ>ty_character) then
                call runtime_error('invalid SHAPE SOURCE type/rank',e%line,e%column);return
            end if
            if(n==2) then
                b=e%args(2)
                if(.not.valid_expression(b)) return
                if(b==index.or.prog%expressions(b)%typ/=ty_integer.or.prog%expressions(b)%rank/=0) then
                    call runtime_error('SHAPE KIND must be scalar INTEGER',e%line,e%column);return
                end if
                if(.not.safe_location_kind(b,0,.false.)) then
                    call runtime_error('SHAPE KIND must be constant',e%line,e%column);return
                end if
                kv=evaluate(b,0)
                if(diag%code/=0) return
                if(kv%tag/=ty_integer.or.(kv%i/=4.and.kv%i/=8)) then
                    call runtime_error('SHAPE supports INTEGER kinds 4 and 8',e%line,e%column);return
                end if
                k=int(kv%i)
            end if
            if(e%typ/=ty_integer.or.e%real_kind/=k.or.e%rank/=1.or.e%extent/=int(r,int64).or.any(e%dims/=0)) then
                call runtime_error('SHAPE result type/kind/shape differs',e%line,e%column);return
            end if
            end associate
        end subroutine
        recursive subroutine prepare_shape_inquiry(index,depth)
            integer,intent(in)::index,depth
            integer::a,s,r,j
            integer,allocatable::marks(:)
            integer(int64)::dims(3),lo(3),hi(3)
            associate(e=>prog%expressions(index))
            call validate_shape_intrinsic(index)
            if(diag%code/=0) return
            call consume(e%line,e%column)
            a=e%args(1);r=prog%expressions(a)%rank
            allocate(marks(prog%ne),source=0)
            call validate_kind_tree(a,marks,depth+1)
            if(diag%code/=0) return
            dims=1_int64
            if(present(constant_index).and.prog%expressions(a)%kind==ex_variable) then
                s=prog%expressions(a)%symbol
                if(.not.valid_symbol(s)) return
                associate(v=>prog%symbols(s))
                if(v%is_allocatable.or.v%assumed_shape.or.v%is_automatic.or.v%is_dummy) then
                    call runtime_error('SHAPE SOURCE does not have constant declared shape',e%line,e%column);return
                end if
                lo=[v%lower_bound,v%lower_bound2,v%lower_bound3]
                hi=[v%upper_bound,v%upper_bound2,v%upper_bound3]
                ! Bounds in the supported model are default-INTEGER sized;
                ! checking before subtraction prevents malformed-IR overflow.
                if(any(lo(:r)<imin).or.any(lo(:r)>imax).or.any(hi(:r)<imin).or.any(hi(:r)>imax)) then
                    call runtime_error('SHAPE declared bound outside supported INTEGER range',e%line,e%column);return
                end if
                dims(:r)=max(0_int64,hi(:r)-lo(:r)+1_int64)
                if(any(dims(:r)>imax)) then
                    call runtime_error('SHAPE dimension extent exceeds supported INTEGER range',e%line,e%column);return
                end if
                if(r>0) then
                    if(prog%expressions(a)%extent/=shape_size(dims).or.shape_size(dims)>max_array_elements) then
                        call runtime_error('SHAPE SOURCE declared extent differs',e%line,e%column);return
                    end if
                    if(r>=2.and.any(prog%expressions(a)%dims/=dims)) then
                        call runtime_error('SHAPE SOURCE declared dimensions differ',e%line,e%column);return
                    end if
                end if
                end associate
            else if(r>0) then
                call prepare_expression(a,depth+1)
                if(diag%code/=0) return
                dims=shape_dims(:,a)
            else if(prog%expressions(a)%kind==ex_variable) then
                if(.not.valid_symbol(prog%expressions(a)%symbol)) return
            end if
            if(any(dims(:r)<0).or.any(dims(:r)>imax)) then
                call runtime_error('SHAPE SOURCE dimension outside supported INTEGER range',e%line,e%column);return
            end if
            if(allocated(expression_cache(index)%values)) deallocate(expression_cache(index)%values)
            allocate(expression_cache(index)%values(r))
            do j=1,r
                expression_cache(index)%values(j)=value_t(tag=ty_integer,real_kind=e%real_kind,i=dims(j))
            end do
            shape_extent(index)=int(r,int64);shape_dims(:,index)=[int(r,int64),1_int64,1_int64]
            end associate
        end subroutine
        recursive subroutine validate_bounds_inquiry(index,walk_tree)
            integer,intent(in)::index
            logical,optional,intent(in)::walk_tree
            integer::a,b,s,j,r,k
            integer,allocatable::marks(:)
            integer(int64)::lo(3),hi(3),dims(3),extent
            type(value_t)::kv
            if(.not.valid_expression(index))return
            if(.not.valid_bounds_inquiry(prog,index))then
                call runtime_error('invalid LBOUND/UBOUND metadata',prog%expressions(index)%line,prog%expressions(index)%column);return
            end if
            associate(e=>prog%expressions(index))
            do j=1,size(e%args)
                if(.not.valid_expression(e%args(j)))return
            end do
            a=e%args(1);r=prog%expressions(a)%rank;k=4
            if(prog%expressions(a)%kind==ex_variable)then
                s=prog%expressions(a)%symbol
                if(.not.valid_symbol(s,allow_absent=.true.))return
                associate(v=>prog%symbols(s),x=>prog%expressions(a))
                dims=0_int64
                if(v%is_allocatable.or.v%is_pointer.or.v%assumed_shape.or.v%is_automatic)then
                    extent=-1_int64
                    if(r>=2)dims=-1_int64
                else
                    lo=[v%lower_bound,v%lower_bound2,v%lower_bound3]
                    hi=[v%upper_bound,v%upper_bound2,v%upper_bound3]
                    if(any(lo(:r)<imin).or.any(lo(:r)>imax).or.any(hi(:r)<imin).or.any(hi(:r)>imax))then
                        call runtime_error('LBOUND/UBOUND declared bounds outside INTEGER range',e%line,e%column);return
                    end if
                    dims=1_int64;dims(:r)=max(0_int64,hi(:r)-lo(:r)+1_int64)
                    if(any(dims>imax))then
                        call runtime_error('LBOUND/UBOUND declared dimension exceeds INTEGER range',e%line,e%column);return
                    end if
                    extent=shape_size(dims)
                    if(r==1)dims=0_int64
                end if
                if(x%extent/=extent.or.any(x%dims/=dims))then
                    call runtime_error('LBOUND/UBOUND ARRAY shape cache differs',e%line,e%column);return
                end if
                end associate
            end if
            if(btest(e%intrinsic_mask,1))then
                b=e%args(2)
                if(prog%expressions(b)%kind==ex_variable.and..not.prog%expressions(b)%parenthesized)then
                    s=prog%expressions(b)%symbol
                    if(.not.valid_symbol(s,allow_absent=.true.))return
                    if(prog%symbols(s)%is_optional)then
                        call runtime_error('LBOUND/UBOUND DIM must not be an OPTIONAL dummy',e%line,e%column);return
                    end if
                end if
            end if
            if(btest(e%intrinsic_mask,2))then
                b=e%args(size(e%args))
                if(.not.safe_location_kind(b,0,.false.))then
                    call runtime_error('LBOUND/UBOUND KIND must be constant',e%line,e%column);return
                end if
                kv=evaluate(b,0)
                if(diag%code/=0)return
                if(kv%tag/=ty_integer.or.(kv%i/=4.and.kv%i/=8))then
                    call runtime_error('LBOUND/UBOUND supports INTEGER kinds 4 and 8',e%line,e%column);return
                end if
                k=int(kv%i)
            end if
            if(e%real_kind/=k)then
                call runtime_error('LBOUND/UBOUND result KIND differs',e%line,e%column);return
            end if
            end associate
            if(present(walk_tree))then
                if(.not.walk_tree)return
            end if
            allocate(marks(prog%ne),source=0)
            call validate_kind_tree(index,marks,0)
        end subroutine
        recursive subroutine prepare_bounds_inquiry(index,depth)
            integer,intent(in)::index,depth
            integer::a,r,s,j,d,n,dim
            integer(int64)::lo(3),hi(3),dims(3),answer
            logical::whole,declared
            type(value_t)::v
            call validate_bounds_inquiry(index)
            if(diag%code/=0)return
            associate(e=>prog%expressions(index))
            call consume(e%line,e%column)
            if(diag%code/=0)return
            a=e%args(1);r=prog%expressions(a)%rank;d=0
            if(btest(e%intrinsic_mask,1))then
                v=evaluate(e%args(2),depth+1)
                if(diag%code/=0)return
                if(v%tag/=ty_integer.or.v%i<1.or.v%i>r)then
                    call runtime_error('LBOUND/UBOUND DIM outside ARRAY rank',e%line,e%column);return
                end if
                d=int(v%i)
            end if
            lo=1_int64;hi=0_int64;dims=1_int64;whole=.false.;declared=.false.
            if(prog%expressions(a)%kind==ex_variable)then
                s=prog%expressions(a)%symbol
                if(.not.valid_symbol(s))return
                whole=.not.prog%expressions(a)%parenthesized
                associate(x=>prog%symbols(s))
                declared=.not.x%is_allocatable.and..not.x%is_pointer.and..not.x%assumed_shape.and..not.x%is_automatic
                if(declared)then
                    lo=[x%lower_bound,x%lower_bound2,x%lower_bound3]
                    hi=[x%upper_bound,x%upper_bound2,x%upper_bound3]
                    dims(:r)=max(0_int64,hi(:r)-lo(:r)+1_int64)
                end if
                end associate
            end if
            if(present(constant_index).and.declared)then
                ! Explicit declared bounds are independent of element values.
                ! This also works for undefined arrays in constant inquiries.
            else
                call prepare_expression(a,depth+1)
                if(diag%code/=0)return
                dims=shape_dims(:,a)
                if(whole.and..not.declared)then
                    lo=[refs(s)%array%lower_bound,refs(s)%array%lower_bound2,refs(s)%array%lower_bound3]
                    hi=[refs(s)%array%upper_bound,refs(s)%array%upper_bound2,refs(s)%array%upper_bound3]
                end if
            end if
            if(any(dims(:r)<0).or.any(dims(:r)>imax))then
                call runtime_error('LBOUND/UBOUND ARRAY dimensions outside INTEGER range',e%line,e%column);return
            end if
            if(whole)then
                ! A zero-size assumed-shape descriptor at the minimum lower
                ! bound has the safe INTEGER(8) sentinel upper = lower - 1.
                ! Its inquiry result is normalized 1/0, never that sentinel.
                if(any(lo(:r)<imin).or.any(lo(:r)>imax).or.any(hi(:r)>imax).or. &
                   any(hi(:r)<imin.and..not.(hi(:r)==imin-1_int64.and.lo(:r)==imin.and.dims(:r)==0)))then
                    call runtime_error('LBOUND/UBOUND ARRAY bounds outside INTEGER range',e%line,e%column);return
                end if
                if(any(max(0_int64,hi(:r)-lo(:r)+1_int64)/=dims(:r)))then
                    call runtime_error('LBOUND/UBOUND ARRAY descriptor differs',e%line,e%column);return
                end if
            end if
            n=r;if(d/=0)n=1
            if(allocated(expression_cache(index)%values))deallocate(expression_cache(index)%values)
            allocate(expression_cache(index)%values(n))
            do j=1,n
                dim=j;if(d/=0)dim=d
                answer=1_int64
                if(e%op=='ubound')answer=dims(dim)
                if(whole.and.dims(dim)>0)then
                    answer=lo(dim)
                    if(e%op=='ubound')answer=hi(dim)
                end if
                if(.not.check_integer(answer,e%line,e%column,e%real_kind))return
                expression_cache(index)%values(j)=value_t(tag=ty_integer,real_kind=e%real_kind,i=answer)
            end do
            shape_extent(index)=0_int64;shape_dims(:,index)=[0_int64,1_int64,1_int64]
            if(e%rank==1)then
                shape_extent(index)=int(r,int64);shape_dims(:,index)=[int(r,int64),1_int64,1_int64]
            end if
            end associate
        end subroutine
        recursive subroutine validate_matrix_call(index,walk_tree)
            integer,intent(in)::index
            logical,optional,intent(in)::walk_tree
            integer,allocatable::marks(:)
            integer::a,b,s,j,r
            integer(int64)::lo(3),hi(3),dims(3),extent
            if(.not.valid_expression(index))return
            if(.not.valid_matrix_intrinsic(prog,index))then
                call runtime_error('invalid TRANSPOSE/NORM2 metadata',prog%expressions(index)%line,prog%expressions(index)%column);return
            end if
            associate(e=>prog%expressions(index))
            do j=1,size(e%args)
                if(.not.valid_expression(e%args(j)))return
            end do
            a=e%args(1)
            associate(x=>prog%expressions(a))
            if(x%kind==ex_variable)then
                s=x%symbol
                if(.not.valid_symbol(s,allow_absent=.true.))return
                associate(v=>prog%symbols(s))
                r=v%rank
                if(x%typ/=v%typ.or.x%real_kind/=v%real_kind.or.x%rank/=r.or. &
                   x%character_len/=-1.or.x%left/=0.or.x%right/=0.or.x%stride/=0.or. &
                   x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or.x%left3/=0.or.x%right3/=0.or. &
                   x%stride3/=0.or.x%third/=0.or.x%length_expr/=0.or.x%generic_id/=0.or. &
                   x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or. &
                   len_trim(x%op)/=0.or.allocated(x%args).or.any(x%triplet.neqv.[.true.,.false.,.false.]))then
                    call runtime_error('invalid TRANSPOSE/NORM2 ARRAY variable metadata',x%line,x%column);return
                end if
                dims=0_int64
                if(v%is_allocatable.or.v%is_pointer.or.v%assumed_shape.or.v%is_automatic)then
                    extent=-1_int64
                    if(r>=2)dims=-1_int64
                else
                    lo=[v%lower_bound,v%lower_bound2,v%lower_bound3]
                    hi=[v%upper_bound,v%upper_bound2,v%upper_bound3]
                    if(any(lo(:r)<imin).or.any(lo(:r)>imax).or.any(hi(:r)<imin).or.any(hi(:r)>imax))then
                        call runtime_error('invalid TRANSPOSE/NORM2 declared bounds',x%line,x%column);return
                    end if
                    dims=1_int64;dims(:r)=max(0_int64,hi(:r)-lo(:r)+1_int64)
                    if(any(dims>imax))then
                        call runtime_error('invalid TRANSPOSE/NORM2 declared dimensions',x%line,x%column);return
                    end if
                    extent=shape_size(dims)
                    if(r==1)dims=0_int64
                end if
                if(x%extent/=extent.or.any(x%dims/=dims))then
                    call runtime_error('TRANSPOSE/NORM2 ARRAY shape cache differs',x%line,x%column);return
                end if
                end associate
            end if
            end associate
            if(size(e%args)==2)then
                b=e%args(2)
                if(prog%expressions(b)%kind==ex_variable.and..not.prog%expressions(b)%parenthesized)then
                    s=prog%expressions(b)%symbol
                    if(.not.valid_symbol(s,allow_absent=.true.))return
                    if(prog%symbols(s)%is_optional)then
                        call runtime_error('NORM2 direct OPTIONAL DIM unsupported',e%line,e%column);return
                    end if
                end if
            end if
            end associate
            if(present(walk_tree))then
                if(.not.walk_tree)return
            end if
            allocate(marks(prog%ne),source=0)
            call validate_kind_tree(index,marks,0)
        end subroutine
        recursive subroutine prepare_matrix_call(index,depth)
            integer,intent(in)::index,depth
            integer::a,j,d,r,k
            type(value_t)::v
            call validate_matrix_call(index)
            if(diag%code/=0)return
            associate(e=>prog%expressions(index))
            call consume(e%line,e%column)
            if(diag%code/=0)return
            do j=1,size(e%args)
                call prepare_expression(e%args(j),depth+1)
                if(diag%code/=0)return
            end do
            a=e%args(1);r=prog%expressions(a)%rank
            shape_dims(:,index)=[0_int64,1_int64,1_int64];shape_extent(index)=0_int64
            if(e%op=='transpose')then
                shape_dims(:,index)=[shape_dims(2,a),shape_dims(1,a),1_int64]
            else
                d=0
                if(size(e%args)==2)then
                    v=evaluate(e%args(2),depth+1)
                    if(diag%code/=0)return
                    if(v%tag/=ty_integer.or.v%i<1.or.v%i>r)then
                        call runtime_error('NORM2 DIM is outside ARRAY rank',e%line,e%column);return
                    end if
                    d=int(v%i)
                end if
                reduction_dim(index)=d
                if(e%rank>0)then
                    shape_dims(:,index)=1_int64;k=0
                    do j=1,r
                        if(j==d)cycle
                        k=k+1;shape_dims(k,index)=shape_dims(j,a)
                    end do
                end if
            end if
            if(e%rank>0)shape_extent(index)=shape_size(shape_dims(:,index))
            if(any(shape_dims(:,index)<0).or.shape_extent(index)>max_array_elements)then
                call runtime_error('TRANSPOSE/NORM2 result shape exceeds limit',e%line,e%column);return
            end if
            end associate
        end subroutine
        recursive subroutine matrix_intrinsic_value(index,depth,pos,value)
            integer,intent(in)::index,depth,pos
            type(value_t),intent(out)::value
            type(value_t)::x
            integer::a,d,r,j,lin,col
            integer(int64)::coordinates(3),left,k,n,source,rows,columns
            real(real32)::scale4,ssq4,ax4,factor4
            real(real64)::scale8,ssq8,ax8,factor8
            associate(e=>prog%expressions(index))
            lin=e%line;col=e%column;a=e%args(1);r=prog%expressions(a)%rank
            value=value_t(tag=e%typ,real_kind=e%real_kind)
            if(pos<1.or.(e%rank>0.and.int(pos,int64)>shape_extent(index)).or.(e%rank==0.and.pos/=1))then
                call runtime_error('TRANSPOSE/NORM2 result index outside bounds',lin,col);return
            end if
            if(e%op=='transpose')then
                rows=shape_dims(1,a);columns=shape_dims(2,a)
                if(rows<=0.or.columns<=0)then
                    call runtime_error('TRANSPOSE empty result has no element',lin,col);return
                end if
                source=(int(pos,int64)-1)/columns+1+mod(int(pos,int64)-1,columns)*rows
                x=evaluate(a,depth+1,int(source))
                if(diag%code/=0)return
                if(x%tag/=e%typ.or.x%real_kind/=e%real_kind)then
                    call runtime_error('TRANSPOSE element type/kind differs',lin,col);return
                end if
                value=x;return
            end if
            d=reduction_dim(index);coordinates=1_int64
            n=shape_extent(a)
            if(d/=0)then
                n=shape_dims(d,a);left=int(pos,int64)-1
                do j=1,r
                    if(j==d)cycle
                    if(shape_dims(j,a)<=0)then
                        call runtime_error('NORM2 empty result has no element',lin,col);return
                    end if
                    coordinates(j)=mod(left,shape_dims(j,a))+1
                    left=left/shape_dims(j,a)
                end do
            end if
            scale4=0.0_real32;ssq4=1.0_real32;scale8=0.0_real64;ssq8=1.0_real64
            do k=1_int64,n
                call consume(lin,col)
                if(diag%code/=0)return
                source=k
                if(d/=0)then
                    coordinates(d)=k
                    source=coordinates(1)+(coordinates(2)-1)*shape_dims(1,a)+ &
                        (coordinates(3)-1)*shape_dims(1,a)*shape_dims(2,a)
                end if
                x=evaluate(a,depth+1,int(source))
                if(diag%code/=0)return
                if(x%tag/=ty_real.or.x%real_kind/=e%real_kind.or..not.ieee_is_finite(x%r))then
                    call runtime_error('NORM2 requires finite REAL values of the declared kind',lin,col);return
                end if
                if(e%real_kind==4)then
                    if(abs(x%r)>real(huge(0.0_real32),real64))then
                        call runtime_error('NORM2 REAL(4) input exceeds range',lin,col);return
                    end if
                    ax4=abs(real(x%r,real32))
                    if(ax4==0.0_real32)cycle
                    if(scale4<ax4)then
                        ssq4=1.0_real32+ssq4*(scale4/ax4)**2;scale4=ax4
                    else
                        ssq4=ssq4+(ax4/scale4)**2
                    end if
                else
                    ax8=abs(x%r)
                    if(ax8==0.0_real64)cycle
                    if(scale8<ax8)then
                        ssq8=1.0_real64+ssq8*(scale8/ax8)**2;scale8=ax8
                    else
                        ssq8=ssq8+(ax8/scale8)**2
                    end if
                end if
            end do
            ! Scaled sum of squares avoids x*x overflow/underflow. Operations
            ! retain the ARRAY kind; only the final value uses common storage.
            if(e%real_kind==4)then
                factor4=sqrt(ssq4)
                if(scale4>huge(0.0_real32)/factor4)then
                    call runtime_error('NORM2 result exceeds REAL range',lin,col);return
                end if
                value%r=real(scale4*factor4,real64)
            else
                factor8=sqrt(ssq8)
                if(scale8>huge(0.0_real64)/factor8)then
                    call runtime_error('NORM2 result exceeds REAL range',lin,col);return
                end if
                value%r=scale8*factor8
            end if
            if(.not.ieee_is_finite(value%r))call runtime_error('NORM2 result exceeds REAL range',lin,col)
            end associate
        end subroutine
        recursive subroutine prepare_array_call(index,depth)
            integer,intent(in)::index,depth
            integer::a,b,n,j,mask,dim,typ,rk,rank,ar,br
            integer(int64)::inner,other
            type(value_t)::dv
            associate(e=>prog%expressions(index))
            if(is_bounds_inquiry(e%op))then
                call prepare_bounds_inquiry(index,depth)
                return
            end if
            if(e%op=='transpose'.or.e%op=='norm2')then
                call prepare_matrix_call(index,depth)
                return
            end if
            if(e%op=='shape') then
                call prepare_shape_inquiry(index,depth)
                return
            end if
            if(is_location_reduction(e%op)) then
                call prepare_location(index,depth)
                return
            end if
            if(e%op=='eoshift') then
                call prepare_eoshift(index,depth)
                return
            end if
            if(e%op=='cshift') then
                call prepare_cshift(index,depth)
                return
            end if
            if(e%op=='pack') then
                call prepare_pack(index,depth)
                return
            end if
            if(e%op=='reshape') then
                call prepare_reshape(index,depth)
                return
            end if
            n=size(e%args)
            if(n<1.or.n>3) then
                call runtime_error('invalid array intrinsic argument count',e%line,e%column); return
            end if
            call consume(e%line,e%column)
            do j=1,n
                if(.not.valid_expression(e%args(j))) return
                call prepare_expression(e%args(j),depth+1)
                if(diag%code/=0) return
            end do
            a=e%args(1); ar=prog%expressions(a)%rank
            if(ar<1.or.ar>2) then
                call runtime_error('array intrinsic requires an array',e%line,e%column); return
            end if
            typ=prog%expressions(a)%typ; rk=prog%expressions(a)%real_kind
            rank=0; mask=0; dim=0
            shape_dims(:,index)=[0_int64,1_int64,1_int64]; shape_extent(index)=0_int64
            if(is_logical_reduction(e%op)) then
                if(typ/=ty_logical.or.rk/=4.or.e%intrinsic_mask<1.or.e%intrinsic_mask>7.or. &
                   .not.btest(e%intrinsic_mask,0).or.popcnt(e%intrinsic_mask)/=n.or. &
                   (e%op/='count'.and.btest(e%intrinsic_mask,2))) then
                    call runtime_error('invalid logical reduction MASK/slots',e%line,e%column);return
                end if
                typ=ty_logical;rk=4
                if(e%op=='count') typ=ty_integer
                do j=2,n
                    b=e%args(j)
                    if(prog%expressions(b)%typ/=ty_integer.or.prog%expressions(b)%rank/=0) then
                        call runtime_error('logical reduction DIM/KIND must be scalar INTEGER',e%line,e%column);return
                    end if
                end do
                if(btest(e%intrinsic_mask,1)) then
                    dv=evaluate(e%args(2),depth+1)
                    if(diag%code/=0) return
                    if(dv%tag/=ty_integer.or.dv%i<1.or.dv%i>ar) then
                        call runtime_error('reduction DIM outside array rank',e%line,e%column);return
                    end if
                    dim=int(dv%i);rank=ar-1
                end if
                if(btest(e%intrinsic_mask,2)) then
                    dv=evaluate(e%args(n),depth+1)
                    if(diag%code/=0) return
                    if(dv%tag/=ty_integer.or.(dv%i/=4.and.dv%i/=8)) then
                        call runtime_error('COUNT supports INTEGER kinds 4 and 8',e%line,e%column);return
                    end if
                    rk=int(dv%i)
                end if
                reduction_dim(index)=dim
                if(rank==1) then
                    shape_extent(index)=shape_dims(3-dim,a)
                    shape_dims(:,index)=[shape_extent(index),1_int64,1_int64]
                end if
            else if(is_array_reduction(e%op)) then
                if(typ/=ty_integer.and.typ/=ty_real) then
                    call runtime_error('reduction ARRAY must be numeric',e%line,e%column); return
                end if
                if(n>=2) then
                    b=e%args(2)
                    if(prog%expressions(b)%typ==ty_integer.and.prog%expressions(b)%rank==0) then
                        dv=evaluate(b,depth+1)
                        if(diag%code/=0) return
                        if(dv%tag/=ty_integer.or.dv%i<1.or.dv%i>ar) then
                            call runtime_error('reduction DIM outside array rank',e%line,e%column); return
                        end if
                        dim=int(dv%i); rank=ar-1
                    else if(prog%expressions(b)%typ==ty_logical.and.n==2) then
                        mask=2
                    else
                        call runtime_error('reduction requires scalar INTEGER DIM or LOGICAL MASK',e%line,e%column); return
                    end if
                end if
                if(n==3) mask=3
                if(mask/=0) then
                    b=e%args(mask)
                    if(prog%expressions(b)%typ/=ty_logical) then
                        call runtime_error('reduction MASK must be LOGICAL',e%line,e%column); return
                    end if
                    if(prog%expressions(b)%rank>0) then
                        if(prog%expressions(b)%rank/=ar.or.any(shape_dims(:,a)/=shape_dims(:,b))) then
                            call runtime_error('reduction MASK shape does not conform',e%line,e%column); return
                        end if
                    end if
                end if
                reduction_dim(index)=dim
                if(rank==1) then
                    shape_extent(index)=shape_dims(3-dim,a)
                    shape_dims(:,index)=[shape_extent(index),1_int64,1_int64]
                end if
            else
                if(n/=2) then
                    call runtime_error('DOT_PRODUCT/MATMUL require two arrays',e%line,e%column); return
                end if
                b=e%args(2); br=prog%expressions(b)%rank
                if(br<1.or.br>2) then
                    call runtime_error('DOT_PRODUCT/MATMUL require array arguments',e%line,e%column); return
                end if
                if(typ==ty_logical.and.prog%expressions(b)%typ==ty_logical) then
                    typ=ty_logical
                else if((typ==ty_integer.or.typ==ty_real).and. &
                    (prog%expressions(b)%typ==ty_integer.or.prog%expressions(b)%typ==ty_real)) then
                    typ=ty_integer; rk=4
                    if(prog%expressions(a)%typ==ty_integer.and.prog%expressions(b)%typ==ty_integer) &
                        rk=max(prog%expressions(a)%real_kind,prog%expressions(b)%real_kind)
                    if(prog%expressions(a)%typ==ty_real) then
                        typ=ty_real; rk=prog%expressions(a)%real_kind
                    end if
                    if(prog%expressions(b)%typ==ty_real) then
                        typ=ty_real; rk=max(rk,prog%expressions(b)%real_kind)
                    end if
                else
                    call runtime_error('DOT_PRODUCT/MATMUL operand types are incompatible',e%line,e%column); return
                end if
                if(e%op=='dot_product') then
                    if(ar/=1.or.br/=1) then
                        call runtime_error('DOT_PRODUCT requires vectors',e%line,e%column); return
                    end if
                    inner=shape_extent(a); other=shape_extent(b)
                else
                    if(ar==1.and.br==1) then
                        call runtime_error('MATMUL requires at least one matrix',e%line,e%column); return
                    end if
                    inner=shape_dims(ar,a); other=shape_dims(1,b)
                    rank=ar+br-2
                    shape_dims(:,index)=1_int64
                    if(ar==2) shape_dims(1,index)=shape_dims(1,a)
                    if(br==2) shape_dims(rank,index)=shape_dims(2,b)
                    shape_extent(index)=shape_size(shape_dims(:,index))
                end if
                if(inner/=other) then
                    call runtime_error('DOT_PRODUCT/MATMUL inner dimensions do not conform',e%line,e%column); return
                end if
            end if
            if(shape_extent(index)>max_array_elements) then
                call runtime_error('array intrinsic result element limit exceeded',e%line,e%column); return
            end if
            if(e%rank/=rank.or.e%typ/=typ.or.e%real_kind/=rk) then
                call runtime_error('array intrinsic result type/kind/rank differs',e%line,e%column); return
            end if
            if(e%extent>=0.and.e%extent/=shape_extent(index)) then
                call runtime_error('array intrinsic cached extent differs',e%line,e%column); return
            end if
            if(rank>=2.and.e%extent>=0) then
                if(any(e%dims/=shape_dims(:,index))) &
                    call runtime_error('array intrinsic cached dimensions differ',e%line,e%column)
            end if
            end associate
        end subroutine
        recursive subroutine array_intrinsic_value(index,depth,value,position)
            integer,intent(in)::index,depth
            integer,intent(in),optional::position
            type(value_t),intent(out)::value
            type(value_t)::x,y,term,m
            integer::a,b,k,n,mask,pos,dim,source,leftpos,rightpos,row,col,ar,br,lin,column
            logical::selected
            call prepare_expression(index,depth)
            if(diag%code/=0) return
            associate(e=>prog%expressions(index))
            lin=e%line; column=e%column
            a=e%args(1);ar=prog%expressions(a)%rank
            value=value_t(tag=e%typ,real_kind=e%real_kind)
            pos=1
            if(present(position)) pos=position
            if(is_bounds_inquiry(e%op).and.e%rank==0)pos=1
            if(e%op=='pack'.or.e%op=='shape'.or.e%op=='cshift'.or.e%op=='eoshift'.or.is_bounds_inquiry(e%op).or.is_location_reduction(e%op)) then
                if(.not.allocated(expression_cache(index)%values)) then
                    call runtime_error('PACK result cache is missing',lin,column);return
                end if
                if(pos<1.or.pos>size(expression_cache(index)%values)) then
                    call runtime_error('PACK result index outside bounds',lin,column);return
                end if
                value=expression_cache(index)%values(pos)
                return
            end if
            if(e%op=='transpose'.or.e%op=='norm2')then
                ! A scalar norm broadcasts; the surrounding array position
                ! does not select a second scalar result element.
                if(e%rank==0)pos=1
                call matrix_intrinsic_value(index,depth,pos,value)
                return
            end if
            if(e%op=='reshape') then
                source=pos
                if(e%rank>=2.and.reduction_dim(index)==2) then
                    row=mod(pos-1,int(shape_dims(1,index)))
                    col=(pos-1)/int(shape_dims(1,index))
                    source=col+row*int(shape_dims(2,index))+1
                end if
                b=a
                if(source>shape_extent(a)) then
                    b=e%args(3)
                    source=mod(source-int(shape_extent(a))-1,int(shape_extent(b)))+1
                end if
                value=evaluate(b,depth+1,source)
                if(diag%code/=0) return
                if(value%tag/=e%typ.or.value%real_kind/=e%real_kind) then
                    call runtime_error('RESHAPE element type/kind differs from SOURCE',lin,column);return
                end if
                if(e%typ==ty_character) then
                    if(.not.allocated(value%s)) then
                        call runtime_error('missing RESHAPE CHARACTER element',lin,column);return
                    end if
                    if(len(value%s)/=e%character_len) &
                        call runtime_error('RESHAPE CHARACTER element length differs',lin,column)
                end if
            else if(is_array_reduction(e%op)) then
                select case(e%op)
                case('all')
                    value%l=.true.
                case('product')
                    value%i=1_int64; value%r=1.0_real64
                case('minval','maxval')
                    value%i=imax
                    if(e%real_kind==8) value%i=max64
                    value%r=huge(0.0_real64)
                    if(e%real_kind==4) value%r=real(huge(0.0_real32),real64)
                    if(e%op=='maxval') then
                        value%i=imin
                        if(e%real_kind==8) value%i=min64
                        value%r=-value%r
                    end if
                end select
                mask=0;dim=reduction_dim(index)
                if(.not.is_logical_reduction(e%op)) then
                    if(size(e%args)==3) mask=e%args(3)
                    if(size(e%args)==2.and.dim==0) mask=e%args(2)
                end if
                selected=.true.
                if(mask/=0) then
                    if(prog%expressions(mask)%rank==0) then
                        m=evaluate(mask,depth+1)
                        if(diag%code/=0) return
                        selected=m%l
                    end if
                end if
                n=int(shape_extent(a))
                if(dim/=0) n=int(shape_dims(dim,a))
                do k=1,n
                    call consume(lin,column)
                    if(diag%code/=0) return
                    source=k
                    if(ar==2.and.dim==1) source=k+(pos-1)*int(shape_dims(1,a))
                    if(ar==2.and.dim==2) source=pos+(k-1)*int(shape_dims(1,a))
                    if(mask/=0) then
                        if(prog%expressions(mask)%rank>0) then
                            m=evaluate(mask,depth+1,source)
                            if(diag%code/=0) return
                            selected=m%l
                        end if
                    end if
                    if(.not.selected) cycle
                    x=evaluate(a,depth+1,source)
                    if(diag%code/=0) return
                    if(is_logical_reduction(e%op)) then
                        if(x%tag/=ty_logical.or.x%real_kind/=4) then
                            call runtime_error('logical reduction MASK value differs from LOGICAL metadata',lin,column);return
                        end if
                    end if
                    select case(e%op)
                    case('all'); value%l=value%l.and.x%l
                    case('any'); value%l=value%l.or.x%l
                    case('parity'); value%l=value%l.neqv.x%l
                    case('count'); if(x%l) value%i=value%i+1_int64
                    case('sum'); value=binary('+',value,x,e%typ,lin,column,e%real_kind)
                    case('product'); value=binary('*',value,x,e%typ,lin,column,e%real_kind)
                    case('minval'); value=intrinsic_value('min',[value,x],e%typ,lin,column,e%real_kind)
                    case('maxval'); value=intrinsic_value('max',[value,x],e%typ,lin,column,e%real_kind)
                    end select
                    call check_accumulator(value,lin,column)
                    if(diag%code/=0) return
                end do
            else
                b=e%args(2);br=prog%expressions(b)%rank
                n=int(shape_dims(ar,a));row=1;col=1
                if(e%op=='matmul') then
                    if(ar==2) row=pos
                    if(br==2) col=pos
                    if(ar==2.and.br==2) then
                        row=mod(pos-1,int(shape_dims(1,index)))+1
                        col=(pos-1)/int(shape_dims(1,index))+1
                    end if
                end if
                do k=1,n
                    call consume(lin,column)
                    if(diag%code/=0) return
                    leftpos=k;rightpos=k
                    if(ar==2) leftpos=row+(k-1)*int(shape_dims(1,a))
                    if(br==2) rightpos=k+(col-1)*int(shape_dims(1,b))
                    x=evaluate(a,depth+1,leftpos);y=evaluate(b,depth+1,rightpos)
                    if(diag%code/=0) return
                    if(e%typ==ty_logical) then
                        value%l=value%l.or.(x%l.and.y%l)
                    else
                        term=binary('*',x,y,e%typ,lin,column,e%real_kind)
                        call check_accumulator(term,lin,column)
                        if(diag%code/=0) return
                        value=binary('+',value,term,e%typ,lin,column,e%real_kind)
                        call check_accumulator(value,lin,column)
                        if(diag%code/=0) return
                    end if
                end do
            end if
            end associate
        end subroutine
        subroutine check_accumulator(value,lin,col)
            type(value_t),intent(in)::value
            integer,intent(in)::lin,col
            if(diag%code/=0) return
            if(value%tag==ty_integer) then
                if(.not.check_integer(value%i,lin,col,value%real_kind)) return
            else if(value%tag==ty_real) then
                if(.not.ieee_is_finite(value%r)) call runtime_error('non-finite real result',lin,col)
            end if
        end subroutine
        subroutine merge_runtime_shape(parent,child,previous)
            integer, intent(in) :: parent,child
            integer, intent(in), optional :: previous
            if (diag%code/=0.or.prog%expressions(child)%rank==0) return
            if (present(previous)) then
                if (previous>0) then
                    if (prog%expressions(previous)%rank>0) then
                        if (prog%expressions(previous)%rank/=prog%expressions(child)%rank.or. &
                            any(shape_dims(:,previous)/=shape_dims(:,child))) then
                            call runtime_error('array expression shapes do not conform', &
                                prog%expressions(parent)%line,prog%expressions(parent)%column)
                            return
                        end if
                    end if
                end if
            end if
            shape_extent(parent)=shape_extent(child)
            shape_dims(:,parent)=shape_dims(:,child)
        end subroutine
        subroutine validate_substring(index,inquiry)
            integer,intent(in)::index
            logical,intent(in),optional::inquiry
            integer::s,j,children(2),b,r,indices(3)
            logical::allow_absent
            allow_absent=.false.
            if(present(inquiry)) allow_absent=inquiry
            if(.not.valid_expression(index)) return
            associate(e=>prog%expressions(index))
            s=e%symbol
            if(s==0) then
                if(e%value%tag/=ty_character.or.e%value%real_kind/=4.or..not.allocated(e%value%s)) then
                    call runtime_error('invalid literal substring base',e%line,e%column);return
                end if
                if(len(e%value%s)>65536) then
                    call runtime_error('literal substring base length limit exceeded',e%line,e%column);return
                end if
            else
                if(.not.valid_symbol(s,allow_absent=allow_absent)) return
                if(prog%symbols(s)%typ/=ty_character.or.(prog%symbols(s)%rank/=0.and.e%third==0).or. &
                   e%value%tag/=0.or.allocated(e%value%s)) then
                    call runtime_error('invalid substring base',e%line,e%column);return
                end if
            end if
            if(e%kind/=ex_substring.or.e%typ/=ty_character.or.e%rank/=0.or. &
               e%real_kind/=4.or.e%character_len/=-1.or.e%extent/=0.or.any(e%dims/=0).or. &
               e%stride/=0.or.e%left2/=0.or.e%right2/=0.or.e%stride2/=0.or. &
               e%left3/=0.or.e%right3/=0.or.e%stride3/=0.or.any(e%triplet(2:)).or. &
               e%length_expr/=0.or.allocated(e%args)) then
                call runtime_error('invalid scalar substring metadata',e%line,e%column);return
            end if
            if(e%third/=0) then
                b=e%third
                if(.not.valid_expression(b)) return
                if(s<=0) then
                    call runtime_error('substring element requires an array symbol',e%line,e%column);return
                end if
                r=prog%symbols(s)%rank
                associate(base=>prog%expressions(b))
                if(base%kind/=ex_element.or.base%symbol/=s.or.base%typ/=ty_character.or.base%real_kind/=4.or.prog%symbols(s)%real_kind/=4.or. &
                   base%rank/=0.or.base%extent/=0.or.any(base%dims/=0).or.r<1.or.r>3.or. &
                   base%character_len/=prog%symbols(s)%character_len.or. &
                   base%left==0.or.(r>=2.eqv.base%right==0).or.(r==3.eqv.base%third==0).or. &
                   base%stride/=0.or.base%left2/=0.or.base%right2/=0.or.base%stride2/=0.or. &
                   base%left3/=0.or.base%right3/=0.or.base%stride3/=0.or.any(base%triplet(2:)).or. &
                   allocated(base%args).or.base%length_expr/=0.or.base%value%tag/=0.or. &
                   allocated(base%value%s).or.allocated(base%value%record)) then
                    call runtime_error('invalid substring element base metadata',e%line,e%column);return
                end if
                indices=[base%left,base%right,base%third]
                do j=1,r
                    call validate_substring_index(indices(j))
                    if(diag%code/=0)return
                end do
                end associate
            end if
            children=[e%left,e%right]
            do j=1,2
                if(children(j)==0) cycle
                if(.not.valid_expression(children(j))) return
                if(prog%expressions(children(j))%rank/=0.or.prog%expressions(children(j))%typ/=ty_integer) then
                    call runtime_error('substring bounds must be scalar INTEGER',e%line,e%column);return
                end if
            end do
            end associate
        end subroutine
        recursive subroutine substring_bounds(index,lo,hi,depth)
            integer,intent(in)::index,depth
            integer,intent(out)::lo,hi
            integer::s,n,j,children(2)
            integer(int64)::bounds(2)
            type(value_t)::value
            lo=1;hi=0
            if(depth>512) then
                call runtime_error('substring expression nesting limit exceeded',0,0);return
            end if
            call validate_substring(index)
            if(diag%code/=0) return
            associate(e=>prog%expressions(index))
            s=e%symbol
            if(s==0) then
                n=len(e%value%s)
            else
                if(prog%symbols(s)%is_allocatable.and.(e%third==0.or.prog%symbols(s)%deferred_character)) then
                    if(.not.array_available(s,e%line,e%column)) return
                end if
                n=prog%symbols(s)%character_len
                if(n<0.and.allocated(refs(s)%value%s)) n=len(refs(s)%value%s)
                if(n<0.and.e%third/=0) n=refs(s)%array%character_len
            end if
            if(n<0.or.n>65536) then
                call runtime_error('invalid substring base length',e%line,e%column);return
            end if
            bounds=[1_int64,int(n,int64)];children=[e%left,e%right]
            do j=1,2
                if(children(j)==0) cycle
                value=evaluate(children(j),depth+1)
                if(diag%code/=0) return
                if(value%tag/=ty_integer) then
                    call runtime_error('substring bounds must be INTEGER',e%line,e%column);return
                end if
                if(.not.check_integer(value%i,e%line,e%column,value%real_kind)) return
                bounds(j)=value%i
            end do
            ! A reversed range is empty. Never form a host substring or subtract
            ! arbitrary int64 bounds in that case, even at the integer extremes.
            if(bounds(2)<bounds(1)) return
            if(bounds(1)<1.or.bounds(2)>n) then
                call runtime_error('substring bounds out of range',e%line,e%column);return
            end if
            lo=int(bounds(1));hi=int(bounds(2))
            end associate
        end subroutine
        subroutine validate_substring_index(index)
            integer,intent(in)::index
            integer::s
            if(.not.valid_expression(index))return
            associate(e=>prog%expressions(index))
            if(e%typ/=ty_integer.or.e%rank/=0.or.e%extent/=0.or.any(e%dims/=0).or. &
               (e%real_kind/=4.and.e%real_kind/=8))then
                call runtime_error('invalid substring element index metadata',e%line,e%column);return
            end if
            if(e%kind==ex_literal)then
                if(e%value%tag/=ty_integer.or.e%value%real_kind/=e%real_kind.or. &
                   allocated(e%value%s).or.allocated(e%value%record))then
                    call runtime_error('invalid substring index literal cache',e%line,e%column);return
                end if
                if(.not.check_integer(e%value%i,e%line,e%column,e%real_kind))return
            else if(e%kind==ex_variable)then
                s=e%symbol
                if(.not.valid_symbol(s,allow_absent=.true.))return
                if(prog%symbols(s)%typ/=ty_integer.or.prog%symbols(s)%rank/=0.or. &
                   prog%symbols(s)%real_kind/=e%real_kind)then
                    call runtime_error('substring index declaration differs',e%line,e%column);return
                end if
                if(prog%symbols(s)%is_parameter.and.prog%symbols(s)%parameter_ready)then
                    associate(v=>prog%symbols(s)%constant_value)
                    if(v%tag/=ty_integer.or.v%real_kind/=e%real_kind.or.allocated(v%s).or.allocated(v%record))then
                        call runtime_error('invalid substring index PARAMETER cache',e%line,e%column);return
                    end if
                    if(.not.check_integer(v%i,e%line,e%column,v%real_kind))return
                    end associate
                end if
            end if
            end associate
        end subroutine
        integer function substring_element_offset(base,depth) result(offset)
            integer,intent(in)::base,depth
            integer::children(3),s,r,j,e
            type(value_t)::indices(3)
            offset=0
            associate(x=>prog%expressions(base))
            s=x%symbol;r=prog%symbols(s)%rank;children=[x%left,x%right,x%third]
            do j=1,r
                e=children(j)
                call validate_substring_index(e)
                if(diag%code/=0)return
                indices(j)=evaluate(e,depth+1)
                if(diag%code/=0)return
                if(indices(j)%tag/=ty_integer.or.indices(j)%real_kind/=prog%expressions(e)%real_kind.or. &
                   allocated(indices(j)%s).or.allocated(indices(j)%record))then
                    call runtime_error('substring index value metadata differs',x%line,x%column);return
                end if
                if(.not.check_integer(indices(j)%i,x%line,x%column,indices(j)%real_kind))return
            end do
            offset=element_offset(s,indices(:r),x%line,x%column)
            end associate
        end function
        subroutine check_substring_payload(value,n,lin,col)
            type(value_t),intent(in)::value
            integer,intent(in)::n,lin,col
            if(value%tag/=ty_character.or.value%real_kind/=4.or..not.allocated(value%s).or. &
               allocated(value%record)) then
                call runtime_error('invalid substring element payload',lin,col);return
            end if
            if(n<0.or.n>65536) then
                call runtime_error('invalid substring element length',lin,col);return
            end if
            if(len(value%s)/=n) call runtime_error('substring element payload length differs',lin,col)
        end subroutine
        recursive function substring_element_value(base,depth) result(value)
            integer,intent(in)::base,depth
            type(value_t)::value
            integer::s,k,n,lin,col
            associate(e=>prog%expressions(base))
            s=e%symbol;lin=e%line;col=e%column
            k=substring_element_offset(base,depth)
            if(diag%code/=0) return
            n=prog%symbols(s)%character_len
            if(n<0) n=refs(s)%array%character_len
            if(prog%symbols(s)%is_parameter) then
                if(.not.prog%symbols(s)%parameter_ready.or..not.allocated(prog%symbols(s)%constant_values)) then
                    call runtime_error('array PARAMETER value is not defined',lin,col);return
                end if
                if(k<1.or.k>size(prog%symbols(s)%constant_values)) then
                    call runtime_error('substring PARAMETER position out of bounds',lin,col);return
                end if
                call check_substring_payload(prog%symbols(s)%constant_values(k),n,lin,col)
                if(diag%code/=0) return
                value=parameter_element(s,k,lin,col)
            else
                if(present(constant_index)) then
                    call runtime_error('substring element is not a constant expression',lin,col);return
                end if
                if(.not.associated(refs(s)%array%data).or..not.associated(refs(s)%array%flags)) then
                    call runtime_error('substring element storage missing',lin,col);return
                end if
                if(k<1.or.k>size(refs(s)%array%data).or.k>size(refs(s)%array%flags)) then
                    call runtime_error('substring element position out of bounds',lin,col);return
                end if
                if(.not.refs(s)%array%flags(k)) then
                    call runtime_error('read of uninitialized substring element',lin,col);return
                end if
                call check_substring_payload(refs(s)%array%data(k),n,lin,col)
                if(diag%code/=0) return
                value=refs(s)%array%data(k)
            end if
            end associate
        end function
        subroutine assign_substring(s,target,rhs,lin,col)
            integer,intent(in)::s,target,rhs,lin,col
            integer::lo,hi,n,b,k
            logical::is_defined
            type(value_t)::value,previous
            character(:),allocatable::staged
            call substring_bounds(target,lo,hi,0)
            if(diag%code/=0) return
            if(prog%expressions(target)%symbol/=s.or.s<=0) then
                call runtime_error('substring assignment requires a variable base',lin,col);return
            end if
            b=prog%expressions(target)%third;k=0
            if(b/=0) then
                associate(base=>prog%expressions(b))
                k=substring_element_offset(b,0)
                end associate
                if(diag%code/=0) return
            end if
            value=evaluate(rhs,0)
            if(diag%code/=0) return
            if(value%tag/=ty_character.or.value%real_kind/=4.or..not.allocated(value%s).or.allocated(value%record)) then
                call runtime_error('substring assignment requires CHARACTER' ,lin,col);return
            end if
            n=prog%symbols(s)%character_len
            if(n<0.and.allocated(refs(s)%value%s)) n=len(refs(s)%value%s)
            if(b/=0) then
                if(n<0) n=refs(s)%array%character_len
                if(.not.associated(refs(s)%array%data).or..not.associated(refs(s)%array%flags)) then
                    call runtime_error('substring element storage missing',lin,col);return
                end if
                if(k<1.or.k>size(refs(s)%array%data).or.k>size(refs(s)%array%flags)) then
                    call runtime_error('substring element storage changed',lin,col);return
                end if
                is_defined=refs(s)%array%flags(k)
                if(is_defined) then
                    call check_substring_payload(refs(s)%array%data(k),n,lin,col)
                    if(diag%code/=0) return
                    previous=refs(s)%array%data(k)
                end if
            else
                is_defined=refs(s)%defined
                if(is_defined) previous=refs(s)%value
            end if
            if(b/=0.and.hi>=lo)then
                if(lo<1.or.hi>n)then
                    call runtime_error('substring target length changed during evaluation',lin,col);return
                end if
            end if
            if(hi<lo) then
                if(n==0) then
                    if(b/=0) then
                        refs(s)%array%data(k)=value_t(tag=ty_character,s='');refs(s)%array%flags(k)=.true.
                    else
                        refs(s)%value=value_t(tag=ty_character,s='');refs(s)%defined=.true.
                    end if
                end if
                return
            end if
            if(.not.is_defined) then
                if(lo/=1.or.hi/=n) then
                    call runtime_error('partial substring assignment requires an initialized base',lin,col);return
                end if
                staged=repeat(' ',n)
            else
                if(.not.allocated(previous%s)) then
                    call runtime_error('substring base storage missing',lin,col);return
                end if
                if(len(previous%s)/=n) then
                    call runtime_error('substring base storage length differs',lin,col);return
                end if
                staged=previous%s
            end if
            staged(lo:hi)=value%s
            if(b/=0) then
                refs(s)%array%data(k)=value_t(tag=ty_character,s=staged);refs(s)%array%flags(k)=.true.
            else
                refs(s)%value=value_t(tag=ty_character,s=staged);refs(s)%defined=.true.
            end if
        end subroutine
        recursive subroutine triplet_value(index,value,depth)
            integer, intent(in) :: index,depth
            integer(int64), intent(out) :: value
            type(value_t) :: evaluated
            value=0_int64
            if (.not.valid_expression(index)) return
            if (prog%expressions(index)%rank/=0.or.prog%expressions(index)%typ/=ty_integer) then
                call runtime_error('section triplet must be scalar INTEGER', &
                    prog%expressions(index)%line,prog%expressions(index)%column)
                return
            end if
            evaluated=evaluate(index,depth)
            if (diag%code/=0) return
            if (evaluated%tag/=ty_integer) then
                call runtime_error('section triplet must be scalar INTEGER',0,0)
                return
            end if
            if (.not.check_integer(evaluated%i,0,0)) return
            value=evaluated%i
        end subroutine
        recursive function evaluate(index,depth,position) result(v)
            integer, intent(in) :: index,depth
            integer, intent(in), optional :: position
            type(value_t) :: v,x,y
            type(component_value_t)::packed
            type(value_t), allocatable :: argv(:)
            integer :: k,lin,col,child,at,lo,hi,item_length
            integer(int64) :: result_extent,child_extent
            if (diag%code/=0) return
            if (.not.valid_expression(index)) return
            lin=prog%expressions(index)%line
            col=prog%expressions(index)%column
            call consume(lin,col)
            if (diag%code/=0) return
            if (depth>512) then
                call runtime_error('expression nesting limit exceeded',lin,col)
                return
            end if
            associate(e=>prog%expressions(index))
            if (e%rank>0) then
                if (.not.present(position)) then
                    call runtime_error('array expression requires an array context',lin,col)
                    return
                end if
                call prepare_expression(index,depth)
                if (diag%code/=0) return
                if (position<1.or.position>shape_extent(index)) then
                    call runtime_error('array expression position out of bounds',lin,col)
                    return
                end if
            end if
            v%tag=e%typ; v%real_kind=e%real_kind
            select case(e%kind)
            case(ex_constructor_index)
                do k=constructor_level,1,-1
                    if(constructor_owners(k)/=e%constructor_owner) cycle
                    v%i=constructor_values(k);return
                end do
                call runtime_error('constructor index is outside its lexical activation',lin,col);return
            case(ex_constructor_do)
                call runtime_error('constructor implied-DO requires its constructor context',lin,col);return
            case(ex_gather_rows)
                if(.not.present(position)) then
                    call runtime_error('row gather requires an array context',lin,col);return
                end if
                if(.not.allocated(expression_cache(index)%values)) then
                    call runtime_error('row gather temporary is missing',lin,col);return
                end if
                v=expression_cache(index)%values(position)
            case(ex_record)
                k=e%typ-ty_derived_base
                call initialize_record(v,e%typ);if(diag%code/=0) return
                if(.not.allocated(e%args)) then
                    call runtime_error('structure constructor arguments are absent',lin,col);return
                end if
                if(size(e%args)>size(v%record%components)) then
                    call runtime_error('structure constructor component count mismatch',lin,col);return
                end if
                do at=size(e%args)+1,size(v%record%components)
                    if(.not.v%record%component_defined(at)) then
                        call runtime_error('omitted structure component has no default',lin,col);return
                    end if
                end do
                do at=1,size(e%args)
                    x=evaluate(e%args(at),depth+1);if(diag%code/=0) return
                    y=convert(x,prog%derived_types(k)%component_types(at),lin,col, &
                              prog%derived_types(k)%component_kinds(at))
                    if(diag%code/=0) return
                    packed=pack_component(y,k,at)
                    if(diag%code/=0) return
                    v%record%components(at)=packed
                    v%record%component_defined(at)=.true.
                end do
            case(ex_component)
                if(.not.valid_expression(e%left)) return
                if(prog%expressions(e%left)%kind/=ex_variable) then
                    call runtime_error('component base must be a scalar variable',lin,col);return
                end if
                k=prog%expressions(e%left)%symbol
                if(.not.valid_symbol(k)) return
                if(.not.allocated(refs(k)%value%record)) then
                    call runtime_error('uninitialized derived object',lin,col);return
                end if
                if(.not.allocated(refs(k)%value%record%components).or..not.allocated(refs(k)%value%record%component_defined)) then
                    call runtime_error('uninitialized derived object',lin,col);return
                end if
                if(e%symbol<1.or.e%symbol>size(refs(k)%value%record%components)) then
                    call runtime_error('invalid component reference',lin,col);return
                end if
                child=prog%symbols(k)%typ-ty_derived_base
                if(child<1.or.child>prog%nt.or.prog%expressions(e%left)%typ/=prog%symbols(k)%typ) then
                    call runtime_error('invalid component base type metadata',lin,col);return
                end if
                if(e%symbol>prog%derived_types(child)%ncomponents.or. &
                   e%symbol>size(refs(k)%value%record%component_defined)) then
                    call runtime_error('invalid component schema reference',lin,col);return
                end if
                if(e%typ/=prog%derived_types(child)%component_types(e%symbol).or. &
                   e%real_kind/=prog%derived_types(child)%component_kinds(e%symbol).or. &
                   e%character_len/=prog%derived_types(child)%component_lengths(e%symbol).or. &
                   e%rank/=0.or.e%extent/=0.or.any(e%dims/=0)) then
                    call runtime_error('component type-kind-length metadata differs',lin,col);return
                end if
                associate(base=>prog%expressions(e%left))
                if(base%rank/=0.or.base%extent/=0.or.any(base%dims/=0).or. &
                   base%real_kind/=4.or.base%character_len/=-1.or.prog%symbols(k)%rank/=0) then
                    call runtime_error('invalid component base shape-kind metadata',lin,col);return
                end if
                end associate
                if(.not.refs(k)%value%record%component_defined(e%symbol)) then
                    call runtime_error('read of uninitialized derived component',lin,col);return
                end if
                associate(c=>refs(k)%value%record%components(e%symbol))
                    if(c%tag/=e%typ.or.c%real_kind/=e%real_kind) then
                        call runtime_error('component payload type-kind differs',lin,col);return
                    end if
                    v=value_t(tag=c%tag,real_kind=c%real_kind,i=c%i,r=c%r,l=c%l)
                    if(c%tag==ty_character) then
                        if(.not.allocated(c%s)) then
                            call runtime_error('CHARACTER component payload missing',lin,col);return
                        end if
                        if(len(c%s)/=e%character_len) then
                            call runtime_error('CHARACTER component payload length differs',lin,col);return
                        end if
                        v%s=c%s
                    end if
                end associate
                if(v%tag/=e%typ) call runtime_error('component type mismatch',lin,col)
            case(ex_constructor)
                call prepare_expression(index,depth+1)
                if(diag%code/=0) return
                if(.not.present(position)) then
                    call runtime_error('constructor requires an array context',lin,col);return
                end if
                if(allocated(expression_cache(index)%values)) then
                    v=expression_cache(index)%values(position);return
                end if
                at=position
                do k=1,size(e%args)
                    call consume(lin,col)
                    if(diag%code/=0) return
                    child=e%args(k);child_extent=1_int64
                    if(prog%expressions(child)%rank>0) child_extent=shape_extent(child)
                    if(at<=child_extent) then
                        if(prog%expressions(child)%rank==0) then
                            v=evaluate(child,depth+1)
                        else
                            v=evaluate(child,depth+1,at)
                        end if
                        exit
                    end if
                    at=at-int(child_extent)
                end do
                if(diag%code/=0) return
                if(e%typ==ty_character) then
                    item_length=expression_cache(index)%character_len
                    if(.not.allocated(v%s).or.item_length<0.or.item_length>65536) then
                        call runtime_error('invalid CHARACTER constructor length',lin,col);return
                    end if
                    if(e%op/='character'.and.len(v%s)/=item_length) then
                        call runtime_error('CHARACTER constructor item lengths differ',lin,col);return
                    end if
                    v%s=v%s(:min(len(v%s),item_length))//repeat(' ',max(0,item_length-len(v%s)))
                end if
            case(ex_literal)
                v=e%value
            case(ex_variable)
                if (.not.valid_symbol(e%symbol)) return
                if (prog%symbols(e%symbol)%is_parameter) then
                    if (.not.prog%symbols(e%symbol)%parameter_ready) then
                        call runtime_error('PARAMETER value is not defined',lin,col)
                        return
                    end if
                    if(prog%symbols(e%symbol)%rank>0) then
                        if(.not.present(position)) then
                            call runtime_error('PARAMETER must be scalar for a scalar variable expression',lin,col);return
                        end if
                        v=parameter_element(e%symbol,position,lin,col)
                        return
                    end if
                    v=prog%symbols(e%symbol)%constant_value
                    if(v%tag/=prog%symbols(e%symbol)%typ.or.v%tag/=e%typ) then
                        call runtime_error('PARAMETER value type mismatch',lin,col)
                    end if
                    if(prog%symbols(e%symbol)%rank/=0) &
                        call runtime_error('PARAMETER must be scalar',lin,col)
                    if(v%tag==ty_real) then
                        if(v%real_kind/=prog%symbols(e%symbol)%real_kind.or.v%real_kind/=e%real_kind) then
                            call runtime_error('PARAMETER value kind mismatch',lin,col); return
                        end if
                    end if
                    if(v%tag==ty_integer) then
                        if(.not.check_integer(v%i,lin,col,v%real_kind)) return
                    else if(v%tag==ty_real) then
                        if(.not.ieee_is_finite(v%r)) call runtime_error('non-finite PARAMETER value',lin,col)
                    end if
                    return
                end if
                if(present(constant_index)) then
                    call runtime_error('variable is not a constant expression',lin,col)
                    return
                end if
                if (prog%symbols(e%symbol)%rank>0) then
                    if(.not.array_available(e%symbol,lin,col)) return
                    if (.not.present(position)) then
                        call runtime_error('array expression requires an array context',lin,col)
                        return
                    end if
                    if (e%rank/=prog%symbols(e%symbol)%rank.or. &
                        (e%extent>=0.and.e%extent/=size(refs(e%symbol)%array%data,kind=int64))) then
                        call runtime_error('array expression shape differs from symbol',lin,col)
                        return
                    end if
                    if (.not.refs(e%symbol)%array%flags(position)) then
                        call runtime_error('read of uninitialized array element '//trim(prog%symbols(e%symbol)%name),lin,col)
                        return
                    end if
                    v=refs(e%symbol)%array%data(position)
                    return
                end if
                if(prog%symbols(e%symbol)%is_allocatable) then
                    if(.not.array_available(e%symbol,lin,col)) return
                end if
                if (.not.refs(e%symbol)%defined) then
                    call runtime_error('read of uninitialized variable '//trim(prog%symbols(e%symbol)%name),lin,col)
                    return
                end if
                v=refs(e%symbol)%value
                if(is_derived_type(v%tag)) then
                    if(.not.record_defined(v)) call runtime_error('read of uninitialized derived components',lin,col)
                end if
            case(ex_substring)
                call substring_bounds(index,lo,hi,depth+1)
                if(diag%code/=0) return
                if(hi<lo) then
                    v%s='';return
                end if
                k=e%symbol
                if(e%third/=0) then
                    x=substring_element_value(e%third,depth+1)
                    if(diag%code/=0) return
                else if(k==0) then
                    x=e%value
                else if(prog%symbols(k)%is_parameter) then
                    if(.not.prog%symbols(k)%parameter_ready) then
                        call runtime_error('substring PARAMETER is not defined',lin,col);return
                    end if
                    x=prog%symbols(k)%constant_value
                else
                    if(present(constant_index)) then
                        call runtime_error('substring is not a constant expression',lin,col);return
                    end if
                    if(.not.refs(k)%defined) then
                        call runtime_error('read of uninitialized substring base',lin,col);return
                    end if
                    x=refs(k)%value
                end if
                if(x%tag/=ty_character.or..not.allocated(x%s)) then
                    call runtime_error('invalid substring base value',lin,col);return
                end if
                if(hi>len(x%s)) then
                    call runtime_error('substring base storage length differs',lin,col);return
                end if
                v%s=x%s(lo:hi)
            case(ex_section)
                if (e%rank<1.or.e%rank>3.or..not.present(position)) then
                    call runtime_error('section requires an array context',lin,col); return
                end if
                if (.not.allocated(arrays)) then
                    call runtime_error('array sections are not constant expressions',lin,col); return
                end if
                if(present(constant_index).and..not.prog%symbols(e%symbol)%is_parameter) then
                    call runtime_error('array section is not a constant expression',lin,col);return
                end if
                k=section_offset(index,position)
                if(prog%symbols(e%symbol)%is_parameter) then
                    v=parameter_element(e%symbol,k,lin,col);return
                end if
                if (.not.refs(e%symbol)%array%flags(k)) then
                    call runtime_error('read of uninitialized array element '//trim(prog%symbols(e%symbol)%name),lin,col)
                    return
                end if
                v=refs(e%symbol)%array%data(k)
            case(ex_element)
                if(.not.valid_symbol(e%symbol)) return
                if(present(constant_index).and..not.prog%symbols(e%symbol)%is_parameter) then
                    call runtime_error('array element is not a constant expression',lin,col);return
                end if
                k=element_expression_offset(e%symbol,e%left,e%right,e%third,depth,lin,col)
                if (diag%code/=0) return
                if(prog%symbols(e%symbol)%is_parameter) then
                    v=parameter_element(e%symbol,k,lin,col);return
                end if
                if (.not.allocated(arrays)) then
                    call runtime_error('array elements are not constant expressions',lin,col)
                    return
                end if
                if (.not.refs(e%symbol)%array%flags(k)) then
                    call runtime_error('read of uninitialized array element '//trim(prog%symbols(e%symbol)%name),lin,col)
                    return
                end if
                v=refs(e%symbol)%array%data(k)
            case(ex_unary)
                x=evaluate(e%left,depth+1,position)
                if (diag%code/=0) return
                select case(trim(e%op))
                case('+')
                    v=x
                case('-')
                    v=x
                    if (x%tag==ty_integer) then
                        if(x%i==min64) then
                            call runtime_error("integer overflow",lin,col); return
                        end if
                        v%i=-x%i
                    else if (x%tag==ty_real) then
                        v%r=-x%r
                    else
                        call runtime_error('nonnumeric unary operand',lin,col)
                    end if
                case('.not.')
                    if (x%tag/=ty_logical) then
                        call runtime_error('nonlogical unary operand',lin,col)
                        return
                    end if
                    v%l=.not.x%l
                case default
                    call runtime_error('invalid unary operator',lin,col)
                end select
            case(ex_binary)
                x=evaluate(e%left,depth+1,position)
                y=evaluate(e%right,depth+1,position)
                if (diag%code/=0) return
                v=binary(trim(e%op),x,y,e%typ,lin,col,e%real_kind)
            case(ex_user_call)
                if(present(constant_index)) then
                    call runtime_error('module function call is not a constant expression',lin,col); return
                end if
                if(.not.allocated(e%args)) then
                    call runtime_error('missing function arguments',lin,col); return
                end if
                if(e%symbol<1.or.e%symbol>prog%np) then
                    call runtime_error('invalid function reference',lin,col); return
                end if
                if(scope/=0) then
                    if(prog%procedures(scope)%is_pure.and..not.prog%procedures(e%symbol)%is_pure) then
                        call runtime_error('impure function call inside a PURE procedure',lin,col); return
                    end if
                end if
                if(prog%procedures(e%symbol)%is_subroutine) then
                    call runtime_error('subroutine cannot be used as a function',lin,col); return
                end if
                if(.not.allocated(prog%procedures(e%symbol)%args)) then
                    call runtime_error('missing function dummies',lin,col); return
                end if
                if(size(e%args)/=size(prog%procedures(e%symbol)%args)) then
                    call runtime_error('function argument count mismatch',lin,col); return
                end if
                if(prog%procedures(e%symbol)%is_elemental) then
                    call prepare_expression(index,depth+1)
                    if(diag%code/=0) return
                    if(.not.prog%procedures(e%symbol)%is_pure) then
                        if(.not.allocated(expression_cache(index)%values)) then
                            result_extent=1_int64
                            if(e%rank>0) result_extent=shape_extent(index)
                            if(result_extent>max_array_elements-cached_elements) then
                                call runtime_error('impure result temporary element limit exceeded',lin,col);return
                            end if
                            cached_elements=cached_elements+result_extent
                            call invoke_procedure(e%symbol,e%args,lin,col,depth+1, &
                                element_results=expression_cache(index)%values)
                            if(diag%code/=0) return
                        end if
                        k=1
                        if(e%rank>0) k=position
                        if(k<1.or.k>size(expression_cache(index)%values)) then
                            call runtime_error('IMPURE ELEMENTAL result position out of bounds',lin,col);return
                        end if
                        v=expression_cache(index)%values(k)
                    else
                        call invoke_procedure(e%symbol,e%args,lin,col,depth+1,v,position)
                    end if
                else if(e%rank>0) then
                    if(.not.present(position)) then
                        call runtime_error('array function requires an array context',lin,col);return
                    end if
                    call prepare_expression(index,depth+1)
                    if(diag%code/=0) return
                    if(position<1.or.position>size(expression_cache(index)%values)) then
                        call runtime_error('array function result position out of bounds',lin,col);return
                    end if
                    v=expression_cache(index)%values(position)
                else
                    if(e%extent/=0) then
                        call runtime_error('invalid scalar function call',lin,col); return
                    end if
                    k=prog%procedures(e%symbol)%result_symbol
                    if(k<1.or.k>prog%ns) then
                        call runtime_error('invalid scalar function result symbol',lin,col);return
                    end if
                    if(prog%symbols(k)%scope/=e%symbol.or.prog%symbols(k)%is_dummy.or. &
                       prog%symbols(k)%is_parameter.or.prog%symbols(k)%rank/=0.or. &
                       e%typ/=prog%symbols(k)%typ.or.e%real_kind/=prog%symbols(k)%real_kind) then
                        call runtime_error('invalid scalar function result metadata',lin,col);return
                    end if
                    if(prog%procedures(e%symbol)%is_pure) then
                        call invoke_procedure(e%symbol,e%args,lin,col,depth+1,v)
                    else
                        ! A scalar call broadcast over array elements is one
                        ! occurrence, not one random draw per element. Cache
                        ! lazily: KIND and empty unevaluated paths draw nothing.
                        if(.not.allocated(expression_cache(index)%values)) then
                            if(cached_elements>=max_array_elements) then
                                call runtime_error('impure result temporary element limit exceeded',lin,col);return
                            end if
                            call invoke_procedure(e%symbol,e%args,lin,col,depth+1,v)
                            if(diag%code/=0) return
                            allocate(expression_cache(index)%values(1))
                            expression_cache(index)%values(1)=v
                            cached_elements=cached_elements+1_int64
                        end if
                        v=expression_cache(index)%values(1)
                    end if
                end if
                if(diag%code/=0) return
                if(v%tag/=e%typ) call runtime_error('function result type mismatch',lin,col)
                if((v%tag==ty_real.or.v%tag==ty_integer).and.v%real_kind/=e%real_kind) &
                    call runtime_error('function result kind mismatch',lin,col)
            case(ex_call)
                if (.not.allocated(e%args)) then
                    call runtime_error('missing intrinsic arguments',lin,col)
                    return
                end if
                call validate_utility_intrinsic(index)
                if(diag%code/=0) return
                if(e%op=='selected_real_kind') then
                    ! Scalar evaluation does not necessarily call prepare_expression.
                    ! Validate the actual IR path before evaluating any argument.
                    if(e%rank/=0.or.e%extent/=0.or.e%typ/=ty_integer.or.e%real_kind/=4.or. &
                       e%intrinsic_mask<0.or.e%intrinsic_mask>7.or.size(e%args)>3) then
                        call runtime_error('invalid SELECTED_REAL_KIND metadata',lin,col);return
                    end if
                    if(popcnt(e%intrinsic_mask)/=size(e%args)) then
                        call runtime_error('invalid SELECTED_REAL_KIND slots',lin,col);return
                    end if
                    do k=1,size(e%args)
                        child=e%args(k)
                        if(.not.valid_expression(child)) return
                        if(prog%expressions(child)%typ/=ty_integer.or.prog%expressions(child)%rank/=0.or. &
                           (prog%expressions(child)%real_kind/=4.and.prog%expressions(child)%real_kind/=8)) then
                            call runtime_error('SELECTED_REAL_KIND needs scalar INTEGER kind 4 or 8',lin,col);return
                        end if
                    end do
                end if
                if(e%op=='associated') then
                    call associated_value(index,v);return
                end if
                if(e%op=='allocated') then
                    call allocated_value(index,v);return
                end if
                if(e%op=='present') then
                    call present_value(index,v)
                    return
                end if
                if(e%op=='len') then
                    call len_value(index,depth,v);return
                end if
                if(e%op=='new_line') then
                    call new_line_value(index,v);return
                end if
                if(is_numeric_model_inquiry(e%op)) then
                    call numeric_model_value(index,v);return
                end if
                if(e%op=='kind') then
                    call kind_value(index,v)
                    return
                end if
                if(e%op=='size') then
                    call inquiry_value(index,depth,v)
                    return
                end if
                if(is_array_transform(e%op)) then
                    call array_intrinsic_value(index,depth,v,position)
                    return
                end if
                allocate(argv(size(e%args)))
                do k=1,size(argv)
                    if(is_character_search_intrinsic(e%op).and.k==3.and.btest(e%intrinsic_mask,2)) then
                        if(absent_character_search_back(e%args(k))) then
                            argv(k)=value_t(tag=ty_logical,l=.false.);cycle
                        end if
                        if(diag%code/=0) return
                    end if
                    argv(k)=evaluate(e%args(k),depth+1,position)
                    if (diag%code/=0) return
                    if(e%op=='selected_real_kind') then
                        if(argv(k)%tag/=ty_integer.or.argv(k)%real_kind/=prog%expressions(e%args(k))%real_kind) then
                            call runtime_error('SELECTED_REAL_KIND argument value differs from type/kind metadata',lin,col)
                            return
                        end if
                    end if
                end do
                v=intrinsic_value(trim(e%op),argv,e%typ,lin,col,e%real_kind,e%intrinsic_mask)
                if(diag%code/=0) return
                if((e%op=='repeat'.or.e%op=='min'.or.e%op=='max').and.e%character_len>=0) then
                    if(.not.allocated(v%s)) then
                        call runtime_error('missing REPEAT result string',lin,col);return
                    end if
                    if(len(v%s)/=e%character_len) call runtime_error('REPEAT result length differs from cache',lin,col)
                end if
            case default
                call runtime_error('invalid expression opcode',lin,col)
            end select
            end associate
            if (diag%code/=0) return
            if (v%tag==ty_integer) then
                if (.not.check_integer(v%i,lin,col,v%real_kind)) return
            else if (v%tag==ty_real) then
                if(v%real_kind/=4.and.v%real_kind/=8) then
                    call runtime_error('unsupported REAL kind',lin,col); return
                end if
                if(v%real_kind==4) v%r=real(real(v%r,real32),real64)
                if (.not.ieee_is_finite(v%r)) call runtime_error('non-finite real result',lin,col)
            end if
        end function
        function checked_op(op,a,b,rk,lin,col) result(c)
            character,intent(in)::op
            integer(int64),intent(in)::a,b
            integer,intent(in)::rk,lin,col
            integer(int64)::c,lo,hi
            logical::ok
            lo=imin;hi=imax
            if(rk==8) then
                lo=min64;hi=max64
            end if
            c=0_int64;ok=.true.
            select case(op)
            case('+')
                if(b>0) ok=a<=hi-b
                if(b<0) ok=a>=lo-b
                if(ok) c=a+b
            case('-')
                if(b>0) ok=a>=lo+b
                if(b<0) ok=a<=hi+b
                if(ok) c=a-b
            case('*')
                if(a>0) then
                    if(b>0) ok=a<=hi/b
                    if(b<0) ok=b>=lo/a
                else if(a<0) then
                    if(b>0) ok=a>=lo/b
                    if(b<0) ok=a>=hi/b
                end if
                if(ok) c=a*b
            end select
            if(.not.ok) call runtime_error('integer overflow',lin,col)
        end function
        function binary(op,x,y,typ,lin,col,real_kind) result(v)
            character(*), intent(in) :: op
            type(value_t), intent(in) :: x,y
            integer, intent(in) :: typ,lin,col,real_kind
            type(value_t) :: v
            real(real64) :: xr,yr
            real(real32) :: xr4,yr4
            integer :: rk
            integer(int64) :: power,base,acc
            logical :: both_integer
            v%tag=typ; v%real_kind=real_kind
            rk=4
            if(x%tag==ty_real) rk=max(rk,x%real_kind)
            if(y%tag==ty_real) rk=max(rk,y%real_kind)
            if(typ==ty_real) rk=real_kind
            both_integer=x%tag==ty_integer .and. y%tag==ty_integer
            xr=0.0_real64
            yr=0.0_real64
            if (x%tag==ty_real) xr=x%r
            if (y%tag==ty_real) yr=y%r
            if (x%tag==ty_integer) xr=real(x%i,real64)
            if (y%tag==ty_integer) yr=real(y%i,real64)
            xr4=0.0_real32; yr4=0.0_real32
            if(rk==4) then
                xr4=real(xr,real32); yr4=real(yr,real32)
                xr=real(xr4,real64); yr=real(yr4,real64)
            end if
            select case(op)
            case('//')
                if(x%tag/=ty_character.or.y%tag/=ty_character.or. &
                   .not.allocated(x%s).or..not.allocated(y%s)) then
                    call runtime_error('Concatenation requires CHARACTER operands',lin,col);return
                end if
                if(len(x%s)>65536-len(y%s)) then
                    call runtime_error('CHARACTER concatenation length limit exceeded (65536)',lin,col);return
                end if
                v%tag=ty_character;v%s=x%s//y%s
            case('+','-','*','/','**')
                if (both_integer) then
                    select case(op)
                    case('+'); v%i=checked_op('+',x%i,y%i,real_kind,lin,col)
                    case('-'); v%i=checked_op('-',x%i,y%i,real_kind,lin,col)
                    case('*'); v%i=checked_op('*',x%i,y%i,real_kind,lin,col)
                    case('/')
                        if (y%i==0_int64) then
                            call runtime_error('integer division by zero',lin,col)
                            return
                        end if
                        if(x%i==min64.and.y%i==-1_int64) then
                            call runtime_error("integer overflow",lin,col); return
                        end if
                        v%i=x%i/y%i
                    case('**')
                        if (y%i<0_int64) then
                            if (x%i==0_int64) then
                                call runtime_error('zero raised to negative power',lin,col)
                                return
                            end if
                            v%i=0_int64
                            if (x%i==1_int64) v%i=1_int64
                            if (x%i==-1_int64) then
                                v%i=1_int64
                                if (mod(y%i,2_int64)/=0) v%i=-1_int64
                            end if
                        else
                            base=x%i
                            power=y%i
                            acc=1_int64
                            do while(power>0_int64)
                                if (mod(power,2_int64)/=0_int64) then
                                    acc=checked_op('*',acc,base,real_kind,lin,col)
                                    if (.not.check_integer(acc,lin,col,real_kind)) return
                                end if
                                power=power/2_int64
                                if (power>0_int64) then
                                    base=checked_op('*',base,base,real_kind,lin,col)
                                    if (.not.check_integer(base,lin,col,real_kind)) return
                                end if
                            end do
                            v%i=acc
                        end if
                    end select
                else
                    select case(op)
                    case('+')
                        if(rk==4) then
                            v%r=real(xr4+yr4,real64)
                        else
                            v%r=xr+yr
                        end if
                    case('-')
                        if(rk==4) then
                            v%r=real(xr4-yr4,real64)
                        else
                            v%r=xr-yr
                        end if
                    case('*')
                        if(rk==4) then
                            v%r=real(xr4*yr4,real64)
                        else
                            v%r=xr*yr
                        end if
                    case('/')
                        if (yr==0.0_real32) then
                            call runtime_error('real division by zero',lin,col)
                            return
                        end if
                        if(rk==4) then
                            v%r=real(xr4/yr4,real64)
                        else
                            v%r=xr/yr
                        end if
                    case('**')
                        if (xr==0.0_real32 .and. yr<0.0_real32) then
                            call runtime_error('zero raised to negative power',lin,col)
                            return
                        end if
                        if (y%tag==ty_integer) then
                            if(rk==4) then
                                v%r=real(xr4**y%i,real64)
                            else
                                v%r=xr**y%i
                            end if
                        else
                            if (xr<0.0_real32) then
                                call runtime_error('negative base with real exponent',lin,col)
                                return
                            end if
                            if(rk==4) then
                                v%r=real(xr4**yr4,real64)
                            else
                                v%r=xr**yr
                            end if
                        end if
                    end select
                end if
            case('==','.eq.')
                if(x%tag==ty_character.and.y%tag==ty_character) then
                    v%l=x%s==y%s
                else if (both_integer) then
                    v%l=x%i==y%i
                else
                    v%l=xr==yr
                end if
            case('/=','.ne.')
                if(x%tag==ty_character.and.y%tag==ty_character) then
                    v%l=x%s/=y%s
                else if (both_integer) then
                    v%l=x%i/=y%i
                else
                    v%l=xr/=yr
                end if
            case('<','.lt.')
                if(x%tag==ty_character.and.y%tag==ty_character) then
                    v%l=x%s<y%s
                else if (both_integer) then
                    v%l=x%i<y%i
                else
                    v%l=xr<yr
                end if
            case('<=','.le.')
                if(x%tag==ty_character.and.y%tag==ty_character) then
                    v%l=x%s<=y%s
                else if (both_integer) then
                    v%l=x%i<=y%i
                else
                    v%l=xr<=yr
                end if
            case('>','.gt.')
                if(x%tag==ty_character.and.y%tag==ty_character) then
                    v%l=x%s>y%s
                else if (both_integer) then
                    v%l=x%i>y%i
                else
                    v%l=xr>yr
                end if
            case('>=','.ge.')
                if(x%tag==ty_character.and.y%tag==ty_character) then
                    v%l=x%s>=y%s
                else if (both_integer) then
                    v%l=x%i>=y%i
                else
                    v%l=xr>=yr
                end if
            case('.and.'); v%l=x%l .and. y%l
            case('.or.'); v%l=x%l .or. y%l
            case('.eqv.'); v%l=x%l .eqv. y%l
            case('.neqv.'); v%l=x%l .neqv. y%l
            case default
                call runtime_error('invalid binary operator',lin,col)
            end select
        end function
        function intrinsic_value(name,args,typ,lin,col,real_kind,intrinsic_mask) result(v)
            character(*), intent(in) :: name
            type(value_t), intent(in) :: args(:)
            integer, intent(in) :: typ,lin,col,real_kind
            integer, intent(in), optional :: intrinsic_mask
            type(value_t) :: v
            integer :: j,k,slot,mask,bessel_n,bessel_arg,lex_a,lex_b,lex_order,selected_arg,longest
            logical :: back
            integer(int64) :: requirements(3)
            real(real32) :: x4,y4
            real(real64) :: special_x,degree_angle,degree_sign,degree_radians
            real(real64) :: scaled_x,scaled_z,scaled_delta
            v%tag=typ; v%real_kind=real_kind
            if (size(args)<1.and.name/='selected_real_kind') then
                call runtime_error('missing intrinsic argument',lin,col)
                return
            end if
            select case(name)
            case('iachar')
                if(size(args)>2.or.typ/=ty_integer.or.(real_kind/=4.and.real_kind/=8)) then
                    call runtime_error('invalid IACHAR result/arguments',lin,col);return
                end if
                if(args(1)%tag/=ty_character.or.args(1)%real_kind/=4.or..not.allocated(args(1)%s)) then
                    call runtime_error('IACHAR requires default CHARACTER C',lin,col);return
                end if
                if(len(args(1)%s)/=1) then
                    call runtime_error('IACHAR C must have length one',lin,col);return
                end if
                if(size(args)==2) then
                    if(args(2)%tag/=ty_integer.or.args(2)%i/=real_kind) then
                        call runtime_error('IACHAR KIND differs from result',lin,col);return
                    end if
                end if
                v%i=int(iachar(args(1)%s),int64)
                if(v%i<0.or.v%i>127)call runtime_error('IACHAR code outside supported ASCII range (0:127)',lin,col)
            case('fraction','exponent','set_exponent')
                k=1
                if(name=='set_exponent')k=2
                if(size(args)/=k.or.args(1)%tag/=ty_real.or.(args(1)%real_kind/=4.and.args(1)%real_kind/=8)) then
                    call runtime_error('model decomposition requires REAL4/8 X',lin,col);return
                end if
                if(name=='exponent') then
                    if(typ/=ty_integer.or.real_kind/=4) then
                        call runtime_error('EXPONENT result must be default INTEGER',lin,col);return
                    end if
                else if(typ/=ty_real.or.real_kind/=args(1)%real_kind) then
                    call runtime_error('model decomposition result kind differs',lin,col);return
                end if
                if(.not.ieee_is_finite(args(1)%r)) then
                    call runtime_error('non-finite model decomposition argument',lin,col);return
                end if
                if(name=='fraction') then
                    if(real_kind==4) then
                        v%r=real(fraction(real(args(1)%r,real32)),real64)
                    else
                        v%r=fraction(args(1)%r)
                    end if
                else if(name=='exponent') then
                    if(args(1)%real_kind==4) then
                        v%i=int(exponent(real(args(1)%r,real32)),int64)
                    else
                        v%i=int(exponent(args(1)%r),int64)
                    end if
                else
                    if(args(2)%tag/=ty_integer.or.(args(2)%real_kind/=4.and.args(2)%real_kind/=8)) then
                        call runtime_error('SET_EXPONENT I must be INTEGER4/8',lin,col);return
                    end if
                    if(.not.check_integer(args(2)%i,lin,col,args(2)%real_kind))return
                    ! Range checks precede narrowing a potentially INTEGER(8) I.
                    ! Zero remains zero at any exponent; gradual underflow is
                    ! delegated to the host only in its safely bounded range.
                    if(args(1)%r==0.0_real64) then
                        v%r=args(1)%r;return
                    end if
                    k=1024;slot=-1074
                    if(real_kind==4) then
                        k=128;slot=-149
                    end if
                    if(args(2)%i>int(k,int64)) then
                        call runtime_error('SET_EXPONENT result overflows supported REAL kind',lin,col);return
                    end if
                    if(args(2)%i<int(slot,int64)) then
                        v%r=sign(0.0_real64,args(1)%r);return
                    end if
                    if(real_kind==4) then
                        v%r=real(set_exponent(real(args(1)%r,real32),int(args(2)%i)),real64)
                    else
                        v%r=set_exponent(args(1)%r,int(args(2)%i))
                    end if
                end if
            case('char','achar')
                if(size(args)>2.or.args(1)%tag/=ty_integer.or.typ/=ty_character.or.real_kind/=4) then
                    call runtime_error('invalid CHAR/ACHAR arguments',lin,col);return
                end if
                if(size(args)==2) then
                    if(args(2)%tag/=ty_integer.or.args(2)%i/=1_int64) then
                        call runtime_error('CHAR/ACHAR support default CHARACTER kind 1 only',lin,col);return
                    end if
                end if
                ! The supported default character set is deliberately ASCII.
                ! Reject out-of-range values rather than host-dependent wrapping.
                if(args(1)%i<0_int64.or.args(1)%i>127_int64) then
                    call runtime_error('CHAR/ACHAR code outside supported ASCII range (0:127)',lin,col);return
                end if
                v%tag=ty_character
                if(name=='achar') then
                    v%s=achar(int(args(1)%i))
                else
                    v%s=char(int(args(1)%i))
                end if
            case('iand','ior','ieor','not','btest','leadz','trailz','shiftr')
                slot=2
                if(name=='not'.or.(name=='leadz'.or.name=='trailz'))slot=1
                if(size(args)/=slot)then
                    call runtime_error('invalid bit intrinsic value count',lin,col);return
                end if
                do j=1,slot
                    if(args(j)%tag/=ty_integer.or.(args(j)%real_kind/=4.and.args(j)%real_kind/=8))then
                        call runtime_error('bit intrinsic requires INTEGER values',lin,col);return
                    end if
                    if(.not.check_integer(args(j)%i,lin,col,args(j)%real_kind))return
                    if(name/='btest'.and.(name/='leadz'.and.name/='trailz').and.name/='shiftr'.and.args(j)%real_kind/=real_kind)then
                        call runtime_error('bit intrinsic value kind differs',lin,col);return
                    end if
                end do
                if(name=='shiftr')then
                    if(typ/=ty_integer.or.real_kind/=args(1)%real_kind)then
                        call runtime_error('invalid SHIFTR result type/kind',lin,col);return
                    end if
                    if(args(2)%i<0_int64.or.args(2)%i>8_int64*real_kind)then
                        call runtime_error('SHIFTR SHIFT outside bit width',lin,col);return
                    end if
                    if(real_kind==4)then
                        v%i=int(shiftr(int(args(1)%i,int32),int(args(2)%i)),int64)
                    else
                        v%i=shiftr(args(1)%i,int(args(2)%i))
                    end if
                    return
                end if
                if((name=='leadz'.or.name=='trailz'))then
                    if(typ/=ty_integer.or.real_kind/=4)then
                        if(name=='trailz')then
                            call runtime_error('invalid TRAILZ result type/kind',lin,col)
                        else
                            call runtime_error('invalid LEADZ result type/kind',lin,col)
                        end if
                        return
                    end if
                    ! These are value operations, not BIT_SIZE metadata inquiries.
                    ! Check before narrowing. Zero yields the declared bit width;
                    ! the result is default INTEGER for either operand kind.
                    if(name=='trailz')then
                        if(args(1)%real_kind==4)then
                            v%i=int(trailz(int(args(1)%i,int32)),int64)
                        else
                            v%i=int(trailz(args(1)%i),int64)
                        end if
                    else
                        if(args(1)%real_kind==4)then
                            v%i=int(leadz(int(args(1)%i,int32)),int64)
                        else
                            v%i=int(leadz(args(1)%i),int64)
                        end if
                    end if
                    return
                end if
                if(name=='btest')then
                    if(typ/=ty_logical.or.real_kind/=4)then
                        call runtime_error('invalid BTEST result type/kind',lin,col);return
                    end if
                    if(args(2)%i<0_int64.or.args(2)%i>=8_int64*args(1)%real_kind)then
                        call runtime_error('BTEST POS outside bit width',lin,col);return
                    end if
                    v%l=btest(args(1)%i,int(args(2)%i));return
                end if
                if(typ/=ty_integer)then
                    call runtime_error('invalid bit intrinsic result type',lin,col);return
                end if
                ! Apply operations at the declared width, then sign extend.
                ! No conversion passes through REAL and no signed arithmetic
                ! is used to create or negate the high-bit representation.
                if(real_kind==4)then
                    select case(name)
                    case('iand');v%i=int(iand(int(args(1)%i,int32),int(args(2)%i,int32)),int64)
                    case('ior');v%i=int(ior(int(args(1)%i,int32),int(args(2)%i,int32)),int64)
                    case('ieor');v%i=int(ieor(int(args(1)%i,int32),int(args(2)%i,int32)),int64)
                    case('not');v%i=int(not(int(args(1)%i,int32)),int64)
                    end select
                else
                    select case(name)
                    case('iand');v%i=iand(args(1)%i,args(2)%i)
                    case('ior');v%i=ior(args(1)%i,args(2)%i)
                    case('ieor');v%i=ieor(args(1)%i,args(2)%i)
                    case('not');v%i=not(args(1)%i)
                    end select
                end if

            case('maskl','maskr')
                if(size(args)<1.or.size(args)>2.or.typ/=ty_integer.or.(real_kind/=4.and.real_kind/=8))then
                    call runtime_error('invalid MASKL/MASKR result/arguments',lin,col);return
                end if
                do j=1,size(args)
                    if(args(j)%tag/=ty_integer.or.(args(j)%real_kind/=4.and.args(j)%real_kind/=8))then
                        call runtime_error('MASKL/MASKR require INTEGER values',lin,col);return
                    end if
                    if(.not.check_integer(args(j)%i,lin,col,args(j)%real_kind))return
                end do
                if(size(args)==1)then
                    if(real_kind/=4)then
                        call runtime_error('MASKL/MASKR default result KIND differs',lin,col);return
                    end if
                else
                    if(args(2)%i/=real_kind)then
                        call runtime_error('MASKL/MASKR KIND differs from result',lin,col);return
                    end if
                end if
                if(args(1)%i<0_int64.or.args(1)%i>8_int64*real_kind)then
                    call runtime_error('MASKL/MASKR I outside result bit width',lin,col);return
                end if
                ! Count bounds are checked before conversion or host bit operations.
                ! Host KIND is a compile-time constant; zero/full-width are defined.
                if(real_kind==4)then
                    if(name=='maskl')then
                        v%i=int(maskl(int(args(1)%i),kind=int32),int64)
                    else
                        v%i=int(maskr(int(args(1)%i),kind=int32),int64)
                    end if
                else
                    if(name=='maskl')then
                        v%i=maskl(int(args(1)%i),kind=int64)
                    else
                        v%i=maskr(int(args(1)%i),kind=int64)
                    end if
                end if

            case('lge','lgt','lle','llt')
                if(size(args)/=2.or.typ/=ty_logical.or.real_kind/=4) then
                    call runtime_error('invalid lexical comparison result/values',lin,col);return
                end if
                do j=1,2
                    if(args(j)%tag/=ty_character.or.args(j)%real_kind/=4.or..not.allocated(args(j)%s)) then
                        call runtime_error('lexical comparison requires default CHARACTER values',lin,col);return
                    end if
                    if(len(args(j)%s)>65536) then
                        call runtime_error('lexical comparison CHARACTER length limit exceeded',lin,col);return
                    end if
                end do
                lex_order=0
                do j=1,max(len(args(1)%s),len(args(2)%s))
                    call consume(lin,col)
                    if(diag%code/=0)return
                    lex_a=32;lex_b=32
                    if(j<=len(args(1)%s))lex_a=iachar(args(1)%s(j:j))
                    if(j<=len(args(2)%s))lex_b=iachar(args(2)%s(j:j))
                    if(lex_a<0.or.lex_a>127.or.lex_b<0.or.lex_b>127) then
                        call runtime_error('lexical comparison supports ASCII characters (0:127)',lin,col);return
                    end if
                    ! Continue validating the full strings after the first
                    ! difference; pad absent characters with ASCII blank.
                    if(lex_order==0.and.lex_a<lex_b)lex_order=-1
                    if(lex_order==0.and.lex_a>lex_b)lex_order=1
                end do
                select case(name)
                case('lge');v%l=lex_order>=0
                case('lgt');v%l=lex_order>0
                case('lle');v%l=lex_order<=0
                case('llt');v%l=lex_order<0
                end select
            case('index','scan','verify','len_trim','adjustl','adjustr')
                if(args(1)%tag/=ty_character.or..not.allocated(args(1)%s)) then
                    call runtime_error('character intrinsic requires CHARACTER values',lin,col);return
                end if
                select case(name)
                case('index','scan','verify')
                    if(size(args)<2.or.size(args)>4) then
                        call runtime_error('invalid character search values',lin,col);return
                    end if
                    if(args(2)%tag/=ty_character.or..not.allocated(args(2)%s)) then
                        call runtime_error('Character search SUBSTRING/SET must be CHARACTER',lin,col);return
                    end if
                    back=.false.
                    if(present(intrinsic_mask)) then
                        if(btest(intrinsic_mask,2)) then
                            if(size(args)<3) then
                                call runtime_error('missing Character search BACK value',lin,col);return
                            end if
                            if(args(3)%tag/=ty_logical) then
                                call runtime_error('Character search BACK must be LOGICAL',lin,col);return
                            end if
                            back=args(3)%l
                        end if
                    end if
                    select case(name)
                    case('index');v%i=int(index(args(1)%s,args(2)%s,back=back),int64)
                    case('scan');v%i=int(scan(args(1)%s,args(2)%s,back=back),int64)
                    case('verify');v%i=int(verify(args(1)%s,args(2)%s,back=back),int64)
                    end select
                case('len_trim');v%i=int(len_trim(args(1)%s),int64)
                case('adjustl');v%s=adjustl(args(1)%s)
                case('adjustr');v%s=adjustr(args(1)%s)
                end select
            case('repeat')
                if(size(args)/=2.or.typ/=ty_character.or.real_kind/=4) then
                    call runtime_error('invalid REPEAT result/arguments',lin,col);return
                end if
                if(args(1)%tag/=ty_character.or..not.allocated(args(1)%s).or.args(2)%tag/=ty_integer) then
                    call runtime_error('invalid REPEAT values',lin,col);return
                end if
                k=repeat_result_length(len(args(1)%s),args(2)%i,lin,col)
                if(diag%code/=0) return
                if(k==0) then
                    v%s=''
                else
                    v%s=repeat(args(1)%s,int(args(2)%i))
                end if
            case('trim')
                if(size(args)/=1.or.args(1)%tag/=ty_character.or..not.allocated(args(1)%s)) then
                    call runtime_error('TRIM requires scalar CHARACTER',lin,col);return
                end if
                v%tag=ty_character;v%s=trim(args(1)%s)
            case('selected_real_kind')
                mask=-1
                if(present(intrinsic_mask)) mask=intrinsic_mask
                if(mask<0.or.mask>7.or.size(args)>3.or.typ/=ty_integer.or.real_kind/=4) then
                    call runtime_error('invalid SELECTED_REAL_KIND metadata',lin,col);return
                end if
                if(popcnt(mask)/=size(args)) then
                    call runtime_error('invalid SELECTED_REAL_KIND slots',lin,col);return
                end if
                requirements=[0_int64,0_int64,2_int64];k=0
                do slot=1,3
                    if(.not.btest(mask,slot-1)) cycle
                    k=k+1
                    if(args(k)%tag/=ty_integer) then
                        call runtime_error('SELECTED_REAL_KIND requires scalar INTEGER',lin,col);return
                    end if
                    requirements(slot)=args(k)%i
                end do
                if(requirements(3)/=2_int64) then
                    v%i=-5_int64
                else if(requirements(1)<=6_int64.and.requirements(2)<=37_int64) then
                    v%i=4_int64
                else if(requirements(1)<=15_int64.and.requirements(2)<=307_int64) then
                    v%i=8_int64
                else if(requirements(1)>15_int64.and.requirements(2)>307_int64) then
                    v%i=-3_int64
                else if(requirements(1)>15_int64) then
                    v%i=-1_int64
                else
                    v%i=-2_int64
                end if
            case('selected_int_kind')
                if(size(args)/=1.or.args(1)%tag/=ty_integer) then
                    call runtime_error('SELECTED_INT_KIND requires one INTEGER',lin,col);return
                end if
                v%i=-1_int64
                if(args(1)%i<=18) v%i=8_int64
                if(args(1)%i<=9) v%i=4_int64
            case('int')
                if(size(args)<1.or.size(args)>2) then
                    call runtime_error('INT requires one or two arguments',lin,col);return
                end if
                if(size(args)==2) then
                    if(args(2)%tag/=ty_integer.or.args(2)%i/=real_kind) then
                        call runtime_error('INT kind argument differs from result kind',lin,col);return
                    end if
                else if(real_kind/=4) then
                    call runtime_error('INT default result kind differs',lin,col);return
                end if
                v=convert(args(1),ty_integer,lin,col,real_kind)
            case('nint','floor','ceiling')
                if(size(args)>2.or.args(1)%tag/=ty_real.or.typ/=ty_integer.or. &
                   (args(1)%real_kind/=4.and.args(1)%real_kind/=8)) then
                    call runtime_error('rounding intrinsic requires REAL argument',lin,col);return
                end if
                if(size(args)==2) then
                    if(args(2)%tag/=ty_integer.or.args(2)%i/=real_kind) then
                        call runtime_error('rounding KIND differs from result',lin,col);return
                    end if
                else if(real_kind/=4) then
                    call runtime_error('rounding default result kind differs',lin,col);return
                end if
                if(.not.ieee_is_finite(args(1)%r)) then
                    call runtime_error('non-finite rounding argument',lin,col);return
                end if
                ! Round in REAL(8), before any integer conversion. This avoids
                ! host integer overflow and preserves the full REAL(4) value.
                v=args(1)
                select case(name)
                case('nint')
                    v%r=anint(v%r)
                case('floor')
                    v%r=aint(v%r)
                    if(v%r>args(1)%r) v%r=v%r-1.0_real64
                case('ceiling')
                    v%r=aint(v%r)
                    if(v%r<args(1)%r) v%r=v%r+1.0_real64
                end select
                v=convert(v,ty_integer,lin,col,real_kind)
            case('merge')
                if(size(args)/=3) then
                    call runtime_error('MERGE requires three arguments',lin,col);return
                end if
                if(typ<ty_integer.or.typ>ty_character.or.args(1)%tag/=typ.or.args(2)%tag/=typ.or. &
                   args(1)%real_kind/=real_kind.or.args(2)%real_kind/=real_kind.or.args(3)%tag/=ty_logical) then
                    call runtime_error('MERGE source type/kind or MASK differs',lin,col);return
                end if
                if(typ==ty_character) then
                    if(.not.allocated(args(1)%s).or..not.allocated(args(2)%s)) then
                        call runtime_error('MERGE CHARACTER source missing',lin,col);return
                    end if
                    if(len(args(1)%s)/=len(args(2)%s)) then
                        call runtime_error('MERGE CHARACTER source lengths must match',lin,col);return
                    end if
                end if
                v=args(2)
                if(args(3)%l) v=args(1)
            case('dble')
                if(size(args)/=1.or.typ/=ty_real.or.real_kind/=8.or. &
                   (args(1)%tag/=ty_integer.and.args(1)%tag/=ty_real)) then
                    call runtime_error('DBLE requires numeric argument and REAL(8) result',lin,col);return
                end if
                v=convert(args(1),ty_real,lin,col,8)
            case('real')
                if(size(args)<1.or.size(args)>2.or.typ/=ty_real.or.(real_kind/=4.and.real_kind/=8).or. &
                   (args(1)%tag/=ty_integer.and.args(1)%tag/=ty_real).or. &
                   (args(1)%real_kind/=4.and.args(1)%real_kind/=8)) then
                    call runtime_error('REAL requires numeric A and REAL4/8 result',lin,col);return
                end if
                if(size(args)==2) then
                    if(args(2)%tag/=ty_integer.or.args(2)%i/=real_kind) then
                        call runtime_error('REAL KIND differs from result kind',lin,col);return
                    end if
                else if(real_kind/=4) then
                    call runtime_error('REAL default result kind differs',lin,col);return
                end if
                if(args(1)%tag==ty_integer.and.real_kind==4) then
                    ! Convert directly to binary32: widening INTEGER8 through
                    ! binary64 first can double-round values near halfway.
                    v=value_t(tag=ty_real,real_kind=4,r=real(real(args(1)%i,real32),real64))
                else
                    v=convert(args(1),ty_real,lin,col,real_kind)
                end if
            case('dprod')
                if(size(args)/=2.or.typ/=ty_real.or.real_kind/=8) then
                    call runtime_error('DPROD requires two operands and REAL8 result',lin,col);return
                end if
                do k=1,2
                    if(args(k)%tag/=ty_real.or.args(k)%real_kind/=4) then
                        call runtime_error('DPROD requires default REAL kind 4 operands',lin,col);return
                    end if
                    if(.not.ieee_is_finite(args(k)%r)) then
                        call runtime_error('non-finite DPROD argument',lin,col);return
                    end if
                    if(abs(args(k)%r)>real(huge(0.0_real32),real64)) then
                        call runtime_error('DPROD operand exceeds REAL4 range',lin,col);return
                    end if
                end do
                ! Widen both represented REAL4 operands before multiplication.
                ! Even the largest finite REAL4 product fits safely in REAL8.
                v%r=real(real(args(1)%r,real32),real64)*real(real(args(2)%r,real32),real64)
            case('tand')
                if(size(args)/=1.or.typ/=ty_real.or.(real_kind/=4.and.real_kind/=8)) then
                    call runtime_error('TAND requires one REAL4/8 operand',lin,col);return
                end if
                if(args(1)%tag/=ty_real.or.args(1)%real_kind/=real_kind) then
                    call runtime_error('TAND operand/result kind differs',lin,col);return
                end if
                special_x=args(1)%r
                if(.not.ieee_is_finite(special_x)) then
                    call runtime_error('non-finite TAND argument',lin,col);return
                end if
                if(abs(special_x)>1048576.0_real64) then
                    call runtime_error('TAND X magnitude exceeds supported limit 1048576',lin,col);return
                end if
                if(real_kind==4)special_x=real(real(special_x,real32),real64)
                degree_sign=sign(1.0_real64,special_x)
                degree_angle=modulo(abs(special_x),180.0_real64)
                if(degree_angle==90.0_real64) then
                    call runtime_error('TAND is singular at odd multiples of 90 degrees',lin,col);return
                end if
                if(degree_angle>90.0_real64)degree_angle=degree_angle-180.0_real64
                if(degree_angle==0.0_real64) then
                    v%r=sign(0.0_real64,special_x)
                else if(abs(degree_angle)==45.0_real64) then
                    v%r=degree_sign*sign(1.0_real64,degree_angle)
                else
                    ! Reduce before radians conversion. Near poles use the
                    ! complementary angle, avoiding subtraction from pi/2.
                    degree_radians=acos(-1.0_real64)/180.0_real64
                    if(abs(degree_angle)>45.0_real64) then
                        v%r=degree_sign*sign(1.0_real64/tan((90.0_real64-abs(degree_angle))*degree_radians),degree_angle)
                    else
                        v%r=degree_sign*tan(degree_angle*degree_radians)
                    end if
                end if
                if(.not.ieee_is_finite(v%r)) then
                    call runtime_error('non-finite TAND result',lin,col);return
                end if
                if(real_kind==4)v%r=real(real(v%r,real32),real64)
            case('asin','atan','atan2')
                if(size(args)<1.or.size(args)>2.or.(name=='asin'.and.size(args)/=1).or. &
                   (name=='atan2'.and.size(args)/=2).or.typ/=ty_real.or.(real_kind/=4.and.real_kind/=8)) then
                    call runtime_error('invalid inverse trig count/result type',lin,col);return
                end if
                do j=1,size(args)
                    if(args(j)%tag/=ty_real.or.args(j)%real_kind/=real_kind) then
                        call runtime_error('inverse trig requires matching REAL4/8 operands',lin,col);return
                    end if
                    if(.not.ieee_is_finite(args(j)%r)) then
                        call runtime_error('non-finite inverse trig argument',lin,col);return
                    end if
                end do
                if(name=='asin'.and.abs(args(1)%r)>1.0_real64) then
                    call runtime_error('ASIN requires -1 <= X <= 1',lin,col);return
                end if
                if(size(args)==2) then
                    if(args(1)%r==0.0_real64.and.args(2)%r==0.0_real64) then
                        call runtime_error('ATAN/ATAN2 require X or Y to be nonzero',lin,col);return
                    end if
                    if(real_kind==4) then
                        v%r=real(atan2(real(args(1)%r,real32),real(args(2)%r,real32)),real64)
                    else
                        v%r=atan2(args(1)%r,args(2)%r)
                    end if
                else if(name=='asin') then
                    if(real_kind==4) then
                        v%r=real(asin(real(args(1)%r,real32)),real64)
                    else
                        v%r=asin(args(1)%r)
                    end if
                else
                    if(real_kind==4) then
                        v%r=real(atan(real(args(1)%r,real32)),real64)
                    else
                        v%r=atan(args(1)%r)
                    end if
                end if
            case('acosd','asind','sind','cosd')
                if(size(args)/=1.or.typ/=ty_real.or.(real_kind/=4.and.real_kind/=8)) then
                    call runtime_error('degree trig requires one REAL4/8 operand',lin,col);return
                end if
                if(args(1)%tag/=ty_real.or.args(1)%real_kind/=real_kind) then
                    call runtime_error('degree trig operand/result kind differs',lin,col);return
                end if
                special_x=args(1)%r
                if(.not.ieee_is_finite(special_x)) then
                    call runtime_error('non-finite degree trig argument',lin,col);return
                end if
                if((name=='acosd'.or.name=='asind').and.abs(special_x)>1.0_real64) then
                    call runtime_error('ACOSD/ASIND require -1 <= X <= 1',lin,col);return
                end if
                if(real_kind==4) then
                    if(abs(special_x)>real(huge(0.0_real32),real64)) then
                        call runtime_error('degree trig operand exceeds REAL4 range',lin,col);return
                    end if
                    special_x=real(real(special_x,real32),real64)
                end if
                if(name=='acosd'.or.name=='asind') then
                    if(real_kind==4) then
                        x4=real(special_x,real32)
                        if(name=='acosd')v%r=real(acos(x4)*(180.0_real32/acos(-1.0_real32)),real64)
                        if(name=='asind')v%r=real(asin(x4)*(180.0_real32/acos(-1.0_real32)),real64)
                    else
                        if(name=='acosd')v%r=acos(special_x)*(180.0_real64/acos(-1.0_real64))
                        if(name=='asind')v%r=asin(special_x)*(180.0_real64/acos(-1.0_real64))
                    end if
                else
                    ! Reduce the represented finite argument before multiplying
                    ! by pi/180. ABS and MOD avoid cancellation of tiny negative
                    ! inputs; complements avoid loss near exact quarter turns.
                    degree_angle=mod(abs(special_x),360.0_real64)
                    degree_sign=1.0_real64
                    if(name=='sind') then
                        degree_sign=sign(1.0_real64,special_x)
                        if(degree_angle>=180.0_real64) then
                            degree_angle=degree_angle-180.0_real64
                            degree_sign=-degree_sign
                        end if
                        if(degree_angle>90.0_real64)degree_angle=180.0_real64-degree_angle
                    else
                        if(degree_angle>180.0_real64)degree_angle=360.0_real64-degree_angle
                        if(degree_angle>90.0_real64) then
                            degree_angle=180.0_real64-degree_angle
                            degree_sign=-1.0_real64
                        end if
                        degree_angle=90.0_real64-degree_angle
                    end if
                    degree_radians=acos(-1.0_real64)/180.0_real64
                    if(degree_angle==0.0_real64) then
                        v%r=degree_sign*0.0_real64
                    else if(degree_angle==30.0_real64) then
                        v%r=degree_sign*0.5_real64
                    else if(degree_angle==90.0_real64) then
                        v%r=degree_sign
                    else if(degree_angle>45.0_real64) then
                        v%r=degree_sign*cos((90.0_real64-degree_angle)*degree_radians)
                    else
                        v%r=degree_sign*sin(degree_angle*degree_radians)
                    end if
                    if(real_kind==4)v%r=real(real(v%r,real32),real64)
                end if
            case('rrspacing')
                if(size(args)/=1.or.typ/=ty_real.or.(real_kind/=4.and.real_kind/=8)) then
                    call runtime_error('RRSPACING requires one REAL4/8 operand',lin,col);return
                end if
                if(args(1)%tag/=ty_real.or.args(1)%real_kind/=real_kind) then
                    call runtime_error('RRSPACING operand/result kind differs',lin,col);return
                end if
                if(.not.ieee_is_finite(args(1)%r)) then
                    call runtime_error('non-finite RRSPACING argument',lin,col);return
                end if
                if(real_kind==4) then
                    if(abs(args(1)%r)>real(huge(0.0_real32),real64)) then
                        call runtime_error('RRSPACING operand exceeds REAL4 range',lin,col);return
                    end if
                    x4=real(args(1)%r,real32)
                    v%r=real(scale(abs(fraction(x4)),digits(x4)),real64)
                else
                    v%r=scale(abs(fraction(args(1)%r)),digits(args(1)%r))
                end if
            case('acos')
                if(size(args)/=1.or.typ/=ty_real.or.(real_kind/=4.and.real_kind/=8)) then
                    call runtime_error('ACOS requires one REAL4/8 operand',lin,col);return
                end if
                if(args(1)%tag/=ty_real.or.args(1)%real_kind/=real_kind) then
                    call runtime_error('ACOS operand/result kind differs',lin,col);return
                end if
                if(.not.ieee_is_finite(args(1)%r)) then
                    call runtime_error('non-finite ACOS argument',lin,col);return
                end if
                if(abs(args(1)%r)>1.0_real64) then
                    call runtime_error('ACOS requires -1 <= X <= 1',lin,col);return
                end if
                if(real_kind==4) then
                    v%r=real(acos(real(args(1)%r,real32)),real64)
                else
                    v%r=acos(args(1)%r)
                end if
            case('aint','anint','asinh','acosh')
                if(size(args)>2.or.typ/=ty_real.or.(real_kind/=4.and.real_kind/=8).or. &
                   ((name=='asinh'.or.name=='acosh').and.size(args)/=1).or. &
                   args(1)%tag/=ty_real.or.(args(1)%real_kind/=4.and.args(1)%real_kind/=8)) then
                    call runtime_error('invalid real rounding/inverse values',lin,col);return
                end if
                if(size(args)==2) then
                    if(args(2)%tag/=ty_integer.or.args(2)%i/=real_kind) then
                        call runtime_error('AINT/ANINT KIND differs from result',lin,col);return
                    end if
                else if(real_kind/=args(1)%real_kind) then
                    call runtime_error('real rounding/inverse default kind differs',lin,col);return
                end if
                if(.not.ieee_is_finite(args(1)%r)) then
                    call runtime_error('non-finite real rounding/inverse argument',lin,col);return
                end if
                if(name=='acosh'.and.args(1)%r<1.0_real64) then
                    call runtime_error('ACOSH requires X >= 1',lin,col);return
                end if
                ! Round at the input kind before converting to the selected
                ! result kind. No host INTEGER conversion is involved.
                if(args(1)%real_kind==4) then
                    x4=real(args(1)%r,real32)
                    select case(name)
                    case('aint');v%r=real(aint(x4),real64)
                    case('anint');v%r=real(anint(x4),real64)
                    case('asinh');v%r=real(asinh(x4),real64)
                    case('acosh');v%r=real(acosh(x4),real64)
                    end select
                else
                    select case(name)
                    case('aint');v%r=aint(args(1)%r)
                    case('anint');v%r=anint(args(1)%r)
                    case('asinh');v%r=asinh(args(1)%r)
                    case('acosh');v%r=acosh(args(1)%r)
                    end select
                end if
                if(real_kind==4) then
                    if(abs(v%r)>real(huge(0.0_real32),real64)) then
                        call runtime_error('AINT/ANINT result overflows REAL kind 4',lin,col);return
                    end if
                    v%r=real(real(v%r,real32),real64)
                end if
                if(.not.ieee_is_finite(v%r))call runtime_error('non-finite real rounding/inverse result',lin,col)
            case('erf','bessel_j0','bessel_j1','bessel_jn','bessel_y0','bessel_y1','bessel_yn')
                bessel_arg=1;bessel_n=0
                if(name=='bessel_jn'.or.name=='bessel_yn') bessel_arg=2
                if(size(args)/=bessel_arg.or.typ/=ty_real.or.(real_kind/=4.and.real_kind/=8)) then
                    call runtime_error('invalid ERF/Bessel result values',lin,col);return
                end if
                if(args(bessel_arg)%tag/=ty_real.or.args(bessel_arg)%real_kind/=real_kind) then
                    call runtime_error('ERF/Bessel X requires matching REAL kind 4 or 8',lin,col);return
                end if
                if(bessel_arg==2) then
                    if(args(1)%tag/=ty_integer.or.(args(1)%real_kind/=4.and.args(1)%real_kind/=8)) then
                        call runtime_error('Bessel N requires INTEGER kind 4 or 8',lin,col);return
                    end if
                    ! Bound before default-INTEGER narrowing and host recurrences.
                    if(args(1)%i<0_int64.or.args(1)%i>32_int64) then
                        call runtime_error('Bessel N outside supported range 0 to 32',lin,col);return
                    end if
                    bessel_n=int(args(1)%i)
                end if
                special_x=args(bessel_arg)%r
                if(.not.ieee_is_finite(special_x)) then
                    call runtime_error('non-finite ERF/Bessel argument',lin,col);return
                end if
                if(name/='erf') then
                    if(abs(special_x)>1048576.0_real64) then
                        call runtime_error('Bessel X magnitude exceeds supported limit 1048576',lin,col);return
                    end if
                    if(name=='bessel_y0'.or.name=='bessel_y1'.or.name=='bessel_yn') then
                        ! Positive lower bound and N<=32 keep the REAL64 host
                        ! recurrence finite, even when the REAL4 result overflows.
                        ! In particular, Y0(0) is singular and is never evaluated.
                        if(special_x<0.00000095367431640625_real64) then
                            call runtime_error('Bessel Y requires X >= 2**(-20)',lin,col);return
                        end if
                    end if
                end if
                ! Widen REAL4 input exactly. Compute in REAL64 and round once;
                ! this also permits a checked REAL4 overflow without host traps.
                select case(name)
                case('erf');v%r=erf(special_x)
                case('bessel_j0');v%r=bessel_j0(special_x)
                case('bessel_j1');v%r=bessel_j1(special_x)
                case('bessel_jn');v%r=bessel_jn(bessel_n,special_x)
                case('bessel_y0');v%r=bessel_y0(special_x)
                case('bessel_y1');v%r=bessel_y1(special_x)
                case('bessel_yn');v%r=bessel_yn(bessel_n,special_x)
                end select
                if(.not.ieee_is_finite(v%r)) then
                    call runtime_error('non-finite ERF/Bessel result',lin,col);return
                end if
                if(real_kind==4) then
                    if(abs(v%r)>real(huge(0.0_real32),real64)) then
                        call runtime_error('ERF/Bessel result exceeds REAL4 finite range',lin,col);return
                    end if
                    v%r=real(real(v%r,real32),real64)
                end if

            case('erfc_scaled')
                if(size(args)/=1.or.typ/=ty_real.or.(real_kind/=4.and.real_kind/=8)) then
                    call runtime_error('invalid ERFC_SCALED result values',lin,col);return
                end if
                if(args(1)%tag/=ty_real.or.args(1)%real_kind/=real_kind) then
                    call runtime_error('ERFC_SCALED requires matching REAL kind 4 or 8',lin,col);return
                end if
                if(.not.ieee_is_finite(args(1)%r)) then
                    call runtime_error('non-finite ERFC_SCALED argument',lin,col);return
                end if
                ! Last binary32/binary64 negative arguments whose scaled result
                ! fits that kind. Verified independently at100 decimal digits;
                ! the next negative representable neighbor overflows. Check
                ! before host evaluation, avoiding square/EXP overflow entirely.
                scaled_x=args(1)%r
                if((real_kind==4.and.scaled_x< -9.3824138641357421875_real64).or. &
                   (real_kind==8.and.scaled_x< -26.628735713751489_real64)) then
                    call runtime_error('ERFC_SCALED finite result range exceeded',lin,col);return
                end if
                if(scaled_x>=1.0e8_real64) then
                    ! erfcx(x)=1/(sqrt(pi)*x)*(1-1/(2*x*x)+...). The
                    ! omitted relative correction is at most5e-17 here. Divide
                    ! the constant by x, never multiply x by sqrt(pi): retain
                    ! positive subnormal results all the way to HUGE(REAL64).
                    v%r=0.564189583547756286948079451560772586_real64/scaled_x
                else if(scaled_x< -1.0_real64) then
                    ! Reflection erfcx(-y)=2*exp(y*y)-erfcx(y). Split y on
                    ! a1/16 grid: z*z is exact over this guarded domain, and
                    ! delta retains the small residual without squaring y.
                    ! This avoids the host's premature negative overflow cutoff.
                    scaled_z=aint(abs(scaled_x)*16.0_real64)/16.0_real64
                    scaled_delta=(abs(scaled_x)-scaled_z)*(abs(scaled_x)+scaled_z)
                    v%r=(2.0_real64*exp(scaled_z*scaled_z))*exp(scaled_delta)-erfc_scaled(abs(scaled_x))
                else
                    ! Stable host scaled evaluation in the central region.
                    ! REAL4 inputs are widened, then rounded only at the end.
                    v%r=erfc_scaled(scaled_x)
                end if
                if(.not.ieee_is_finite(v%r).or.v%r<=0.0_real64) then
                    call runtime_error('invalid ERFC_SCALED finite result',lin,col);return
                end if
                if(real_kind==4) then
                    if(v%r>real(huge(0.0_real32),real64)) then
                        call runtime_error('ERFC_SCALED finite result range exceeded',lin,col);return
                    end if
                    v%r=real(real(v%r,real32),real64)
                end if
            case('isnan')
                if(size(args)/=1.or.typ/=ty_logical.or.real_kind/=4) then
                    call runtime_error('invalid ISNAN result values',lin,col);return
                end if
                if(args(1)%tag/=ty_real.or.(args(1)%real_kind/=4.and.args(1)%real_kind/=8)) then
                    call runtime_error('ISNAN requires REAL kind 4 or 8',lin,col);return
                end if
                ! This GNU extension does not relax the finite-value policy.
                ! NaN/Infinity inputs cannot be introduced through forged IR.
                if(.not.ieee_is_finite(args(1)%r)) then
                    call runtime_error('non-finite ISNAN argument is outside the supported subset',lin,col);return
                end if
                v%l=ieee_is_nan(args(1)%r)
            case('abs')
                v=args(1)
                if (v%tag==ty_integer) then
                    if(v%i==min64) then
                        call runtime_error("integer overflow",lin,col); return
                    end if
                    v%i=abs(v%i)
                else
                    v%r=abs(v%r)
                end if
            case('spacing','nearest')
                k=1
                if(name=='nearest') k=2
                if(size(args)/=k.or.typ/=ty_real.or.(real_kind/=4.and.real_kind/=8)) then
                    call runtime_error('invalid SPACING/NEAREST result or argument count',lin,col);return
                end if
                if(args(1)%real_kind/=real_kind) then
                    call runtime_error('SPACING/NEAREST X kind differs from result',lin,col);return
                end if
                do k=1,size(args)
                    if(args(k)%tag/=ty_real.or.(args(k)%real_kind/=4.and.args(k)%real_kind/=8)) then
                        call runtime_error('SPACING/NEAREST arguments must be REAL kind 4 or 8',lin,col);return
                    end if
                    if(.not.ieee_is_finite(args(k)%r)) then
                        call runtime_error('non-finite SPACING/NEAREST argument',lin,col);return
                    end if
                end do
                if(name=='spacing') then
                    if(real_kind==4) then
                        v%r=real(spacing(real(args(1)%r,real32)),real64)
                    else
                        v%r=spacing(args(1)%r)
                    end if
                else
                    if(args(2)%r==0.0_real64) then
                        call runtime_error('NEAREST direction S must be nonzero',lin,col);return
                    end if
                    ! S may have a different kind. Preserve its sign without
                    ! narrowing a tiny REAL(8) direction to REAL(4) zero.
                    if(real_kind==4) then
                        x4=real(args(1)%r,real32);y4=1.0_real32
                        if(args(2)%r<0.0_real64) y4=-y4
                        if((x4==huge(x4).and.y4>0).or.(x4==-huge(x4).and.y4<0)) then
                            call runtime_error('NEAREST result exceeds finite REAL range',lin,col);return
                        end if
                        v%r=real(nearest(x4,y4),real64)
                    else
                        if((args(1)%r==huge(0.0_real64).and.args(2)%r>0).or. &
                           (args(1)%r==-huge(0.0_real64).and.args(2)%r<0)) then
                            call runtime_error('NEAREST result exceeds finite REAL range',lin,col);return
                        end if
                        v%r=nearest(args(1)%r,sign(1.0_real64,args(2)%r))
                    end if
                end if
            case('dim','sign')
                if(size(args)/=2.or.(typ/=ty_integer.and.typ/=ty_real).or.(real_kind/=4.and.real_kind/=8)) then
                    call runtime_error('invalid DIM/SIGN result or argument count',lin,col);return
                end if
                do k=1,2
                    if(args(k)%tag/=typ.or.args(k)%real_kind/=real_kind) then
                        call runtime_error('DIM/SIGN arguments must match result type/kind',lin,col);return
                    end if
                    if(typ==ty_integer) then
                        if(.not.check_integer(args(k)%i,lin,col,real_kind)) return
                    else
                        if(.not.ieee_is_finite(args(k)%r)) then
                            call runtime_error('non-finite DIM/SIGN argument',lin,col);return
                        end if
                    end if
                end do
                if(typ==ty_integer) then
                    if(name=='dim') then
                        v%i=0_int64
                        if(args(1)%i>args(2)%i) v%i=checked_op('-',args(1)%i,args(2)%i,real_kind,lin,col)
                    else
                        v%i=args(1)%i
                        if((args(2)%i<0.and.v%i>0).or.(args(2)%i>=0.and.v%i<0)) &
                            v%i=checked_op('-',0_int64,v%i,real_kind,lin,col)
                    end if
                else if(real_kind==4) then
                    x4=real(args(1)%r,real32);y4=real(args(2)%r,real32)
                    if(name=='dim') v%r=real(dim(x4,y4),real64)
                    if(name=='sign') v%r=real(sign(x4,y4),real64)
                else
                    if(name=='dim') v%r=dim(args(1)%r,args(2)%r)
                    if(name=='sign') v%r=sign(args(1)%r,args(2)%r)
                end if
            case('log_gamma')
                if(size(args)/=1.or.typ/=ty_real.or.(real_kind/=4.and.real_kind/=8)) then
                    call runtime_error('LOG_GAMMA requires one REAL argument',lin,col);return
                end if
                if(args(1)%tag/=ty_real.or.args(1)%real_kind/=real_kind) then
                    call runtime_error('LOG_GAMMA argument/result kind differs',lin,col);return
                end if
                if(.not.ieee_is_finite(args(1)%r)) then
                    call runtime_error('non-finite LOG_GAMMA argument',lin,col);return
                end if
                if(args(1)%r<=0.0_real64.and.args(1)%r==aint(args(1)%r)) then
                    call runtime_error('LOG_GAMMA argument must not be zero or a negative integer',lin,col);return
                end if
                if(real_kind==4) then
                    v%r=real(log_gamma(real(args(1)%r,real32)),real64)
                else
                    v%r=log_gamma(args(1)%r)
                end if
            case('min','max')
                if(size(args)<2.or.size(args)>16)then
                    call runtime_error('MIN/MAX require two to sixteen arguments',lin,col);return
                end if
                if(typ==ty_character)then
                    if(real_kind/=4)then
                        call runtime_error('MIN/MAX require default CHARACTER values',lin,col);return
                    end if
                    longest=0;selected_arg=1
                    do k=1,size(args)
                        if(args(k)%tag/=ty_character.or.args(k)%real_kind/=4.or..not.allocated(args(k)%s))then
                            call runtime_error('MIN/MAX CHARACTER argument value differs',lin,col);return
                        end if
                        if(len(args(k)%s)>65536)then
                            call runtime_error('MIN/MAX CHARACTER length limit exceeded',lin,col);return
                        end if
                        longest=max(longest,len(args(k)%s))
                    end do
                    do k=2,size(args)
                        lex_order=0
                        do j=1,max(len(args(k)%s),len(args(selected_arg)%s))
                            call consume(lin,col)
                            if(diag%code/=0)return
                            lex_a=ichar(' ');lex_b=ichar(' ')
                            if(j<=len(args(k)%s))lex_a=ichar(args(k)%s(j:j))
                            if(j<=len(args(selected_arg)%s))lex_b=ichar(args(selected_arg)%s(j:j))
                            if(lex_a<lex_b)lex_order=-1
                            if(lex_a>lex_b)lex_order=1
                            if(lex_order/=0)exit
                        end do
                        if((name=='min'.and.lex_order<0).or.(name=='max'.and.lex_order>0))selected_arg=k
                    end do
                    v=args(selected_arg)
                    if(longest>len(v%s))v%s=v%s//repeat(' ',longest-len(v%s))
                    return
                end if
                v=args(1)
                do k=2,size(args)
                    if (typ==ty_integer) then
                        if (name=='min') v%i=min(v%i,args(k)%i)
                        if (name=='max') v%i=max(v%i,args(k)%i)
                    else
                        if (name=='min') v%r=min(v%r,args(k)%r)
                        if (name=='max') v%r=max(v%r,args(k)%r)
                    end if
                end do
            case('mod','modulo')
                if (size(args)/=2) then
                    call runtime_error('MOD requires two arguments',lin,col)
                    return
                end if
                if (typ==ty_integer) then
                    if (args(2)%i==0_int64) then
                        call runtime_error('MOD divisor is zero',lin,col)
                        return
                    end if
                    if(args(2)%i==-1_int64) then
                        v%i=0_int64
                    else
                        v%i=mod(args(1)%i,args(2)%i)
                    end if
                    if(name=='modulo'.and.v%i/=0_int64) then
                        if((v%i<0).neqv.(args(2)%i<0)) v%i=v%i+args(2)%i
                    end if
                else
                    if (args(2)%r==0.0_real64) then
                        call runtime_error('MOD divisor is zero',lin,col)
                        return
                    end if
                    if(real_kind==4) then
                        x4=real(args(1)%r,real32); y4=real(args(2)%r,real32)
                        v%r=real(mod(x4,y4),real64)
                        if(name=="modulo") v%r=real(modulo(x4,y4),real64)
                    else
                        v%r=mod(args(1)%r,args(2)%r)
                        if(name=="modulo") v%r=modulo(args(1)%r,args(2)%r)
                    end if
                end if
            case('exp','log','log10','sqrt','erfc','sinh','cosh','tanh','sin','cos','tan')
                if(size(args)/=1.or.args(1)%tag/=ty_real) then
                    call runtime_error('intrinsic requires one REAL argument',lin,col); return
                end if
                if((name=='log'.or.name=='log10').and.args(1)%r<=0.0_real64) then
                    if(name=='log') call runtime_error('LOG argument must be positive',lin,col)
                    if(name=='log10') call runtime_error('LOG10 argument must be positive',lin,col)
                    return
                end if
                if(name=='sqrt'.and.args(1)%r<0.0_real64) then
                    call runtime_error('SQRT argument must be nonnegative',lin,col); return
                end if
                if(real_kind==4) then
                    x4=real(args(1)%r,real32)
                    select case(name)
                    case('exp'); v%r=real(exp(x4),real64)
                    case('log'); v%r=real(log(x4),real64)
                    case('log10'); v%r=real(log10(x4),real64)
                    case('sqrt'); v%r=real(sqrt(x4),real64)
                    case('erfc'); v%r=real(erfc(x4),real64)
                    case('sinh'); v%r=real(sinh(x4),real64)
                    case('cosh'); v%r=real(cosh(x4),real64)
                    case('tanh'); v%r=real(tanh(x4),real64)
                    case('sin'); v%r=real(sin(x4),real64)
                    case('cos'); v%r=real(cos(x4),real64)
                    case('tan'); v%r=real(tan(x4),real64)
                    end select
                else
                    select case(name)
                    case('exp'); v%r=exp(args(1)%r)
                    case('log'); v%r=log(args(1)%r)
                    case('log10'); v%r=log10(args(1)%r)
                    case('sqrt'); v%r=sqrt(args(1)%r)
                    case('erfc'); v%r=erfc(args(1)%r)
                    case('sinh'); v%r=sinh(args(1)%r)
                    case('cosh'); v%r=cosh(args(1)%r)
                    case('tanh'); v%r=tanh(args(1)%r)
                    case('sin'); v%r=sin(args(1)%r)
                    case('cos'); v%r=cos(args(1)%r)
                    case('tan'); v%r=tan(args(1)%r)
                    end select
                end if
            case default
                call runtime_error('unsupported intrinsic '//name,lin,col)
            end select
        end function
        recursive subroutine render_derived(value,iotype,record,lin,col)
            type(value_t),intent(in)::value
            character(*),intent(in)::iotype
            character(:),allocatable,intent(out)::record
            integer,intent(in)::lin,col
            type(argument_t)::args(6)
            integer::t,f,j,d
            t=value%tag-ty_derived_base;record=''
            if(t<1.or.t>prog%nt) then
                call runtime_error('invalid derived output type',lin,col);return
            end if
            f=prog%derived_types(t)%write_procedure
            if(f<1.or.f>prog%np) then
                call runtime_error('derived output requires a defined formatted WRITE binding',lin,col);return
            end if
            if(.not.prog%procedures(f)%is_subroutine.or.size(prog%procedures(f)%args)/=6) then
                call runtime_error('invalid defined WRITE binding',lin,col);return
            end if
            do j=1,6
                d=prog%procedures(f)%args(j)
                args(j)%typ=prog%symbols(d)%typ;args(j)%real_kind=prog%symbols(d)%real_kind
                args(j)%rank=prog%symbols(d)%rank
                if(j==4) then
                    args(j)%dims=[0_int64,1_int64,1_int64]
                    allocate(args(j)%values(0),args(j)%initialized(0))
                else
                    allocate(args(j)%values(1),args(j)%initialized(1));args(j)%initialized=.true.
                end if
            end do
            args(1)%values(1)=value
            args(2)%values(1)=value_t(tag=ty_integer,i=int(output_unit,int64))
            args(3)%values(1)=value_t(tag=ty_character,s=iotype)
            args(3)%character_len=len(iotype)
            args(5)%values(1)=value_t(tag=ty_integer);args(5)%initialized=.false.
            args(6)%values(1)=value_t(tag=ty_character,s=repeat(' ',1024))
            args(6)%character_len=len(args(6)%values(1)%s)
            call execute_program(prog,diag,procedure_index=f,argument_bindings=args, &
                budget_remaining=budget,call_stack=stack,io_in_progress=.true.,random_state=rng,defined_output=record,module_store=modules,pointer_context=context,input_units=input_units)
            if(diag%code/=0) return
            if(.not.args(5)%initialized(1)) then
                call runtime_error('defined WRITE did not define IOSTAT',lin,col);return
            end if
            if(args(5)%values(1)%i/=0) then
                call runtime_error('defined WRITE failed: '//trim(args(6)%values(1)%s),lin,col)
            end if
        end subroutine
        subroutine append_list_output(record,used,text,lin,col)
            character(:),allocatable,intent(inout)::record
            integer,intent(inout)::used
            character(*),intent(in)::text
            integer,intent(in)::lin,col
            character(:),allocatable::grown
            integer::needed,capacity,stat
            ! List-directed records have a separate 16 MiB staging bound.
            ! Subtraction checks before growth avoid oversized concatenations;
            ! geometric capacity avoids quadratic copying for long lists.
            if(used<0.or.used>len(record).or.used>max_list_output_characters) then
                call runtime_error('invalid list-directed output buffer',lin,col);return
            end if
            if(len(text)>max_list_output_characters-used) then
                call runtime_error('list-directed output exceeds 16777216 characters',lin,col);return
            end if
            needed=used+len(text)
            if(needed>len(record)) then
                capacity=max(256,len(record))
                do while(capacity<needed)
                    capacity=min(max_list_output_characters,2*capacity)
                end do
                allocate(character(capacity)::grown,stat=stat)
                if(stat/=0) then
                    call runtime_error('list-directed output buffer allocation failed',lin,col);return
                end if
                if(used>0) grown(:used)=record(:used)
                call move_alloc(grown,record)
            end if
            if(len(text)>0) record(used+1:needed)=text
            used=needed
        end subroutine
        subroutine capture_output_format(ins,fmt)
            type(instruction_t),intent(in)::ins
            character(:),allocatable,intent(out)::fmt
            type(value_t)::value
            type(format_edit_t)::edits(64)
            type(diagnostic_t)::format_diag
            integer::e,s,n,reversion
            if(allocated(ins%format)) then
                fmt=ins%format
            else if(ins%format_expr/=0) then
                e=ins%format_expr
                if(.not.valid_expression(e)) return
                associate(x=>prog%expressions(e))
                s=x%symbol
                if(.not.valid_symbol(s)) return
                if(x%kind/=ex_variable.or.x%scope/=scope.or.x%typ/=ty_character.or.x%real_kind/=4.or. &
                   x%rank/=0.or.x%extent/=0.or.any(x%dims/=0).or.x%character_len/=prog%symbols(s)%character_len.or. &
                   x%left/=0.or.x%right/=0.or.x%stride/=0.or.x%left2/=0.or.x%right2/=0.or.x%stride2/=0.or. &
                   x%left3/=0.or.x%right3/=0.or.x%stride3/=0.or.x%third/=0.or.x%length_expr/=0.or. &
                   x%generic_id/=0.or.x%bound_type/=0.or.x%bound_binding/=0.or.x%intrinsic_mask/=0.or. &
                   len_trim(x%op)/=0.or.allocated(x%args).or.x%constructor_kind_expr/=0.or.x%parenthesized.or. &
                   any(x%triplet.neqv.[.true.,.false.,.false.]).or. &
                   prog%symbols(s)%typ/=ty_character.or.prog%symbols(s)%rank/=0.or. &
                   prog%symbols(s)%real_kind/=4.or.prog%symbols(s)%is_parameter) then
                    call runtime_error('invalid runtime format descriptor',ins%line,ins%column);return
                end if
                end associate
                value=evaluate(e,0)
                if(diag%code/=0) return
                if(value%tag/=ty_character.or.value%real_kind/=4.or..not.allocated(value%s)) then
                    call runtime_error('runtime format requires a defined CHARACTER value',ins%line,ins%column);return
                end if
                if(len(value%s)>65536) then
                    call runtime_error('runtime format exceeds 65536 characters',ins%line,ins%column);return
                end if
                fmt=value%s
            else
                return
            end if
            ! Validate grammar before evaluating output items; retain a snapshot
            ! if the destination or an item later changes the format variable.
            call parse_print_format(fmt,edits,n,format_diag,ins%line,ins%column,reversion)
            if(format_diag%code/=0) call runtime_error(format_diag%message,ins%line,ins%column)
        end subroutine
        subroutine commit_output_record(text,mode,formatted,lin,col,final_position)
            character(*),intent(in)::text
            integer,intent(in)::mode,lin,col,final_position
            logical,intent(in)::formatted
            integer::j,column,limit,status,rewind
            character(:),allocatable::staged
            character(32)::host_format
            column=context%output_column
            limit=max_list_output_characters
            if(formatted) limit=65536
            if(column<0.or.column>65536.or.final_position<0.or.final_position>len(text)) then
                call runtime_error('invalid pending output record state',lin,col);return
            end if
            staged=text
            ! A list-directed statement can also overwrite only the prefix of
            ! a record left by an earlier nonadvancing formatted statement.
            if(.not.formatted.and.allocated(context%output_tail)) then
                if(len(context%output_tail)>65536) then
                    call runtime_error('invalid pending output record state',lin,col);return
                end if
                if(len(staged)<len(context%output_tail)) staged=staged//context%output_tail(len(staged)+1:)
            end if
            ! All checking precedes this statement's only external write. A
            ! reversion newline starts another bounded output record.
            do j=1,len(staged)
                if(staged(j:j)==new_line('a')) then
                    column=0
                else
                    if(column>=limit) then
                        call runtime_error('combined output record exceeds character limit',lin,col);return
                    end if
                    column=column+1
                end if
            end do
            rewind=len(staged)-final_position
            if(mode==1.and.rewind>0) then
                ! The zero-width A transfer realizes the pending backward tab.
                ! Only this bounded, synthesized host descriptor is executed;
                ! user format text is never forwarded to external I/O.
                write(host_format,'(a,i0,a)') '(a,tl',rewind,',a)'
                write(output_unit,host_format,advance='no',iostat=status) staged,''
            else if(mode==1) then
                write(output_unit,'(a)',advance='no',iostat=status) staged
            else
                write(output_unit,'(a)',iostat=status) staged
            end if
            if(status/=0) then
                call runtime_error('PRINT output failed',lin,col);return
            end if
            if(mode==1) then
                column=context%output_column
                do j=1,final_position
                    if(staged(j:j)==new_line('a')) then
                        column=0
                    else
                        column=column+1
                    end if
                end do
                context%output_column=column
                context%output_tail=staged(final_position+1:)
            else
                context%output_column=0;context%output_tail=''
            end if
        end subroutine
        recursive subroutine collect_output_values(ins,values)
            type(instruction_t),intent(in)::ins
            type(value_t),allocatable,intent(out)::values(:)
            type(value_t)::staged_value
            integer::j,k,n,cursor,ios
            integer(int64)::extent,character_bytes
            n=0
            do j=1,size(ins%items)
                k=ins%items(j)
                if(k<1.or.k>prog%ne) then
                    call runtime_error('invalid output item reference',ins%line,ins%column);return
                end if
                if(prog%expressions(k)%kind==ex_output_do) then
                    call collect_implied_output(ins,values);return
                end if
            end do
            do j=1,size(ins%items)
                if(.not.valid_expression(ins%items(j))) return
                call prepare_expression(ins%items(j),0)
                if(diag%code/=0) return
                extent=1_int64
                if(prog%expressions(ins%items(j))%rank>0) extent=shape_extent(ins%items(j))
                if(extent<0.or.extent>max_print_values-n) then
                    call runtime_error('PRINT expanded value limit exceeded (65536)',ins%line,ins%column);return
                end if
                n=n+int(extent)
            end do
            allocate(values(n),stat=ios)
            if(ios/=0) then
                call runtime_error('PRINT temporary allocation failed',ins%line,ins%column);return
            end if
            cursor=0;character_bytes=0_int64
            do j=1,size(ins%items)
                if(prog%expressions(ins%items(j))%rank==0) then
                    staged_value=evaluate(ins%items(j),0)
                    if(diag%code/=0)return
                    call check_output_integer_metadata(staged_value,ins%items(j))
                    call check_output_character_storage(staged_value,character_bytes,ins%line,ins%column)
                    if(diag%code/=0)return
                    cursor=cursor+1;values(cursor)=staged_value
                else
                    do k=1,int(shape_extent(ins%items(j)))
                        staged_value=evaluate(ins%items(j),0,k)
                        if(diag%code/=0)return
                        call check_output_integer_metadata(staged_value,ins%items(j))
                        call check_output_character_storage(staged_value,character_bytes,ins%line,ins%column)
                        if(diag%code/=0)return
                        cursor=cursor+1;values(cursor)=staged_value
                    end do
                end if
                if(diag%code/=0) return
            end do
        end subroutine
        ! Output control trees are expanded in source order. Staged values are
        ! not rendered or committed until the whole statement succeeds. Controls
        ! are frozen once at entry; counters retain the ordinary DO final value.
        recursive subroutine collect_implied_output(ins,values)
            type(instruction_t),intent(in)::ins
            type(value_t),allocatable,intent(out)::values(:)
            type(value_t),allocatable::buffer(:)
            integer,allocatable::marks(:)
            integer::j,used,iterations,epoch,ios
            integer(int64)::character_bytes
            allocate(buffer(0),marks(prog%ne),stat=ios)
            if(ios/=0) then
                call runtime_error('output implied-DO scratch allocation failed',ins%line,ins%column);return
            end if
            marks=0;epoch=0;used=0;iterations=0;character_bytes=0_int64
            do j=1,size(ins%items)
                call expand_output_item(ins%items(j),1,buffer,used,iterations,character_bytes,marks,epoch)
                if(diag%code/=0) return
            end do
            allocate(values(used),stat=ios)
            if(ios/=0) then
                call runtime_error('PRINT temporary allocation failed',ins%line,ins%column);return
            end if
            values=buffer(:used)
        end subroutine
        recursive subroutine expand_output_item(root,depth,buffer,used,iterations,character_bytes,marks,epoch)
            integer,intent(in)::root,depth
            type(value_t),allocatable,intent(inout)::buffer(:)
            integer,intent(inout)::used,iterations,marks(:),epoch
            integer(int64),intent(inout)::character_bytes
            type(value_t)::a,b,c,value
            integer::j,k,s
            integer(int64)::extent,last,stride,next
            if(diag%code/=0) return
            if(root<1.or.root>prog%ne) then
                call runtime_error('invalid output item reference',0,0);return
            end if
            associate(x=>prog%expressions(root))
            call consume(x%line,x%column);if(diag%code/=0) return
            if(x%kind/=ex_output_do) then
                if(.not.valid_expression(root)) return
                call reset_output_item(root,marks,epoch)
                call prepare_expression(root,0)
                if(diag%code/=0) return
                extent=1_int64
                if(x%rank>0) extent=shape_extent(root)
                if(extent<0.or.extent>max_print_values-used) then
                    call runtime_error('PRINT expanded value limit exceeded (65536)',x%line,x%column);return
                end if
                do k=1,int(extent)
                    if(x%rank==0) then
                        value=evaluate(root,0)
                    else
                        value=evaluate(root,0,k)
                    end if
                    if(diag%code/=0) return
                    call check_output_integer_metadata(value,root)
                    if(diag%code/=0) return
                    call append_output_value(value,buffer,used,character_bytes,x%line,x%column)
                    if(diag%code/=0) return
                end do
                return
            end if
            if(depth>max_output_do_depth.or..not.valid_output_do(prog,root).or.x%scope/=scope) then
                call runtime_error('invalid output implied-DO metadata',x%line,x%column);return
            end if
            s=x%symbol
            if(.not.valid_symbol(s)) return
            if(refs(s)%active) then
                call runtime_error('output implied-DO counter is already active',x%line,x%column);return
            end if
            call reset_output_item(x%left,marks,epoch);a=evaluate(x%left,0)
            if(diag%code/=0) return
            call reset_output_item(x%right,marks,epoch);b=evaluate(x%right,0)
            if(diag%code/=0) return
            c=value_t(tag=ty_integer,real_kind=prog%symbols(s)%real_kind,i=1_int64)
            if(x%stride/=0) then
                call reset_output_item(x%stride,marks,epoch);c=evaluate(x%stride,0)
            end if
            if(diag%code/=0) return
            if(a%tag/=ty_integer.or.b%tag/=ty_integer.or.c%tag/=ty_integer) then
                call runtime_error('noninteger output implied-DO control',x%line,x%column);return
            end if
            if(.not.check_integer(a%i,x%line,x%column,prog%symbols(s)%real_kind)) return
            if(.not.check_integer(b%i,x%line,x%column,prog%symbols(s)%real_kind)) return
            if(.not.check_integer(c%i,x%line,x%column,prog%symbols(s)%real_kind)) return
            last=b%i;stride=c%i
            if(stride==0_int64) then
                call runtime_error('output implied-DO step is zero',x%line,x%column);return
            end if
            refs(s)%value=a;refs(s)%value%real_kind=prog%symbols(s)%real_kind;refs(s)%defined=.true.
            if((stride>0.and.a%i>last).or.(stride<0.and.a%i<last)) return
            refs(s)%active=.true.
            do
                iterations=iterations+1
                if(iterations>max_print_values) then
                    call runtime_error('output implied-DO iteration limit exceeded (65536)',x%line,x%column);exit
                end if
                call consume(x%line,x%column)
                if(diag%code/=0) exit
                do j=1,size(x%args)
                    call expand_output_item(x%args(j),depth+1,buffer,used,iterations,character_bytes,marks,epoch)
                    if(diag%code/=0) exit
                end do
                if(diag%code/=0) exit
                next=checked_op('+',refs(s)%value%i,stride,prog%symbols(s)%real_kind,x%line,x%column)
                if(diag%code/=0) exit
                refs(s)%value%i=next
                if((stride>0.and.next>last).or.(stride<0.and.next<last)) exit
            end do
            refs(s)%active=.false.
            end associate
        end subroutine
        subroutine append_output_value(value,buffer,used,character_bytes,lin,col)
            type(value_t),intent(in)::value
            type(value_t),allocatable,intent(inout)::buffer(:)
            integer,intent(inout)::used
            integer(int64),intent(inout)::character_bytes
            integer,intent(in)::lin,col
            type(value_t),allocatable::grown(:)
            integer::capacity,ios
            if(used>=max_print_values) then
                call runtime_error('PRINT expanded value limit exceeded (65536)',lin,col);return
            end if
            call check_output_character_storage(value,character_bytes,lin,col)
            if(diag%code/=0) return
            if(used==size(buffer)) then
                capacity=min(max_print_values,max(16,2*size(buffer)))
                allocate(grown(capacity),stat=ios)
                if(ios/=0) then
                    call runtime_error('PRINT temporary allocation failed',lin,col);return
                end if
                grown(:used)=buffer(:used);call move_alloc(grown,buffer)
            end if
            used=used+1;buffer(used)=value
        end subroutine
        recursive logical function constructor_has_loop(root,depth) result(found)
            integer,intent(in)::root,depth
            integer::j
            found=.false.
            if(root<1.or.root>prog%ne.or.depth>256) return
            associate(x=>prog%expressions(root))
            if(x%kind==ex_constructor_do) then
                found=.true.;return
            end if
            if(x%kind/=ex_constructor.or..not.allocated(x%args)) return
            do j=1,size(x%args)
                if(constructor_has_loop(x%args(j),depth+1)) then
                    found=.true.;return
                end if
            end do
            end associate
        end function
        recursive subroutine materialize_constructor(root,depth)
            integer,intent(in)::root,depth
            type(value_t),allocatable::buffer(:),values(:)
            integer,allocatable::marks(:)
            integer::j,used,epoch,status,old_level
            integer(int64)::bytes
            if(diag%code/=0) return
            if(constructor_materializations==0) then
                if(.not.valid_constructor_tree(prog,root)) then
                    call runtime_error('invalid constructor tree or lexical ownership', &
                        prog%expressions(root)%line,prog%expressions(root)%column);return
                end if
            end if
            old_level=constructor_level
            constructor_materializations=constructor_materializations+1
            if(constructor_materializations==1) constructor_expansions=0
            used=0;epoch=0;bytes=0_int64
            allocate(buffer(0),marks(prog%ne),stat=status)
            if(status/=0) then
                call runtime_error('constructor implied-DO scratch allocation failed', &
                    prog%expressions(root)%line,prog%expressions(root)%column)
            else
                marks=0
                call validate_kind_tree(root,marks,0)
                marks=0
                do j=1,size(prog%expressions(root)%args)
                    if(diag%code/=0) exit
                    call expand_constructor_item(prog%expressions(root)%args(j),root,depth+1,buffer,used,bytes,marks,epoch)
                    if(diag%code/=0) exit
                end do
                if(diag%code==0) then
                    if(cached_elements>max_array_elements-int(used,int64)) then
                        call runtime_error('constructor temporary element limit exceeded', &
                            prog%expressions(root)%line,prog%expressions(root)%column)
                    else
                        allocate(values(used),stat=status)
                        if(status/=0) then
                            call runtime_error('constructor result allocation failed', &
                                prog%expressions(root)%line,prog%expressions(root)%column)
                        else
                            values=buffer(:used)
                            call move_alloc(values,expression_cache(root)%values)
                            cached_elements=cached_elements+used
                            shape_extent(root)=int(used,int64);shape_dims(:,root)=[int(used,int64),1_int64,1_int64]
                        end if
                    end if
                end if
            end if
            constructor_level=old_level
            constructor_materializations=constructor_materializations-1
        end subroutine
        recursive subroutine expand_constructor_item(item,root,depth,buffer,used,bytes,marks,epoch)
            integer,intent(in)::item,root,depth
            type(value_t),allocatable,intent(inout)::buffer(:)
            integer,intent(inout)::used,marks(:),epoch
            integer(int64),intent(inout)::bytes
            type(value_t)::a,b,c,v
            integer::j,k,slot,rk
            integer(int64)::n,step,last,next
            if(diag%code/=0) return
            if(item<1.or.item>prog%ne.or.depth>256) then
                call runtime_error('invalid constructor expansion tree',0,0);return
            end if
            associate(x=>prog%expressions(item))
            call consume(x%line,x%column);if(diag%code/=0) return
            if(x%rank<0.or.x%rank>1.or.x%typ/=prog%expressions(root)%typ.or. &
               x%real_kind/=prog%expressions(root)%real_kind) then
                call runtime_error('constructor item type, kind or rank mismatch',x%line,x%column);return
            end if
            if(x%typ==ty_character.and.prog%expressions(root)%op/='character') then
                if(x%character_len>=0.and.x%character_len/=expression_cache(root)%character_len) then
                    call runtime_error('CHARACTER constructor item lengths differ',x%line,x%column);return
                end if
            end if
            if(x%kind/=ex_constructor_do) then
                if(.not.valid_expression(item)) return
                call reset_output_item(item,marks,epoch)
                call prepare_expression(item,depth+1)
                if(diag%code/=0) return
                n=1_int64
                if(x%rank>0) n=shape_extent(item)
                if(n<0.or.n>max_array_elements-used) then
                    call runtime_error('constructor element limit exceeded',x%line,x%column);return
                end if
                do k=1,int(n)
                    if(x%rank==0) then
                        v=evaluate(item,depth+1)
                    else
                        v=evaluate(item,depth+1,k)
                    end if
                    if(diag%code/=0) return
                    call append_constructor_value(v,root,buffer,used,bytes)
                    if(diag%code/=0) return
                end do
                call reset_output_item(item,marks,epoch)
                return
            end if
            if(constructor_level>=max_constructor_do_depth.or..not.allocated(x%args)) then
                call runtime_error('constructor implied-DO nesting limit exceeded (8)',x%line,x%column);return
            end if
            if(x%scope/=prog%expressions(root)%scope) then
                call runtime_error('constructor implied-DO scope mismatch',x%line,x%column);return
            end if
            rk=prog%symbols(x%symbol)%real_kind
            call reset_output_item(x%left,marks,epoch);a=evaluate(x%left,depth+1)
            if(diag%code/=0) return
            call reset_output_item(x%right,marks,epoch);b=evaluate(x%right,depth+1)
            if(diag%code/=0) return
            c=value_t(tag=ty_integer,real_kind=rk,i=1_int64)
            if(x%stride/=0) then
                call reset_output_item(x%stride,marks,epoch);c=evaluate(x%stride,depth+1)
            end if
            if(diag%code/=0) return
            if(a%tag/=ty_integer.or.b%tag/=ty_integer.or.c%tag/=ty_integer) then
                call runtime_error('noninteger constructor implied-DO control',x%line,x%column);return
            end if
            if(.not.check_integer(a%i,x%line,x%column,rk)) return
            if(.not.check_integer(b%i,x%line,x%column,rk)) return
            if(.not.check_integer(c%i,x%line,x%column,rk)) return
            step=c%i;last=b%i
            if(step==0_int64) then
                call runtime_error('constructor implied-DO step is zero',x%line,x%column);return
            end if
            if((step>0.and.a%i>last).or.(step<0.and.a%i<last)) return
            constructor_level=constructor_level+1;slot=constructor_level
            constructor_owners(slot)=item;constructor_values(slot)=a%i
            do
                constructor_expansions=constructor_expansions+1
                if(constructor_expansions>max_array_elements) then
                    call runtime_error('constructor implied-DO iteration limit exceeded',x%line,x%column);exit
                end if
                call consume(x%line,x%column);if(diag%code/=0) exit
                do j=1,size(x%args)
                    call expand_constructor_item(x%args(j),root,depth+1,buffer,used,bytes,marks,epoch)
                    if(diag%code/=0) exit
                end do
                if(diag%code/=0) exit
                next=checked_op('+',constructor_values(slot),step,rk,x%line,x%column)
                if(diag%code/=0) exit
                constructor_values(slot)=next
                if((step>0.and.next>last).or.(step<0.and.next<last)) exit
            end do
            constructor_level=constructor_level-1
            end associate
        end subroutine
        subroutine append_constructor_value(value,root,buffer,used,bytes)
            type(value_t),intent(in)::value
            integer,intent(in)::root
            type(value_t),allocatable,intent(inout)::buffer(:)
            integer,intent(inout)::used
            integer(int64),intent(inout)::bytes
            type(value_t),allocatable::grown(:)
            type(value_t)::v
            integer::capacity,status,n
            associate(x=>prog%expressions(root))
            if(used>=max_array_elements) then
                call runtime_error('constructor element limit exceeded',x%line,x%column);return
            end if
            if(value%tag/=x%typ.or.value%real_kind/=x%real_kind) then
                call runtime_error('constructor value type or kind mismatch',x%line,x%column);return
            end if
            v=value
            if(x%typ==ty_character) then
                n=expression_cache(root)%character_len
                if(.not.allocated(v%s).or.n<0.or.n>65536) then
                    call runtime_error('invalid CHARACTER constructor value',x%line,x%column);return
                end if
                if(x%op/='character'.and.len(v%s)/=n) then
                    call runtime_error('CHARACTER constructor item lengths differ',x%line,x%column);return
                end if
                if(bytes>16777216_int64-n) then
                    call runtime_error('constructor CHARACTER staging limit exceeded (16 MiB)',x%line,x%column);return
                end if
                bytes=bytes+n
                v%s=v%s(:min(len(v%s),n))//repeat(' ',max(0,n-len(v%s)))
            end if
            if(used==size(buffer)) then
                capacity=min(max_array_elements,max(16,2*size(buffer)))
                allocate(grown(capacity),stat=status)
                if(status/=0) then
                    call runtime_error('constructor temporary allocation failed',x%line,x%column);return
                end if
                grown(:used)=buffer(:used);call move_alloc(grown,buffer)
            end if
            used=used+1;buffer(used)=v
            end associate
        end subroutine
        subroutine reset_output_item(root,marks,epoch)
            integer,intent(in)::root
            integer,intent(inout)::marks(:),epoch
            ! The statement and expansion caps bound epochs well below HUGE.
            epoch=epoch+1
            call clear_output_tree(root,marks,epoch,0)
        end subroutine
        recursive subroutine clear_output_tree(root,marks,epoch,depth)
            integer,intent(in)::root,epoch,depth
            integer,intent(inout)::marks(:)
            integer::j,children(12)
            if(diag%code/=0.or.root==0) return
            if(root<1.or.root>prog%ne.or.depth>256) then
                call runtime_error('invalid output expression tree',0,0);return
            end if
            if(marks(root)==epoch) return
            marks(root)=epoch
            associate(x=>prog%expressions(root))
            call consume(x%line,x%column);if(diag%code/=0) return
            shape_state(root)=0
            expression_cache(root)%character_len=-1
            cached_gather_character_bytes=cached_gather_character_bytes-expression_cache(root)%gather_character_bytes
            expression_cache(root)%gather_character_bytes=0_int64
            if(allocated(expression_cache(root)%values)) then
                cached_elements=cached_elements-size(expression_cache(root)%values,kind=int64)
                deallocate(expression_cache(root)%values)
            end if
            children=[x%left,x%right,x%stride,x%left2,x%right2,x%stride2,x%left3,x%right3,x%stride3, &
                      x%third,x%length_expr,x%constructor_kind_expr]
            do j=1,size(children)
                if(children(j)/=0) call clear_output_tree(children(j),marks,epoch,depth+1)
            end do
            if(allocated(x%args)) then
                do j=1,size(x%args)
                    call clear_output_tree(x%args(j),marks,epoch,depth+1)
                end do
            end if
            end associate
        end subroutine
        subroutine ensure_process_name(lin,col)
            integer,intent(in)::lin,col
            integer::n,status,ios
            if(context%process_name_ready) then
                if(.not.allocated(context%process_name).or.context%process_name_status<0) then
                    call runtime_error('invalid process program name context',lin,col);return
                end if
                if(len(context%process_name)>65536) call runtime_error('process program name exceeds 65536 characters',lin,col)
                return
            end if
            call get_command_argument(0,length=n,status=status)
            if(status/=0) n=0
            if(n<0.or.n>65536) then
                call runtime_error('process program name exceeds 65536 characters',lin,col);return
            end if
            allocate(character(n)::context%process_name,stat=ios)
            if(ios/=0) then
                call runtime_error('process program name allocation failed',lin,col);return
            end if
            context%process_name(:)=''
            if(status==0.and.n>0) call get_command_argument(0,value=context%process_name,status=status)
            context%process_name_status=max(0,status);context%process_name_ready=.true.
        end subroutine
        subroutine execute_timing_query(ins)
            type(instruction_t),intent(in)::ins
            type(clock_sample_t)::sample
            type(value_t)::values(3)
            integer::j,k,e,s,t,clock_kind,types(3),kinds(3),symbols(3)
            logical::ok
            if(.not.valid_timing_query(prog,ins))then
                call runtime_error('invalid timing inquiry metadata',ins%line,ins%column);return
            end if
            call check_random_effect(ins%line,ins%column,'Timing inquiry')
            if(diag%code/=0)return
            types=0;kinds=0;symbols=0
            do j=1,size(ins%items)
                e=ins%items(j);if(e==0)cycle
                if(.not.valid_expression(e))return
                s=prog%expressions(e)%symbol
                if(ins%d==1)then
                    if(.not.valid_symbol(s,allow_absent=.true.))return
                    if(.not.dummy_present(s))cycle
                else
                    if(.not.valid_symbol(s))return
                end if
                if(refs(s)%active)then
                    call runtime_error('timing output is an active DO counter',ins%line,ins%column);return
                end if
                if(prog%symbols(s)%scope<0.or.prog%symbols(s)%is_saved.or.captured(s)) &
                    call check_external_effect(ins%line,ins%column)
                if(diag%code/=0)return
                do k=1,j-1
                    t=symbols(k);if(t==0)cycle
                    if(associated(refs(s)%value,refs(t)%value).or.associated(refs(s)%defined,refs(t)%defined))then
                        call runtime_error('timing inquiry outputs overlap',ins%line,ins%column);return
                    end if
                end do
                types(j)=prog%symbols(s)%typ;kinds(j)=prog%symbols(s)%real_kind;symbols(j)=s
            end do
            clock_kind=timing_request_kind(ins%d,types,kinds)
            if(clock_kind==0)then
                call runtime_error('invalid effective timing output metadata',ins%line,ins%column);return
            end if
            ! All descriptors, effects and the fixed inquiry charge are checked
            ! before obtaining a host sample, then every result is staged before
            ! any user output is defined. Neither inquiry reads output values.
            do j=1,64
                call consume(ins%line,ins%column);if(diag%code/=0)return
            end do
            call sample_processor_clock(ins%d,clock_kind,sample,ok)
            if(.not.ok)then
                call runtime_error('unsupported host clock request',ins%line,ins%column);return
            end if
            call timing_sample_values(ins%d,types,kinds,sample,values,ok)
            if(.not.ok)then
                call runtime_error('invalid or nonfinite host clock sample',ins%line,ins%column);return
            end if
            do j=1,3
                s=symbols(j);if(s==0)cycle
                refs(s)%value=values(j);refs(s)%defined=.true.
            end do
        end subroutine
        subroutine execute_process_query(ins)
            type(instruction_t),intent(in)::ins
            type(value_t)::number
            character(:),allocatable::text
            integer::j,k,e,s,t,first,n,ios,status,length_value,value_slot,length_slot,status_slot
            intrinsic::getcwd
            if(.not.valid_process_query(prog,ins)) then
                call runtime_error('invalid process query metadata',ins%line,ins%column);return
            end if
            call check_random_effect(ins%line,ins%column,'Process query')
            if(diag%code/=0) return
            first=1;value_slot=1;length_slot=0;status_slot=2
            if(ins%d==2) then
                first=2;value_slot=2;length_slot=3;status_slot=4
            end if
            n=0
            do j=first,size(ins%items)
                e=ins%items(j);if(e==0) cycle
                s=prog%expressions(e)%symbol
                if(.not.valid_symbol(s)) return
                if(refs(s)%active) then
                    call runtime_error('process query cannot modify an active DO counter',ins%line,ins%column);return
                end if
                if(prog%symbols(s)%is_allocatable) then
                    if(.not.array_available(s,ins%line,ins%column)) return
                end if
                do k=first,j-1
                    if(ins%items(k)==0) cycle
                    t=prog%expressions(ins%items(k))%symbol
                    if(associated(refs(s)%defined,refs(t)%defined)) then
                        call runtime_error('process query outputs overlap',ins%line,ins%column);return
                    end if
                end do
                if(j==value_slot) n=character_length(e,0,.true.)
                if(diag%code/=0) return
            end do
            if(n<0.or.n>65536) then
                call runtime_error('process query CHARACTER buffer exceeds 65536 characters',ins%line,ins%column);return
            end if
            number=value_t(tag=ty_integer,i=0_int64)
            if(ins%d==2) then
                number=evaluate(ins%items(1),0)
                if(diag%code/=0) return
                if(number%tag/=ty_integer.or.number%real_kind/=4.or.number%i<0) then
                    call runtime_error('process query NUMBER requires a nonnegative default INTEGER',ins%line,ins%column);return
                end if
            end if
            ! Charge fixed inquiry work before touching the processor, then all
            ! copied/padded characters before committing any output actual.
            do j=1,64
                call consume(ins%line,ins%column);if(diag%code/=0) return
            end do
            allocate(character(n)::text,stat=ios)
            if(ios/=0) then
                call runtime_error('process query buffer allocation failed',ins%line,ins%column);return
            end if
            text=repeat(' ',n);length_value=0;status=0
            if(ins%d==1) then
                call getcwd(text,status)
                if(status/=0) text=repeat(' ',n)
                length_value=len_trim(text)
            else if(number%i>0) then
                ! The CLI currently accepts no interpreted-program arguments.
                ! Never expose the interpreter's flags or host option arguments.
                status=1
            else
                call ensure_process_name(ins%line,ins%column)
                if(diag%code/=0) return
                length_value=len(context%process_name);status=context%process_name_status
                if(ins%items(value_slot)>0.and.status==0) then
                    text=context%process_name(:min(n,length_value))//repeat(' ',max(0,n-length_value))
                    if(n<length_value) status=-1
                    ! GNU treats a present zero-length VALUE as unavailable;
                    ! omit VALUE for a portable length-only inquiry.
                    if(n==0) status=1
                end if
            end if
            do j=1,n+length_value
                call consume(ins%line,ins%column);if(diag%code/=0) return
            end do
            e=ins%items(value_slot)
            if(e/=0) then
                s=prog%expressions(e)%symbol
                refs(s)%value=value_t(tag=ty_character,s=text);refs(s)%defined=.true.
            end if
            if(length_slot>0) then
                e=ins%items(length_slot)
                if(e/=0) then
                    s=prog%expressions(e)%symbol
                    refs(s)%value=value_t(tag=ty_integer,i=int(length_value,int64));refs(s)%defined=.true.
                end if
            end if
            e=ins%items(status_slot)
            if(e/=0) then
                s=prog%expressions(e)%symbol
                refs(s)%value=value_t(tag=ty_integer,i=int(status,int64));refs(s)%defined=.true.
            end if
        end subroutine
        subroutine execute_internal_read(ins)
            type(instruction_t),intent(in)::ins
            type(value_t)::file,value,status_value
            integer::j,k,s,t,n,ios,at,length_token,iv4,stat_symbol,file_symbol,char_length,repeat_type,repeat_kind,u,record_length,storage_n
            integer(int64)::repeat_left,total,character_bytes
            real(real32)::rv4
            logical::slash,is_null,quoted,reused,external,pending_comma
            character(65536)::token,record
            external=ins%op==op_read_external.and..not.allocated(ins%format);u=0;record_length=0;pending_comma=.false.
            if(ins%op==op_read_external) then
                if(.not.valid_external_read(prog,ins)) then
                    call runtime_error('invalid external READ metadata',ins%line,ins%column);return
                end if
                call check_external_effect(ins%line,ins%column)
                if(diag%code/=0) return
            else if(.not.valid_internal_read(prog,ins)) then
                call runtime_error('invalid internal READ metadata',ins%line,ins%column);return
            end if
            ! Validate every descriptor before starting data transfer. Nothing is
            ! read from targets: null values must preserve their definedness.
            total=0_int64;character_bytes=0_int64;stat_symbol=0;file_symbol=prog%expressions(ins%a)%symbol
            do j=0,size(ins%items)
                if(j==0) then
                    if(ins%b==0) cycle
                    s=prog%expressions(ins%b)%symbol;stat_symbol=s
                else
                    s=prog%expressions(ins%items(j))%symbol
                end if
                if(.not.valid_symbol(s)) return
                if(associated(refs(s)%defined,refs(file_symbol)%defined)) then
                    call runtime_error('READ file or unit overlaps a target',ins%line,ins%column);return
                end if
                if(refs(s)%active) then
                    call runtime_error('internal READ cannot modify an active DO variable',ins%line,ins%column);return
                end if
                n=1
                if(prog%symbols(s)%rank>0.or.prog%symbols(s)%is_allocatable) then
                    if(.not.array_available(s,ins%line,ins%column)) return
                    if(prog%symbols(s)%rank>0) n=size(refs(s)%array%data)
                end if
                storage_n=n
                if(j>0)then
                    if(prog%expressions(ins%items(j))%kind==ex_element)n=1
                end if
                if(j>0.and.prog%symbols(s)%typ==ty_character) then
                    call read_character_length(s,char_length,ins%line,ins%column)
                    if(diag%code/=0) return
                    character_bytes=character_bytes+int(n,int64)*int(char_length,int64)
                    if(character_bytes>16777216_int64.or..not.character_storage_fits(s,int(storage_n,int64),char_length)) then
                        call runtime_error('READ CHARACTER byte limit exceeded (16777216)',ins%line,ins%column);return
                    end if
                end if
                if(j>0) total=total+n
                if(total>max_array_elements) then
                    call runtime_error('internal READ expanded target limit exceeded',ins%line,ins%column);return
                end if
                do k=0,j-1
                    if(k==0) then
                        if(stat_symbol==0) cycle
                        t=stat_symbol
                    else
                        t=prog%expressions(ins%items(k))%symbol
                    end if
                    if(associated(refs(s)%defined,refs(t)%defined)) then
                        call runtime_error('internal READ targets overlap',ins%line,ins%column);return
                    end if
                end do
            end do
            if(ins%op==op_read_internal.and.prog%expressions(ins%a)%kind==ex_element)then
                call validate_internal_element_file_storage(file_symbol,ins%line,ins%column)
                if(diag%code/=0)return
            end if
            file=evaluate(ins%a,0)
            if(diag%code/=0) return
            if(ins%op==op_read_internal.and.prog%expressions(ins%a)%kind==ex_element)then
                call read_character_length(file_symbol,char_length,ins%line,ins%column)
                if(diag%code/=0)return
                if(file%tag/=ty_character.or.file%real_kind/=4.or..not.allocated(file%s))then
                    call runtime_error('invalid internal READ element file value',ins%line,ins%column);return
                end if
                if(len(file%s)/=char_length)then
                    call runtime_error('internal READ element file length differs',ins%line,ins%column);return
                end if
            end if
            if(ins%op==op_read_external.and..not.external) then
                call external_character_read(ins,file,stat_symbol)
                return
            end if
            ios=0
            if(external) then
                call bound_input_unit(file,u,ins%line,ins%column)
                if(diag%code/=0) return
                call input_record(u,record,record_length,ios,ins%line,ins%column)
                if(diag%code/=0) return
            else
            if(file%tag/=ty_character.or..not.allocated(file%s)) then
                call runtime_error('invalid internal READ file value',ins%line,ins%column);return
            end if
            if(len(file%s)>65536) then
                call runtime_error('internal READ file exceeds 65536 characters',ins%line,ins%column);return
            end if
            ! Single scalar CHARACTER record. Host control characters are not
            ! silently treated as extra internal records or external file data.
            do j=1,len(file%s)
                call consume(ins%line,ins%column)
                if(diag%code/=0) return
                if(iachar(file%s(j:j))<32.and.file%s(j:j)/=achar(9)) then
                    call runtime_error('internal READ requires a single text record',ins%line,ins%column);return
                end if
            end do
            end if
            at=1;repeat_left=0;length_token=0;slash=.false.;is_null=.false.;quoted=.false.
            repeat_type=0;repeat_kind=0
            transfer: do j=1,size(ins%items)
                if(ios/=0) exit transfer
                s=prog%expressions(ins%items(j))%symbol;n=1
                if(prog%symbols(s)%rank>0) n=size(refs(s)%array%data)
                do k=1,n
                    call consume(ins%line,ins%column)
                    if(diag%code/=0) return
                    reused=repeat_left>0
                    if(external) then
                        call next_external_input(u,record,record_length,at,pending_comma,repeat_left,token,length_token,is_null,slash,quoted,ios,ins%line,ins%column)
                        if(diag%code/=0) return
                    else
                        call next_internal_input(file%s,at,repeat_left,token,length_token,is_null,slash,quoted,ios)
                    end if
                    if(ios/=0.or.slash) exit transfer
                    if(is_null) cycle
                    value=value_t();value%tag=prog%symbols(s)%typ;value%real_kind=prog%symbols(s)%real_kind
                    if(reused) then
                        if(value%tag/=repeat_type.or.value%real_kind/=repeat_kind) then
                            ios=1;exit transfer
                        end if
                    end if
                    repeat_type=value%tag;repeat_kind=value%real_kind
                    if(value%tag==ty_character) then
                        call read_character_length(s,char_length,ins%line,ins%column)
                        if(diag%code/=0) return
                        value%s=token(:min(length_token,char_length))//repeat(' ',max(0,char_length-length_token))
                    else
                    if(quoted) then
                        ios=1;exit transfer
                    end if
                    ! Validate the token alphabet before invoking a bounded
                    ! native internal conversion; no unit or file is opened.
                    do t=1,length_token
                        if(index('0123456789+-.eEdD',token(t:t))==0) ios=1
                    end do
                    if(value%tag==ty_integer) then
                        do t=1,length_token
                            if(index('0123456789+-',token(t:t))==0) ios=1
                        end do
                    end if
                    if(ios/=0) exit transfer
                    if(value%tag==ty_integer) then
                        if(value%real_kind==4) then
                            read(token(:length_token),*,iostat=ios) iv4
                            if(ios==0) value%i=int(iv4,int64)
                        else
                            read(token(:length_token),*,iostat=ios) value%i
                        end if
                    else if(value%real_kind==4) then
                        read(token(:length_token),*,iostat=ios) rv4
                        if(ios==0) value%r=real(rv4,real64)
                    else
                        read(token(:length_token),*,iostat=ios) value%r
                    end if
                    if(ios/=0) then
                        ios=1;exit transfer
                    end if
                    if(value%tag==ty_real) then
                        if(.not.ieee_is_finite(value%r)) then
                            ios=1;exit transfer
                        end if
                    end if
                    end if
                    if(prog%symbols(s)%rank==0) then
                        refs(s)%value=value;refs(s)%defined=.true.
                    else
                        refs(s)%array%data(k)=value;refs(s)%array%flags(k)=.true.
                    end if
                end do
            end do transfer
            ! F2018 12.11.2/12.11.3: after conversion error or EOF, the
            ! input-list objects are undefined, even if prefix values transferred.
            ! Retain storage, but never expose those incidental values as defined.
            if(ios/=0) then
                do j=1,size(ins%items)
                    s=prog%expressions(ins%items(j))%symbol
                    if(prog%symbols(s)%rank==0) then
                        refs(s)%defined=.false.
                    else
                        refs(s)%array%flags=.false.
                    end if
                end do
            end if
            if(stat_symbol/=0) then
                status_value%tag=ty_integer;status_value%real_kind=prog%symbols(stat_symbol)%real_kind
                status_value%i=int(ios,int64);refs(stat_symbol)%value=status_value;refs(stat_symbol)%defined=.true.
            else if(ios<0) then
                if(external) then
                    call runtime_error('end of external READ input',ins%line,ins%column)
                else
                    call runtime_error('end of internal READ record',ins%line,ins%column)
                end if
            else if(ios>0) then
                if(external) then
                    call runtime_error('invalid value or past endfile in external READ input',ins%line,ins%column)
                else
                    call runtime_error('invalid value in internal READ record',ins%line,ins%column)
                end if
            end if
        end subroutine
        subroutine validate_internal_element_file_storage(s,lin,col)
            integer,intent(in)::s,lin,col
            integer::r,j,n
            integer(int64)::lb(3),ub(3),extent,total
            ! This new input-file subset owns its local storage. Validate the
            ! complete descriptor before generic element evaluation computes an
            ! offset, but never inspect unselected payloads or definedness flags.
            if(.not.valid_symbol(s))return
            if(.not.array_available(s,lin,col))return
            r=prog%symbols(s)%rank
            if(r<1.or.r>3.or.refs(s)%array%borrowed)then
                call runtime_error('invalid internal READ element file storage',lin,col);return
            end if
            lb=[refs(s)%array%lower_bound,refs(s)%array%lower_bound2,refs(s)%array%lower_bound3]
            ub=[refs(s)%array%upper_bound,refs(s)%array%upper_bound2,refs(s)%array%upper_bound3]
            if(.not.prog%symbols(s)%is_allocatable)then
                if(lb(1)/=prog%symbols(s)%lower_bound.or.ub(1)/=prog%symbols(s)%upper_bound)then
                    call runtime_error('internal READ element file declared bounds differ',lin,col);return
                end if
                if(r>=2)then
                    if(lb(2)/=prog%symbols(s)%lower_bound2.or.ub(2)/=prog%symbols(s)%upper_bound2)then
                        call runtime_error('internal READ element file declared bounds differ',lin,col);return
                    end if
                end if
                if(r==3)then
                    if(lb(3)/=prog%symbols(s)%lower_bound3.or.ub(3)/=prog%symbols(s)%upper_bound3)then
                        call runtime_error('internal READ element file declared bounds differ',lin,col);return
                    end if
                end if
            end if
            total=1_int64
            do j=1,r
                extent=0_int64
                if(ub(j)>=lb(j))then
                    if(lb(j)<0_int64)then
                        if(ub(j)>huge(0_int64)+lb(j))then
                            call runtime_error('invalid internal READ element file bounds',lin,col);return
                        end if
                    end if
                    extent=ub(j)-lb(j)
                    if(extent>=max_array_elements)then
                        call runtime_error('internal READ element file extent limit exceeded',lin,col);return
                    end if
                    extent=extent+1_int64
                end if
                if(extent>0_int64)then
                    if(total>int(max_array_elements,int64)/extent)then
                        call runtime_error('internal READ element file extent limit exceeded',lin,col);return
                    end if
                end if
                total=total*extent
            end do
            if(total/=size(refs(s)%array%data,kind=int64).or.total/=size(refs(s)%array%flags,kind=int64))then
                call runtime_error('internal READ element file descriptor size differs',lin,col);return
            end if
            call read_character_length(s,n,lin,col)
            if(diag%code/=0)return
            if(n/=prog%symbols(s)%character_len)then
                call runtime_error('internal READ element file declared length differs',lin,col);return
            end if
            if(.not.character_storage_fits(s,total,n))then
                call runtime_error('internal READ element file CHARACTER storage limit exceeded',lin,col);return
            end if
        end subroutine
        subroutine read_character_length(s,n,lin,col)
            integer,intent(in)::s,lin,col
            integer,intent(out)::n
            n=prog%symbols(s)%character_len
            if(prog%symbols(s)%is_allocatable) then
                n=refs(s)%array%character_len
            else if(n<0) then
                ! Runtime-length locals keep their frozen length in the scalar
                ! descriptor; assumed-length array dummies also carry it there.
                if(allocated(refs(s)%value%s)) n=len(refs(s)%value%s)
                if(n<0.and.prog%symbols(s)%rank>0) n=refs(s)%array%character_len
            end if
            if(n<0.or.n>65536) call runtime_error('invalid READ CHARACTER length',lin,col)
        end subroutine
        subroutine bound_input_unit(value,u,lin,col)
            type(value_t),intent(in)::value
            integer,intent(out)::u
            integer,intent(in)::lin,col
            integer::j
            u=0
            if(value%tag/=ty_integer.or.value%i<=0.or.value%i>2147483647_int64) then
                call runtime_error('external input requires a positive bound unit number',lin,col);return
            end if
            if(present(input_units)) then
                do j=1,size(input_units)
                    if(input_units(j)%unit==value%i) u=j
                end do
            end if
            if(u==0) call runtime_error('external input unit is not explicitly bound',lin,col)
        end subroutine
        subroutine input_record(u,record,n,ios,lin,col)
            integer,intent(in)::u,lin,col
            character(*),intent(out)::record
            integer,intent(out)::n,ios
            integer::first,j,code,next
            ! Only pre-authorized caller-owned bytes are accessed. A complete
            ! record is validated before its cursor is committed, even when the
            ! input list needs only a prefix. No native unit or filename exists.
            n=0;ios=0;record='';first=input_units(u)%position;next=first
            if(first>len(input_units(u)%data)) then
                ios=-1
                if(input_units(u)%endfile) ios=1
                input_units(u)%endfile=.true.;return
            end if
            do j=first,len(input_units(u)%data)
                call consume(lin,col)
                if(diag%code/=0) return
                code=iachar(input_units(u)%data(j:j));next=j+1
                if(code==10) exit
                if(code==13.and.j<len(input_units(u)%data)) then
                    if(input_units(u)%data(j+1:j+1)==achar(10)) then
                        call consume(lin,col)
                        if(diag%code/=0) return
                        next=j+2;exit
                    end if
                end if
                if((code<32.and.code/=9).or.code==127) then
                    call runtime_error('external READ requires text records',lin,col);return
                end if
                if(n>=len(record)) then
                    call runtime_error('external READ record exceeds 65536 characters',lin,col);return
                end if
                n=n+1;record(n:n)=input_units(u)%data(j:j)
            end do
            input_units(u)%position=next
        end subroutine
        subroutine execute_inquire_name(ins)
            type(instruction_t),intent(in)::ins
            type(value_t)::unit_value,value
            integer::u,s,n,j,file_symbol
            if(.not.valid_inquire_name(prog,ins))then
                call runtime_error('invalid INQUIRE NAME metadata',ins%line,ins%column);return
            end if
            ! Do not weaken READ's ordinary/PURE policy merely because this
            ! inquiry reads cached metadata rather than consuming a record.
            call check_external_effect(ins%line,ins%column)
            if(diag%code/=0)return
            call check_random_effect(ins%line,ins%column,'INQUIRE')
            if(diag%code/=0)return
            s=prog%expressions(ins%b)%symbol;file_symbol=prog%expressions(ins%a)%symbol
            if(.not.valid_symbol(s))return
            if(refs(s)%active.or.associated(refs(s)%defined,refs(file_symbol)%defined))then
                call runtime_error('invalid INQUIRE NAME target',ins%line,ins%column);return
            end if
            if(prog%symbols(s)%is_allocatable)then
                if(.not.array_available(s,ins%line,ins%column))return
            end if
            call read_character_length(s,n,ins%line,ins%column)
            if(diag%code/=0)return
            if(.not.character_storage_fits(s,1_int64,n))then
                call runtime_error('INQUIRE NAME CHARACTER storage limit exceeded',ins%line,ins%column);return
            end if
            unit_value=evaluate(ins%a,0)
            if(diag%code/=0)return
            if(unit_value%tag/=ty_integer.or.unit_value%real_kind/=prog%symbols(file_symbol)%real_kind)then
                call runtime_error('INQUIRE UNIT value kind/type differs',ins%line,ins%column);return
            end if
            call bound_input_unit(unit_value,u,ins%line,ins%column)
            if(diag%code/=0)return
            if(.not.allocated(input_units(u)%name))then
                call runtime_error('INQUIRE NAME requires a named registered input unit',ins%line,ins%column);return
            end if
            ! Charge copied/padded text before allocating or committing output.
            do j=1,n+len(input_units(u)%name)
                call consume(ins%line,ins%column)
                if(diag%code/=0)return
            end do
            ! Stage padding/truncation before the only target commit. No host
            ! INQUIRE, path lookup, file open, cursor or endfile mutation occurs.
            value=value_t(tag=ty_character,s=input_units(u)%name(:min(n,len(input_units(u)%name)))// &
                repeat(' ',max(0,n-len(input_units(u)%name))))
            refs(s)%value=value;refs(s)%defined=.true.
        end subroutine
        subroutine execute_backspace(ins)
            type(instruction_t),intent(in)::ins
            type(value_t)::value
            integer::u,s,j,file_symbol
            if(.not.valid_backspace(prog,ins)) then
                call runtime_error('invalid BACKSPACE metadata',ins%line,ins%column);return
            end if
            call check_external_effect(ins%line,ins%column)
            if(diag%code/=0) return
            s=0;file_symbol=prog%expressions(ins%a)%symbol
            if(ins%b/=0) then
                s=prog%expressions(ins%b)%symbol
                if(.not.valid_symbol(s)) return
                if(refs(s)%active.or.associated(refs(s)%defined,refs(file_symbol)%defined)) then
                    call runtime_error('invalid BACKSPACE IOSTAT target',ins%line,ins%column);return
                end if
            end if
            value=evaluate(ins%a,0)
            if(diag%code/=0) return
            call bound_input_unit(value,u,ins%line,ins%column)
            if(diag%code/=0) return
            if(input_units(u)%endfile) then
                input_units(u)%endfile=.false.
            else
                ! The cursor always denotes the start of a record or the end
                ! boundary. Skip the preceding terminator, then find that record.
                j=input_units(u)%position-1
                if(j>0) then
                    if(input_units(u)%data(j:j)==achar(10)) j=j-1
                end if
                do while(j>0)
                    call consume(ins%line,ins%column)
                    if(diag%code/=0) return
                    if(input_units(u)%data(j:j)==achar(10)) exit
                    j=j-1
                end do
                input_units(u)%position=j+1
            end if
            if(s/=0) then
                refs(s)%value=value_t(tag=ty_integer,real_kind=prog%symbols(s)%real_kind,i=0_int64)
                refs(s)%defined=.true.
            end if
        end subroutine
        subroutine next_external_input(u,record,n,at,pending_comma,repeat_left,token,length_token,is_null,slash,quoted,ios,lin,col)
            integer,intent(in)::u,lin,col
            character(*),intent(inout)::record,token
            integer,intent(inout)::n,at,length_token
            integer(int64),intent(inout)::repeat_left
            logical,intent(inout)::pending_comma,is_null,slash,quoted
            integer,intent(out)::ios
            integer::first,q,digit
            integer(int64)::repeat_count
            logical::closed
            character::quote,ch
            ios=0
            if(repeat_left>0) then
                repeat_left=repeat_left-1;return
            end if
            is_null=.false.;quoted=.false.;length_token=0
            call external_input_blanks(u,record,n,at,.true.,ios,lin,col)
            if(ios/=0.or.diag%code/=0) return
            if(pending_comma) then
                pending_comma=.false.
                if(record(at:at)==',') then
                    at=at+1;call external_input_blanks(u,record,n,at,.true.,ios,lin,col)
                    if(ios/=0.or.diag%code/=0) return
                end if
            end if
            if(record(at:at)=='/') then
                slash=.true.;return
            end if
            if(record(at:at)==',') then
                at=at+1;is_null=.true.;return
            end if
            first=at;q=at
            do while(q<=n)
                if(record(q:q)<'0'.or.record(q:q)>'9') exit
                q=q+1
            end do
            if(q<=n.and.q>first) then
                if(record(q:q)=='*') then
                    repeat_count=0
                    do at=first,q-1
                        digit=iachar(record(at:at))-iachar('0')
                        if(repeat_count>(huge(0_int64)-digit)/10_int64) then
                            ios=1;return
                        end if
                        repeat_count=10_int64*repeat_count+digit
                    end do
                    if(repeat_count<=0) then
                        ios=1;return
                    end if
                    repeat_left=repeat_count-1;at=q+1
                end if
            end if
            if(at<=n) then
                quote=record(at:at);quoted=quote=="'".or.quote=='"'
                if(quoted) then
                    at=at+1;closed=.false.
                    do
                        if(at>n) then
                            call input_record(u,record,n,ios,lin,col);at=1
                            if(ios/=0.or.diag%code/=0) return
                            cycle
                        end if
                        ch=record(at:at);at=at+1
                        if(ch==quote) then
                            if(at<=n) then
                                if(record(at:at)==quote) then
                                    at=at+1
                                else
                                    closed=.true.;exit
                                end if
                            else
                                closed=.true.;exit
                            end if
                        end if
                        if(length_token>=len(token)) then
                            ios=1;return
                        end if
                        length_token=length_token+1;token(length_token:length_token)=ch
                        if(ios/=0) return
                    end do
                    if(at<=n) then
                        if(index(' ,/'//achar(9),record(at:at))==0) then
                            ios=1;return
                        end if
                    end if
                else
                    do while(at<=n)
                        ch=record(at:at)
                        if(index(' ,/'//achar(9),ch)/=0) exit
                        if(ch=="'".or.ch=='"') then
                            ios=1;return
                        end if
                        if(length_token>=len(token)) then
                            ios=1;return
                        end if
                        length_token=length_token+1;token(length_token:length_token)=ch;at=at+1
                        if(ios/=0) return
                    end do
                end if
            end if
            is_null=length_token==0.and..not.quoted
            ! Consume a same-record comma now; if the record ends, defer its
            ! optional comma to the next request rather than reading ahead.
            call external_input_blanks(u,record,n,at,.false.,ios,lin,col)
            pending_comma=at>n
            if(at<=n) then
                if(record(at:at)==',') at=at+1
            end if
        end subroutine
        subroutine external_input_blanks(u,record,n,at,advance,ios,lin,col)
            integer,intent(in)::u,lin,col
            character(*),intent(inout)::record
            integer,intent(inout)::n,at
            logical,intent(in)::advance
            integer,intent(out)::ios
            ios=0
            do
                do while(at<=n)
                    if(record(at:at)/=' '.and.record(at:at)/=achar(9)) return
                    at=at+1
                end do
                if(.not.advance) return
                call input_record(u,record,n,ios,lin,col);at=1
                if(ios/=0.or.diag%code/=0) return
            end do
        end subroutine
        integer function external_read_element_offset(root,s,lin,col,stat_symbol) result(offset)
            integer,intent(in)::root,s,lin,col,stat_symbol
            type(value_t)::subscripts(3)
            integer::children(3),r,j,e
            offset=0
            if(.not.valid_external_read_element(prog,root,s,scope,stat_symbol))then
                call runtime_error('invalid external READ array element descriptor',lin,col);return
            end if
            r=prog%symbols(s)%rank
            associate(target=>prog%expressions(root))
            children=[target%left,target%right,target%third]
            end associate
            do j=1,r
                e=children(j)
                subscripts(j)=evaluate(e,1)
                if(diag%code/=0)return
                if(subscripts(j)%tag/=ty_integer.or.subscripts(j)%real_kind/=prog%expressions(e)%real_kind)then
                    call runtime_error('external READ subscript value metadata differs',lin,col);return
                end if
                if(.not.check_integer(subscripts(j)%i,lin,col,subscripts(j)%real_kind))return
            end do
            offset=element_offset(s,subscripts(:r),lin,col)
        end function
        subroutine external_character_read(ins,unit_value,stat_symbol)
            type(instruction_t),intent(in)::ins
            type(value_t),intent(in)::unit_value
            integer,intent(in)::stat_symbol
            type(value_t)::value,status_value
            integer::u,j,s,first,last,next,n,ios,code,offset,item,allocation_status,used
            if(unit_value%tag/=ty_integer.or.unit_value%i<=0.or.unit_value%i>2147483647_int64) then
                call runtime_error('external READ requires a positive bound unit number',ins%line,ins%column);return
            end if
            if(.not.present(input_units)) then
                call runtime_error('external READ unit is not explicitly bound',ins%line,ins%column);return
            end if
            u=0
            do j=1,size(input_units)
                if(input_units(j)%unit==unit_value%i) u=j
            end do
            if(u==0) then
                call runtime_error('external READ unit is not explicitly bound',ins%line,ins%column);return
            end if
            item=ins%items(1);s=prog%expressions(item)%symbol;offset=0
            if(prog%expressions(item)%kind==ex_element)then
                ! Freeze each index once before the input cursor, target or
                ! IOSTAT changes; undefined target payload is never read.
                offset=external_read_element_offset(item,s,ins%line,ins%column,stat_symbol)
                if(diag%code/=0)return
            end if
            call read_character_length(s,n,ins%line,ins%column)
            if(diag%code/=0) return
            first=input_units(u)%position;last=first-1;next=first;ios=0
            if(first>len(input_units(u)%data)) then
                ios=-1
                if(input_units(u)%endfile) ios=1
                input_units(u)%endfile=.true.
            else
                do j=first,len(input_units(u)%data)
                    call consume(ins%line,ins%column)
                    if(diag%code/=0) return
                    code=iachar(input_units(u)%data(j:j));next=j+1
                    if(code==10) exit
                    if(code==13) then
                        if(j<len(input_units(u)%data)) then
                            if(input_units(u)%data(j+1:j+1)==achar(10)) then
                                call consume(ins%line,ins%column)
                                if(diag%code/=0) return
                                next=j+2;exit
                            end if
                        end if
                    end if
                    if((code<32.and.code/=9).or.code==127) then
                        call runtime_error('external READ requires text records',ins%line,ins%column);return
                    end if
                    last=j
                    if(last-first+1>65536) then
                        call runtime_error('external READ record exceeds 65536 characters',ins%line,ins%column);return
                    end if
                end do
                value=value_t(tag=ty_character)
                allocate(character(n)::value%s,stat=allocation_status)
                if(allocation_status/=0)then
                    call runtime_error('external READ staging allocation failed',ins%line,ins%column);return
                end if
                value%s(:)=' ';used=min(last-first+1,n)
                if(used>0)value%s(:used)=input_units(u)%data(first:first+used-1)
                ! No allocation or evaluation remains at commit. Other element
                ! values/flags are preserved; scalar behavior stays unchanged.
                if(offset>0)then
                    refs(s)%array%data(offset)=value_t(tag=ty_character)
                    call move_alloc(value%s,refs(s)%array%data(offset)%s)
                    refs(s)%array%flags(offset)=.true.
                else
                    refs(s)%value=value_t(tag=ty_character)
                    call move_alloc(value%s,refs(s)%value%s)
                    refs(s)%defined=.true.
                end if
                input_units(u)%position=next
            end if
            if(ios/=0)then
                if(offset>0)then
                    refs(s)%array%flags(offset)=.false.
                else
                    refs(s)%defined=.false.
                end if
            end if
            if(stat_symbol/=0) then
                status_value=value_t(tag=ty_integer,real_kind=prog%symbols(stat_symbol)%real_kind,i=int(ios,int64))
                refs(stat_symbol)%value=status_value;refs(stat_symbol)%defined=.true.
            else if(ios<0) then
                call runtime_error('end of external READ input',ins%line,ins%column)
            else if(ios>0) then
                call runtime_error('external READ is past the endfile record',ins%line,ins%column)
            end if
        end subroutine
        subroutine check_output_integer_metadata(value,root)
            type(value_t),intent(in)::value
            integer,intent(in)::root
            if(diag%code/=0) return
            associate(e=>prog%expressions(root))
            if(e%typ/=ty_integer.and.value%tag/=ty_integer) return
            ! Bit editing must use the declared integer width, not an unchecked
            ! conflicting value cache. Apply equally to ordinary/array output
            ! and leaf items inside output implied-DOs before staging commits.
            if(e%typ/=value%tag.or.e%real_kind/=value%real_kind) &
                call runtime_error('output INTEGER value metadata differs from expression',e%line,e%column)
            end associate
        end subroutine
        subroutine check_output_character_storage(value,used,lin,col)
            type(value_t),intent(in)::value
            integer(int64),intent(inout)::used
            integer,intent(in)::lin,col
            integer::t,j,n
            integer(int64)::bytes
            if(diag%code/=0) return
            bytes=0_int64
            if(value%tag==ty_character) then
                if(.not.allocated(value%s)) then
                    call runtime_error('invalid CHARACTER output value',lin,col);return
                end if
                bytes=len(value%s,kind=int64)
            else if(is_derived_type(value%tag)) then
                t=value%tag-ty_derived_base
                if(t<1.or.t>prog%nt.or..not.allocated(value%record)) then
                    call runtime_error('invalid derived CHARACTER output value',lin,col);return
                end if
                if(.not.allocated(value%record%components).or..not.allocated(value%record%component_defined)) then
                    call runtime_error('missing derived CHARACTER output components',lin,col);return
                end if
                n=prog%derived_types(t)%ncomponents
                if(n<1.or.n>16.or.size(value%record%components)/=n.or.size(value%record%component_defined)/=n) then
                    call runtime_error('invalid derived CHARACTER output schema',lin,col);return
                end if
                do j=1,n
                    if(prog%derived_types(t)%component_types(j)/=ty_character)cycle
                    associate(c=>value%record%components(j))
                    if(c%tag/=ty_character.or.c%real_kind/=4) then
                        call runtime_error('invalid derived CHARACTER output component',lin,col);return
                    end if
                    if(.not.allocated(c%s))then
                        if(value%record%component_defined(j))then
                            call runtime_error('defined CHARACTER output component payload missing',lin,col);return
                        end if
                        cycle
                    end if
                    if(len(c%s)/=prog%derived_types(t)%component_lengths(j)) then
                        call runtime_error('derived CHARACTER output length differs',lin,col);return
                    end if
                    bytes=bytes+len(c%s,kind=int64)
                    end associate
                end do
            else
                return
            end if
            if(used<0.or.bytes>16777216_int64-used) then
                call runtime_error('output CHARACTER temporary limit exceeded (16777216)',lin,col);return
            end if
            used=used+bytes
        end subroutine
        recursive subroutine formatted_record(fmt,values,record,lin,col,allow_reversion,nonadvancing,initial_tail,final_position)
            character(*),intent(in)::fmt
            type(value_t),intent(in)::values(:)
            character(:),allocatable,intent(out)::record
            integer,intent(in)::lin,col
            type(diagnostic_t)::format_diag
            logical,intent(in),optional::allow_reversion,nonadvancing
            character(*),intent(in),optional::initial_tail
            integer,intent(out),optional::final_position
            type(value_t),allocatable::rendered(:)
            integer::j,ios
            allocate(rendered(size(values)),stat=ios)
            if(ios/=0) then
                call runtime_error('formatted output temporary allocation failed',lin,col);return
            end if
            rendered=values
            do j=1,size(values)
                if(.not.is_derived_type(values(j)%tag)) cycle
                call render_derived(values(j),'DT',rendered(j)%s,lin,col)
                if(diag%code/=0) return
            end do
            call render_print_format(fmt,rendered,record,format_diag,lin,col,allow_reversion,nonadvancing,initial_tail,final_position)
            if(format_diag%code/=0) call runtime_error(format_diag%message,lin,col)
        end subroutine
    end subroutine
    ! The parser and executor share a bounded format program. Group boundaries
    ! are nodes rather than expanded copies, so nested repeat products cannot
    ! allocate an unbounded descriptor list. Only the outer parentheses are free.
    subroutine parse_print_format(fmt,edits,nedit,diag,lin,col,reversion_start)
        character(*),intent(in)::fmt
        integer,intent(in)::lin,col
        type(format_edit_t),intent(out)::edits(64)
        integer,intent(out)::nedit,reversion_start
        type(diagnostic_t),intent(inout)::diag
        character(:),allocatable::text
        character::quote,ch
        integer::i,n,at,total
        nedit=0;reversion_start=1
        if(diag%code/=0) return
        text=''
        quote=achar(0)
        do i=1,len_trim(fmt)
            ch=fmt(i:i)
            if(quote/=achar(0)) then
                text=text//ch
                if(ch==quote) quote=achar(0)
                cycle
            end if
            if(ch=="'".or.ch=='"') then
                quote=ch;text=text//ch;cycle
            end if
            if(ch==' '.or.ch==achar(9)) cycle
            text=text//lower(ch)
        end do
        n=len(text)
        if(n<3) then
            call fail(diag,'PRINT format must be a nonempty parenthesized descriptor list',lin,col);return
        end if
        if(text(1:1)/='('.or.text(n:n)/=')') then
            call fail(diag,'PRINT format must be parenthesized',lin,col);return
        end if
        at=2
        call parse_sequence(total,0)
        if(diag%code/=0) return
        if(at/=n+1) call fail(diag,'invalid PRINT format group syntax',lin,col)
    contains
        recursive subroutine parse_sequence(total,depth)
            integer,intent(out)::total
            integer,intent(in)::depth
            integer::start,k,repeat,ios,opening,child_total,part_total,scan
            logical::unlimited,has_data,colon_item,slash_item
            character::quote,ch
            total=0
            if(depth>31) then
                call fail(diag,'PRINT format group nesting limit exceeded (31)',lin,col);return
            end if
            if(at>n) then
                call fail(diag,'unterminated PRINT format group',lin,col);return
            end if
            if(text(at:at)==')') then
                call fail(diag,'empty PRINT format group is unsupported',lin,col);return
            end if
            do
                if(at>n) then
                    call fail(diag,'unterminated PRINT format group',lin,col);return
                end if
                start=at;k=at;repeat=1;unlimited=.false.;colon_item=text(at:at)==':'
                do while(k<=n)
                    if(text(k:k)<'0'.or.text(k:k)>'9') exit
                    k=k+1
                end do
                if(k>n) then
                    call fail(diag,'invalid PRINT format repeat count',lin,col);return
                end if
                slash_item=text(k:k)=='/'
                if(text(k:k)=='*') then
                    if(k/=at.or.depth/=0) then
                        call fail(diag,'unlimited format item requires a final outer-level *(...) group',lin,col);return
                    end if
                    if(k>=n) then
                        call fail(diag,'unlimited format item requires *(...)',lin,col);return
                    end if
                    k=k+1
                    if(text(k:k)/='(') then
                        call fail(diag,'unlimited format item requires *(...)',lin,col);return
                    end if
                    unlimited=.true.
                end if
                if(colon_item) then
                    if(nedit>=64)then
                        call fail(diag,'invalid or excessive PRINT format descriptors',lin,col);return
                    end if
                    nedit=nedit+1;edits(nedit)%name=':';at=at+1
                else if(slash_item) then
                    if(k>at) then
                        read(text(at:k-1),*,iostat=ios) repeat
                        if(ios/=0) repeat=0
                    end if
                    if(repeat<1.or.repeat>65536) then
                        call fail(diag,'invalid PRINT format repeat count',lin,col);return
                    end if
                    if(nedit>=64) then
                        call fail(diag,'invalid or excessive PRINT format descriptors',lin,col);return
                    end if
                    if(repeat>65536-total) then
                        call fail(diag,'formatted output exceeds 65536 characters',lin,col);return
                    end if
                    nedit=nedit+1;edits(nedit)%name='/';edits(nedit)%repeat=repeat
                    total=total+repeat;at=k+1
                else if(text(k:k)=='(') then
                    if(k>at.and..not.unlimited) then
                        read(text(at:k-1),*,iostat=ios) repeat
                        if(ios/=0) repeat=0
                    end if
                    if(repeat<1.or.repeat>65536) then
                        call fail(diag,'invalid PRINT format repeat count',lin,col);return
                    end if
                    if(nedit>=64) then
                        call fail(diag,'invalid or excessive PRINT format descriptors',lin,col);return
                    end if
                    nedit=nedit+1;opening=nedit
                    edits(opening)%name='(';edits(opening)%repeat=repeat
                    edits(opening)%unlimited=unlimited
                    at=k+1
                    call parse_sequence(child_total,depth+1)
                    if(diag%code/=0) return
                    if(nedit>=64) then
                        call fail(diag,'invalid or excessive PRINT format descriptors',lin,col);return
                    end if
                    nedit=nedit+1;edits(nedit)%name=')';edits(nedit)%matching=opening
                    edits(opening)%matching=nedit
                    if(unlimited) then
                        if(at/=n) then
                            call fail(diag,'unlimited format item must be the last outer-level item',lin,col);return
                        end if
                        has_data=.false.
                        do scan=opening+1,nedit-1
                            select case(edits(scan)%name)
                            case('(',')','q','x','t','tl','tr',':','/')
                            case default
                                has_data=.true.
                            end select
                        end do
                        if(.not.has_data) then
                            call fail(diag,'unlimited format item must contain a data descriptor',lin,col);return
                        end if
                    end if
                    ! The last closed group, excluding the outer parentheses,
                    ! determines Fortran reversion. Its repeat count applies.
                    reversion_start=opening
                    if(child_total>0) then
                        if(repeat>(65536-total)/child_total) then
                            call fail(diag,'formatted PRINT record exceeds 65536 characters',lin,col);return
                        end if
                    end if
                    total=total+repeat*child_total
                else
                    quote=achar(0)
                    do while(at<=n)
                        ch=text(at:at)
                        if(quote/=achar(0)) then
                            if(ch==quote) quote=achar(0)
                        else if(ch=="'".or.ch=='"') then
                            quote=ch
                        else if(ch==','.or.ch==')'.or.ch==':'.or.ch=='/') then
                            exit
                        end if
                        at=at+1
                    end do
                    if(quote/=achar(0)) then
                        call fail(diag,'Invalid quoted format literal',lin,col);return
                    end if
                    if(at==start.or.nedit>=64) then
                        call fail(diag,'invalid or excessive PRINT format descriptors',lin,col);return
                    end if
                    call parse_edit(text(start:at-1),part_total)
                    if(diag%code/=0) return
                    if(part_total>65536-total) then
                        call fail(diag,'formatted PRINT record exceeds 65536 characters',lin,col);return
                    end if
                    total=total+part_total
                end if
                if(at>n) then
                    call fail(diag,'unterminated PRINT format group',lin,col);return
                end if
                if(text(at:at)==')') then
                    at=at+1;return
                end if
                ! Commas may be omitted around colon, before an unprefixed
                ! slash, and after any slash edit. Quoted punctuation is data.
                if(text(at:at)==':'.or.text(at:at)=='/')cycle
                if((colon_item.or.slash_item).and.text(at:at)/=',')cycle
                if(text(at:at)/=',') then
                    call fail(diag,'format items and groups must be comma-separated',lin,col);return
                end if
                at=at+1
                if(at<=n) then
                    if(text(at:at)==')') then
                        call fail(diag,'trailing comma in PRINT format',lin,col);return
                    end if
                end if
            end do
        end subroutine
        subroutine parse_edit(part,total)
            character(*),intent(in)::part
            integer,intent(out)::total
            character(:),allocatable::name,literal
            character::quote,ch
            integer::j,k,start,repeat,width,digits,ios
            logical::have_width,have_digits,have_point,closed
            total=0
            k=1; repeat=1; width=0; digits=0
            do while(k<=len(part))
                if(part(k:k)<'0'.or.part(k:k)>'9') exit
                k=k+1
            end do
            if(k>1) then
                read(part(:k-1),*,iostat=ios) repeat
                if(ios/=0) repeat=0
            end if
            if(repeat<1.or.repeat>65536.or.k>len(part)) then
                call fail(diag,'invalid PRINT format repeat count',lin,col); return
            end if
            if(part(k:k)=="'".or.part(k:k)=='"') then
                if(k>1) then
                    call fail(diag,'quoted format literals do not accept a repeat prefix',lin,col);return
                end if
                quote=part(k:k);literal='';k=k+1;closed=.false.
                do while(k<=len(part))
                    ch=part(k:k);k=k+1
                    if(ch==quote) then
                        if(k<=len(part)) then
                            if(part(k:k)==quote) then
                                literal=literal//quote;k=k+1;cycle
                            end if
                        end if
                        closed=.true.;exit
                    end if
                    literal=literal//ch
                end do
                if(.not.closed.or.k<=len(part)) then
                    call fail(diag,'Invalid quoted format literal',lin,col);return
                end if
                if(len(literal)>65536-total) then
                    call fail(diag,'Formatted record exceeds 65536 characters',lin,col);return
                end if
                if(len(literal)>0) then
                    if(repeat>(65536-total)/len(literal)) then
                        call fail(diag,'Formatted record exceeds 65536 characters',lin,col);return
                    end if
                end if
                nedit=nedit+1;edits(nedit)%name='q';edits(nedit)%repeat=repeat
                edits(nedit)%literal=literal;total=total+repeat*len(literal)
                return
            end if
            start=k
            do while(k<=len(part))
                if(part(k:k)<'a'.or.part(k:k)>'z') exit
                k=k+1
            end do
            name=part(start:k-1)
            select case(name)
            case('a','i','b','o','z','f','e','es','g','l','x','t','tl','tr','dt')
            case default
                call fail(diag,'unsupported PRINT format descriptor',lin,col); return
            end select
            if(name=='t'.or.name=='tl'.or.name=='tr') then
                if(start/=1) then
                    call fail(diag,'T/TL/TR descriptors do not accept a repeat prefix',lin,col);return
                end if
                start=k
                do while(k<=len(part))
                    if(part(k:k)<'0'.or.part(k:k)>'9') exit
                    k=k+1
                end do
                if(k==start.or.k<=len(part)) then
                    call fail(diag,'T/TL/TR require a positive integer position',lin,col);return
                end if
                read(part(start:),*,iostat=ios) width
                if(ios/=0) width=0
                if(width<1.or.width>65536) then
                    call fail(diag,'T/TL/TR position must be between 1 and 65536',lin,col);return
                end if
                nedit=nedit+1;edits(nedit)%name=name;edits(nedit)%width=width
                ! Positioning does not itself transfer characters. Extent and
                ! cursor checks are performed against the staged record.
                return
            end if
            start=k
            do while(k<=len(part))
                if(part(k:k)<'0'.or.part(k:k)>'9') exit
                k=k+1
            end do
            have_width=k>start
            if(have_width) then
                read(part(start:k-1),*,iostat=ios) width
                if(ios/=0) width=-1
                if(width<0.or.width>1024.or.(width==0.and.name/='i'.and.name/='g'.and. &
                   name/='b'.and.name/='o'.and.name/='z'.and.name/='f')) then
                    call fail(diag,'PRINT format width must be between 1 and 1024',lin,col); return
                end if
            end if
            have_digits=.false.; have_point=.false.
            if(k<=len(part)) then
                if(part(k:k)=='.') then
                    have_point=.true.
                    k=k+1; start=k
                    do while(k<=len(part))
                        if(part(k:k)<'0'.or.part(k:k)>'9') exit
                        k=k+1
                    end do
                    have_digits=k>start
                    if(have_digits) then
                        read(part(start:k-1),*,iostat=ios) digits
                        if(ios/=0) digits=-1
                    end if
                end if
            end if
            if(k<=len(part).or.digits<0.or.digits>1024) then
                call fail(diag,'invalid PRINT format descriptor syntax',lin,col); return
            end if
            select case(name)
            case('dt')
                if(have_width.or.have_point) then
                    call fail(diag,'DT supports no tag or parameter list in this subset',lin,col);return
                end if
            case('a')
                if(have_point) then
                    call fail(diag,'A descriptor does not accept decimal places',lin,col); return
                end if
            case('i')
                if(.not.have_width.or.(have_point.and..not.have_digits)) then
                    call fail(diag,'I descriptor requires width and optional minimum digits',lin,col);return
                end if
            case('b','o','z')
                if(.not.have_width.or.(have_point.and..not.have_digits)) then
                    call fail(diag,'B/O/Z descriptors require width and optional minimum digits',lin,col);return
                end if
                if(.not.have_point) digits=1
                if(width>0.and.digits>width) then
                    call fail(diag,'B/O/Z minimum digits must not exceed a positive width',lin,col);return
                end if
            case('l')
                if(.not.have_width.or.have_point) then
                    call fail(diag,'L descriptor requires a width without decimal places',lin,col); return
                end if
            case('g')
                if(have_width.and.width==0) then
                    if(have_point) then
                        call fail(diag,'this subset supports bare G0 without decimal or exponent fields',lin,col);return
                    end if
                else if(.not.have_width.or..not.have_digits) then
                    call fail(diag,'real descriptors require a width and decimal places',lin,col);return
                end if
            case('f','e','es')
                if(.not.have_width.or..not.have_digits) then
                    call fail(diag,'real descriptors require a width and decimal places',lin,col); return
                end if
            case('x')
                if(have_width.or.have_point) then
                    call fail(diag,'X descriptor accepts only a leading repeat count',lin,col); return
                end if
                width=1
            end select
            nedit=nedit+1
            edits(nedit)%name=name; edits(nedit)%repeat=repeat; edits(nedit)%width=width
            edits(nedit)%digits=digits
            ! Preserve just the individual descriptor, not its repeat prefix.
            j=1
            do while(j<=len(part))
                if(part(j:j)<'0'.or.part(j:j)>'9') exit
                j=j+1
            end do
            if(len(part(j:))>len(edits(nedit)%spec)) then
                call fail(diag,'PRINT format descriptor is too long',lin,col); return
            end if
            edits(nedit)%spec=part(j:)
            if(width>0) then
                if(repeat>(65536-total)/width) then
                    call fail(diag,'formatted PRINT record exceeds 65536 characters',lin,col); return
                end if
                total=total+repeat*width
            end if
        end subroutine
    end subroutine
    subroutine next_format_edit(edits,n,at,remaining,operations,index,diag,lin,col)
        type(format_edit_t),intent(in)::edits(:)
        integer,intent(in)::n,lin,col
        integer,intent(inout)::at,remaining(:),operations
        integer,intent(out)::index
        type(diagnostic_t),intent(inout)::diag
        integer::opening
        index=0
        do while(at<=n)
            operations=operations+1
            if(operations>max_format_operations) then
                call fail(diag,'formatted output operation limit exceeded (262144)',lin,col);return
            end if
            select case(edits(at)%name)
            case('(')
                remaining(at)=edits(at)%repeat;at=at+1
            case(')')
                opening=edits(at)%matching
                if(edits(opening)%unlimited) then
                    ! Same-record iteration, not ordinary format reversion.
                    ! Parsing guarantees a data edit; list exhaustion stops at
                    ! that edit, and every traversal still consumes the budget.
                    at=opening+1;cycle
                end if
                remaining(opening)=remaining(opening)-1
                if(remaining(opening)>0) then
                    at=opening+1
                else
                    at=at+1
                end if
            case default
                index=at;at=at+1;return
            end select
        end do
    end subroutine
    subroutine validate_print_format(fmt,types,diag,line,column,counts,allow_reversion)
        character(*),intent(in)::fmt
        integer,intent(in)::types(:)
        type(diagnostic_t),intent(inout)::diag
        integer,intent(in),optional::line,column
        integer(int64),intent(in),optional::counts(:)
        logical,intent(in),optional::allow_reversion
        type(format_edit_t)::edits(64)
        integer,allocatable::expanded(:)
        integer::n,lin,col,j,total,at,ios,reversion_start
        logical::revert
        lin=0;col=0;revert=.false.
        if(present(line)) lin=line
        if(present(column)) col=column
        if(present(allow_reversion)) revert=allow_reversion
        call parse_print_format(fmt,edits,n,diag,lin,col,reversion_start)
        if(diag%code/=0) return
        total=size(types)
        if(present(counts)) then
            if(size(counts)/=size(types)) then
                call fail(diag,'invalid formatted output counts',lin,col);return
            end if
            ! Runtime-sized sections, PACK, array results and dummy arrays have
            ! no fixed descriptor association until their extents are evaluated.
            ! The runtime validates the entire expanded list before output.
            if(any(counts<0)) return
            if(any(counts>max_print_values).or.sum(counts)>max_print_values) then
                call fail(diag,'PRINT expanded value limit exceeded (65536)',lin,col);return
            end if
            total=int(sum(counts))
        end if
        if(total>max_print_values) then
            call fail(diag,'PRINT expanded value limit exceeded (65536)',lin,col);return
        end if
        allocate(expanded(total),stat=ios)
        if(ios/=0) then
            call fail(diag,'formatted output type allocation failed',lin,col);return
        end if
        if(present(counts)) then
            at=0
            do j=1,size(types)
                expanded(at+1:at+int(counts(j)))=types(j);at=at+int(counts(j))
            end do
        else
            expanded=types
        end if
        call validate_format_types(edits,n,expanded,revert,reversion_start,diag,lin,col)
    end subroutine
    subroutine validate_format_types(edits,n,types,revert,reversion_start,diag,lin,col)
        type(format_edit_t),intent(in)::edits(:)
        integer,intent(in)::n,types(:),reversion_start,lin,col
        logical,intent(in)::revert
        type(diagnostic_t),intent(inout)::diag
        integer::i,j,item,typ,previous,operations,at,remaining(64)
        item=0;operations=0;at=1;remaining=0
        do
            previous=item
            do
                call next_format_edit(edits,n,at,remaining,operations,i,diag,lin,col)
                if(diag%code/=0) return
                if(i==0) exit
                if(edits(i)%name==':')then
                    if(item==size(types))return
                    cycle
                end if
                if(edits(i)%name=='/') then
                    ! A scalar internal file and bounded defined child record
                    ! cannot advance. Only an actually reached slash rejects;
                    ! a preceding exhausted-list colon/data edit may stop first.
                    if(.not.revert) then
                        call fail(diag,'slash record editing requires another record; scalar internal/child WRITE is unsupported',lin,col)
                        return
                    end if
                    if(edits(i)%repeat>max_format_operations-operations) then
                        call fail(diag,'formatted output operation limit exceeded (262144)',lin,col);return
                    end if
                    operations=operations+edits(i)%repeat
                    cycle
                end if
                if(edits(i)%name=='x'.or.edits(i)%name=='q'.or.edits(i)%name=='t'.or. &
                   edits(i)%name=='tl'.or.edits(i)%name=='tr') cycle
                do j=1,edits(i)%repeat
                    if(item==size(types)) return
                    operations=operations+1
                    if(operations>max_format_operations) then
                        call fail(diag,'formatted output operation limit exceeded (262144)',lin,col);return
                    end if
                    item=item+1
                    select case(edits(i)%name)
                    case('dt')
                        typ=types(item)
                        if(.not.is_derived_type(typ)) typ=-1
                    case('a');typ=ty_character
                    case('i','b','o','z');typ=ty_integer
                    case('l');typ=ty_logical
                    case('g')
                        typ=ty_real
                        if(edits(i)%width==0) then
                            typ=types(item)
                            if(typ<ty_integer.or.typ>ty_character) then
                                call fail(diag,'G0 requires an intrinsic INTEGER, REAL, LOGICAL or CHARACTER item',lin,col);return
                            end if
                        end if
                    case default;typ=ty_real
                    end select
                    if(types(item)/=typ) then
                        call fail(diag,'PRINT format descriptor and item type differ',lin,col);return
                    end if
                end do
            end do
            if(item==size(types)) return
            if(item==previous) then
                call fail(diag,'format has no data descriptor for remaining output items',lin,col);return
            end if
            if(.not.revert) then
                call fail(diag,'format reversion requires another record; scalar internal/child WRITE is unsupported',lin,col)
                return
            end if
            at=reversion_start;remaining=0
        end do
    end subroutine
    subroutine render_bit_integer(value,edit,fragment,diag,lin,col)
        type(value_t),intent(in)::value
        type(format_edit_t),intent(in)::edit
        character(:),allocatable,intent(out)::fragment
        type(diagnostic_t),intent(inout)::diag
        integer,intent(in)::lin,col
        character(*),parameter::alphabet='0123456789ABCDEF'
        character(64)::raw
        integer::bits,step,group,bit,pos,digit,n,needed,width
        ! Interpret only the declared INTEGER bit width. In particular, an
        ! INTEGER(4) negative value must not acquire 64 sign-extension bits.
        ! No ABS, unsigned host conversion or minimum-negative negation occurs.
        if(value%real_kind/=4.and.value%real_kind/=8) then
            call fail(diag,'B/O/Z requires a valid INTEGER kind 4 or 8 value',lin,col);return
        end if
        if(value%real_kind==4) then
            if(value%i<imin.or.value%i>imax) then
                call fail(diag,'B/O/Z requires a valid INTEGER kind 4 or 8 value',lin,col);return
            end if
        end if
        bits=8*value%real_kind
        select case(edit%name)
        case('b');step=1
        case('o');step=3
        case('z');step=4
        case default
            call fail(diag,'invalid integer bit output descriptor',lin,col);return
        end select
        n=0
        do group=(bits+step-1)/step-1,0,-1
            digit=0
            do bit=step-1,0,-1
                pos=group*step+bit
                if(pos>=bits) cycle
                if(btest(value%i,pos)) digit=digit+2**bit
            end do
            if(n==0.and.digit==0.and.group/=0) cycle
            n=n+1;raw(n:n)=alphabet(digit+1:digit+1)
        end do
        if(value%i==0_int64.and.edit%digits==0) n=0
        needed=max(n,edit%digits);width=edit%width
        if(width==0) width=max(1,needed)
        if(needed>width) then
            fragment=repeat('*',width)
        else
            fragment=repeat(' ',width-needed)//repeat('0',needed-n)//raw(:n)
        end if
    end subroutine
    subroutine render_print_format(fmt,values,record,diag,lin,col,allow_reversion,nonadvancing,initial_tail,final_position)
        character(*),intent(in)::fmt
        type(value_t),intent(in)::values(:)
        character(:),allocatable,intent(out)::record
        type(diagnostic_t),intent(inout)::diag
        integer,intent(in)::lin,col
        type(format_edit_t)::edits(64)
        logical,intent(in),optional::allow_reversion,nonadvancing
        character(*),intent(in),optional::initial_tail
        integer,intent(out),optional::final_position
        integer,allocatable::types(:)
        integer::i,j,n,item,width,ios,used,cursor,record_start,shift,operations,at,remaining(64),reversion_start
        character(1024)::piece
        ! F0.d alone may need 309 integer digits, sign, point and 1024 places.
        ! Keep the existing scratch length for all other descriptors unchanged.
        character(1340)::fzero_piece
        character(65536)::buffer
        character(:),allocatable::fragment,descriptor
        logical::revert,keep_position
        revert=.false.;keep_position=.false.
        if(present(nonadvancing)) keep_position=nonadvancing
        if(present(allow_reversion)) revert=allow_reversion
        if(size(values)>max_print_values) then
            call fail(diag,'PRINT expanded value limit exceeded (65536)',lin,col);return
        end if
        allocate(types(size(values)),stat=ios)
        if(ios/=0) then
            call fail(diag,'formatted output type allocation failed',lin,col);return
        end if
        do i=1,size(values)
            types(i)=values(i)%tag
        end do
        call parse_print_format(fmt,edits,n,diag,lin,col,reversion_start)
        if(diag%code/=0) return
        call validate_format_types(edits,n,types,revert,reversion_start,diag,lin,col)
        if(diag%code/=0) return
        used=0;cursor=0;record_start=0;item=0;operations=0;at=1;remaining=0
        record=''
        if(present(final_position)) final_position=0
        if(present(initial_tail)) then
            if(len(initial_tail)>65536) then
                call fail(diag,'invalid pending output record state',lin,col);return
            end if
            used=len(initial_tail);buffer(:used)=initial_tail
        end if
        records: do
        do
            call next_format_edit(edits,n,at,remaining,operations,i,diag,lin,col)
            if(diag%code/=0) return
            if(i==0) exit
            if(edits(i)%name==':')then
                if(item==size(values))exit records
                cycle
            end if
            ! Cursor and high-water mark are distinct: backward positions
            ! replace transferred characters, while skipped existing text is
            ! preserved. Each record's left tab limit is record_start. The
            ! first is local to this statement, including nonadvancing WRITE.
            select case(edits(i)%name)
            case('/')
                do j=1,edits(i)%repeat
                    operations=operations+1
                    if(operations>max_format_operations) then
                        call fail(diag,'formatted output operation limit exceeded (262144)',lin,col);return
                    end if
                    ! Preserve pending high-water text. Nonadvancing forward
                    ! positioning also contributes blanks before this explicit
                    ! record advance, exactly as for ordinary format reversion.
                    if(keep_position.and.cursor>used) then
                        buffer(used+1:cursor)=repeat(' ',cursor-used);used=cursor
                    end if
                    if(used==65536) then
                        call fail(diag,'formatted output exceeds 65536 characters',lin,col);return
                    end if
                    used=used+1;buffer(used:used)=new_line('a')
                    record_start=used;cursor=used
                end do
                cycle
            case('x','tr')
                shift=edits(i)%width
                if(edits(i)%name=='x') shift=edits(i)%repeat
                if(shift>65536-cursor) then
                    call fail(diag,'formatted output exceeds 65536 characters',lin,col);return
                end if
                cursor=cursor+shift;cycle
            case('t')
                if(edits(i)%width-1>65536-record_start) then
                    call fail(diag,'formatted output exceeds 65536 characters',lin,col);return
                end if
                cursor=record_start+edits(i)%width-1;cycle
            case('tl')
                cursor=max(record_start,cursor-edits(i)%width);cycle
            end select
            do j=1,edits(i)%repeat
                width=edits(i)%width
                if(trim(edits(i)%name)=='q') then
                    if(j>1) exit
                    fragment=repeat(edits(i)%literal,edits(i)%repeat)
                else
                    if(item==size(values)) exit records
                    item=item+1
                    operations=operations+1
                    if(operations>max_format_operations) then
                        call fail(diag,'formatted output operation limit exceeded (262144)',lin,col);return
                    end if
                    if(is_derived_type(values(item)%tag)) then
                        if(.not.allocated(values(item)%s)) then
                            call fail(diag,'defined output record missing',lin,col);return
                        end if
                        fragment=values(item)%s
                    else if(values(item)%tag==ty_character) then
                        if(.not.allocated(values(item)%s)) then
                            call fail(diag,'invalid CHARACTER print value',lin,col); return
                        end if
                        if(width==0) width=len(values(item)%s)
                        if(width>65536-cursor) then
                            call fail(diag,'formatted PRINT record exceeds 65536 characters',lin,col); return
                        end if
                        if(width<=len(values(item)%s)) then
                            fragment=values(item)%s(:width)
                        else
                            fragment=repeat(' ',width-len(values(item)%s))//values(item)%s
                        end if
                    else if(values(item)%tag==ty_integer.and. &
                            (edits(i)%name=='b'.or.edits(i)%name=='o'.or.edits(i)%name=='z')) then
                        call render_bit_integer(values(item),edits(i),fragment,diag,lin,col)
                        if(diag%code/=0) return
                    else if(values(item)%tag==ty_real.and.edits(i)%name=='f'.and.width==0) then
                        if((values(item)%real_kind/=4.and.values(item)%real_kind/=8).or. &
                           .not.ieee_is_finite(values(item)%r)) then
                            call fail(diag,'F0 requires a finite REAL kind 4 or 8 value',lin,col);return
                        end if
                        descriptor='('//trim(edits(i)%spec)//')'
                        if(values(item)%real_kind==4) then
                            ! Defend reusable-API parameter caches before narrowing.
                            if(abs(values(item)%r)>real(huge(0.0_real32),real64)) then
                                call fail(diag,'F0 REAL kind 4 value exceeds its finite range',lin,col);return
                            end if
                            write(fzero_piece,descriptor,iostat=ios) real(values(item)%r,real32)
                        else
                            write(fzero_piece,descriptor,iostat=ios) values(item)%r
                        end if
                        if(ios/=0) then
                            call fail(diag,'formatted PRINT conversion failed',lin,col);return
                        end if
                        fragment=trim(fzero_piece)
                    else
                        descriptor='('//trim(edits(i)%spec)//')'
                        select case(values(item)%tag)
                        case(ty_integer)
                            if(width==0) then
                                write(piece,descriptor,iostat=ios) values(item)%i
                                width=max(1,len_trim(piece))
                            else
                                write(piece(:width),descriptor,iostat=ios) values(item)%i
                            end if
                        case(ty_logical)
                            if(width==0) then
                                write(piece,descriptor,iostat=ios) values(item)%l
                                width=max(1,len_trim(piece))
                            else
                                write(piece(:width),descriptor,iostat=ios) values(item)%l
                            end if
                        case(ty_real)
                            if(width==0) then
                                if((values(item)%real_kind/=4.and.values(item)%real_kind/=8).or. &
                                   .not.ieee_is_finite(values(item)%r)) then
                                    call fail(diag,'G0 requires a finite REAL kind 4 or 8 value',lin,col);return
                                end if
                                if(values(item)%real_kind==4) then
                                    write(piece,descriptor,iostat=ios) real(values(item)%r,real32)
                                else
                                    write(piece,descriptor,iostat=ios) values(item)%r
                                end if
                                width=max(1,len_trim(piece))
                            else if(values(item)%real_kind==4) then
                                write(piece(:width),descriptor,iostat=ios) real(values(item)%r,real32)
                            else
                                write(piece(:width),descriptor,iostat=ios) values(item)%r
                            end if
                        end select
                        if(ios/=0) then
                            call fail(diag,'formatted PRINT conversion failed',lin,col); return
                        end if
                        fragment=piece(:width)
                    end if
                end if
                if(len(fragment)>65536-cursor) then
                    call fail(diag,'formatted output exceeds 65536 characters',lin,col);return
                end if
                if(cursor>used) buffer(used+1:cursor)=repeat(' ',cursor-used)
                buffer(cursor+1:cursor+len(fragment))=fragment
                cursor=cursor+len(fragment);used=max(used,cursor)
            end do
        end do
        if(item==size(values)) exit records
        if(.not.revert) then
            call fail(diag,'format reversion requires another record',lin,col);return
        end if
        if(keep_position.and.cursor>used) then
            buffer(used+1:cursor)=repeat(' ',cursor-used);used=cursor
        end if
        if(used==65536) then
            call fail(diag,'formatted output exceeds 65536 characters',lin,col);return
        end if
        used=used+1;buffer(used:used)=new_line('a');record_start=used;cursor=used
        at=reversion_start;remaining=0
        end do records
        if(keep_position.and.cursor>used) then
            buffer(used+1:cursor)=repeat(' ',cursor-used);used=cursor
        end if
        record=buffer(:used)
        ! Nonadvancing completion leaves the cursor where format control
        ! positioned it, independently of the high-water mark (F2023 12.3.4.4).
        if(present(final_position)) then
            final_position=used
            if(keep_position) final_position=cursor
        end if
    end subroutine
end module
