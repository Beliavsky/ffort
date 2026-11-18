! SPDX-License-Identifier: MIT
program test_char_identifiers
    use fi_ir
    use fi_parser,only:parse_subset
    use fi_frontend,only:verify_frontend
    use fi_runtime,only:execute_program
    use fortfront_compiler
    use fortfront_ast,only:call_or_subscript_node,program_node
    use frontend_compiler_resolution,only:BINDING_FUNCTION,BINDING_GENERIC_INTERFACE
    implicit none
    character(*),parameter::nl=new_line('a')
    character(*),parameter::dummy_source='program p'//nl//'implicit none'//nl// &
        "call take(char='d',other='e')"//nl//'contains'//nl// &
        'subroutine take(char,other)'//nl//'character(*),intent(in)::char,other'//nl// &
        "if(char/='d') error stop 1"//nl//'end subroutine'//nl//'end program'
    character(*),parameter::function_source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'character(1) function char(i) result(value)'//nl//'integer,intent(in)::i'//nl// &
        "value='Z'"//nl//'end function'//nl//'end module'//nl// &
        'program p'//nl//'use m'//nl//'implicit none'//nl// &
        "if(char(65)/='Z') error stop 2"//nl//'end program'
    character(*),parameter::generic_source='module m'//nl//'implicit none'//nl// &
        'interface char'//nl//'module procedure convert'//nl//'end interface'//nl//'contains'//nl// &
        'character(1) function convert(i) result(value)'//nl//'integer,intent(in)::i'//nl// &
        "value='Z'"//nl//'end function'//nl//'end module'//nl// &
        'program p'//nl//'use m'//nl//'implicit none'//nl// &
        "if(char(65)/='Z') error stop 3"//nl//'end program'
    character(*),parameter::intrinsic_source='program p'//nl//'implicit none'//nl// &
        "if(char(65)/='A') error stop 4"//nl//'end program'
    character(*),parameter::array_source='program p'//nl//'implicit none'//nl// &
        'integer::char(2),other(2)'//nl//'char=[1,2]'//nl//'other=[3,4]'//nl// &
        'if(char(2)/=2) error stop 5'//nl//'end program'
    type(program_t)::p
    type(diagnostic_t)::d
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    type(declaration_binding_t)::binding
    character(:),allocatable::source,err
    integer::i,s,e,checks,seen,scope
    checks=0
    call load(dummy_source)
    s=p%procedures(1)%args(1)
    if(p%symbols(s)%name/='char'.or..not.p%symbols(s)%is_dummy) error stop 'dummy identity lost'
    checks=checks+1
    p%symbols(s)%name='wrong'
    call reject('forged CHAR dummy name')
    call load(dummy_source)
    s=p%procedures(1)%args(1)
    do i=1,p%ne
        if(p%expressions(i)%kind/=ex_variable.or.p%expressions(i)%symbol/=s) cycle
        p%expressions(i)%symbol=p%procedures(1)%args(2)
        exit
    end do
    if(i>p%ne) error stop 'dummy reference missing'
    call reject('wrong same-type dummy declaration')
    call load(function_source)
    e=find_expression(ex_user_call)
    p%expressions(e)%kind=ex_call;p%expressions(e)%op='char';p%expressions(e)%symbol=0
    call reject('shadowed function forged as intrinsic CHAR')
    call load(generic_source)
    e=find_expression(ex_user_call)
    p%expressions(e)%kind=ex_call;p%expressions(e)%op='char';p%expressions(e)%symbol=0
    p%expressions(e)%generic_id=0
    call reject('shadowed generic forged as intrinsic CHAR')
    call load(intrinsic_source)
    e=find_expression(ex_call)
    p%expressions(e)%op='achar'
    call reject('wrong intrinsic spelling')
    call load(array_source)
    e=find_expression(ex_element)
    s=p%expressions(e)%symbol
    do i=1,p%ns
        if(p%symbols(i)%name=='other') exit
    end do
    if(i>p%ns.or.i==s) error stop 'other array missing'
    p%expressions(e)%symbol=i
    call reject('wrong CHAR array declaration')
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call producer(array_source)
    seen=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i)) cycle
        select type(n=>front%arena%entries(i)%node)
        type is(call_or_subscript_node)
            if(.not.allocated(n%name)) cycle
            if(n%name/='char') cycle
            typ=query_resolved_type(front%arena,i)
            if(n%is_intrinsic.or..not.n%is_array_access.or..not.typ%found.or. &
               typ%type_kind/=TINT.or.typ%rank/=0.or.typ%kind_value/=4) &
                error stop 'producer shadowed CHAR array metadata'
            seen=seen+1
        end select
    end do
    if(seen/=1) error stop 'producer shadowed CHAR array missing'
    checks=checks+1
    call producer(intrinsic_source)
    seen=0
    do i=1,front%arena%entry_count
        if(.not.front%arena%has_node_at(i)) cycle
        select type(n=>front%arena%entries(i)%node)
        type is(call_or_subscript_node)
            if(.not.allocated(n%name)) cycle
            if(n%name/='char') cycle
            typ=query_resolved_type(front%arena,i)
            if(.not.n%is_intrinsic.or.n%is_array_access.or..not.typ%found.or. &
               typ%type_kind/=TCHAR.or.typ%rank/=0.or.typ%kind_value/=1) &
                error stop 'producer intrinsic CHAR metadata'
            seen=seen+1
        end select
    end do
    if(seen/=1) error stop 'producer intrinsic CHAR missing'
    checks=checks+1
    call producer(function_source)
    call resolve_name_in_scope(front%arena,scope,'char',binding,err)
    if(.not.binding%found.or.binding%binding_kind/=BINDING_FUNCTION) &
        error stop 'producer user CHAR binding missing'
    checks=checks+1
    call producer(generic_source)
    call resolve_name_in_scope(front%arena,scope,'char',binding,err)
    if(.not.binding%found.or.binding%binding_kind/=BINDING_GENERIC_INTERFACE) &
        error stop 'producer generic CHAR binding missing'
    checks=checks+1
    print *, 'PASS: CHAR identifiers, intrinsic preservation, producer and adapter mutations:',checks
contains
    subroutine load(text)
        character(*),intent(in)::text
        source=text
        call parse_subset(source,p,d)
        call okay('parser')
        call verify_frontend(source,p,d)
        call okay('adapter')
        call execute_program(p,d)
        call okay('runtime')
        checks=checks+3
    end subroutine
    subroutine reject(label)
        character(*),intent(in)::label
        call verify_frontend(source,p,d)
        if(d%code==0) then
            print *,label
            error stop 'adapter admitted forged CHAR metadata'
        end if
        checks=checks+1
    end subroutine
    subroutine okay(label)
        character(*),intent(in)::label
        if(d%code/=0) then
            print *,label,': ',d%message
            error stop 'CHAR identifier native check failed'
        end if
    end subroutine
    integer function find_expression(kind) result(index)
        integer,intent(in)::kind
        do index=1,p%ne
            if(p%expressions(index)%kind==kind) return
        end do
        error stop 'expected expression missing'
    end function
    subroutine producer(text)
        character(*),intent(in)::text
        integer::j
        call compile_frontend_from_string(text,front,opts)
        if(.not.front%success()) error stop 'producer failed'
        scope=0
        do j=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(j)) cycle
            select type(n=>front%arena%entries(j)%node)
            type is(program_node)
                if(n%name=='p') scope=j
            end select
        end do
        if(scope==0) error stop 'producer program scope missing'
    end subroutine
end program
