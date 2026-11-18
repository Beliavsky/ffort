! SPDX-License-Identifier: MIT
program test_character_parameters_producer
    use fortfront_compiler
    use fortfront_ast,only:call_or_subscript_node,declaration_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    integer::checks
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.
    opts%run_semantics=.true.
    checks=0
    call check_call('char(65)',0,1)
    call check_call('achar(65_8)',0,1)
    call check_call('char([65,66])',1,1)
    call check_call('achar([65_8,66_8])',1,1)
    call check_call('char(reshape([65,66,67,68],[2,2]))',2,1)
    call check_call('achar(reshape([65_8,66_8,67_8,68_8],[2,2]))',2,1)
    call check_call('char(65,1)',0,1)
    call check_call('achar(65,kind=1_8)',0,1)
    call check_call('char(i=[65,66],kind=1)',1,1)
    call check_call('achar(kind=1,i=reshape([65,66,67,68],[2,2]))',2,1)
    call check_call('char(65,kind=4)',0,4)
    call check_call('achar(kind=4,i=[65,66])',1,4)
    call check_call('char(reshape([65,66,67,68],[2,2]),4)',2,4)
    call check_declarations('character(*),parameter::first=achar(i=65,kind=1),second="tail"',0,0)
    call check_declarations('character(*),parameter::first=merge("ab","cd",.true.),second="tail"',0,0)
    call check_declarations('character(*),parameter::first=merge("ab","cd",mask=.false.),second="tail"',0,0)
    call check_declarations('character(*),parameter::first(2)=[character(3)::"a","bc"],second="tail"',1,0)
    call check_declarations('character(*),parameter::first(0)=[character(7)::],second="tail"',1,0)
    call check_declarations('character(*),parameter::first(0)=(/character(7)::/),second="tail"',1,0)
    call check_declarations('character(*),parameter::first="head",second(0)=[character(7)::]',0,1)
    print *, 'PASS: CHARACTER independent producer metadata and multi-entity declarations:',checks
contains
    subroutine compile(source)
        character(*),intent(in)::source
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl//source//nl// &
            'end program',front,opts)
        if(.not.front%success()) then
            print *,source
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'CHARACTER producer failure'
        end if
    end subroutine
    subroutine check_call(expression,rank,kind_value)
        character(*),intent(in)::expression
        integer,intent(in)::rank,kind_value
        integer::i,found
        call compile('print *,'//expression)
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(call_or_subscript_node)
                if(.not.allocated(node%name)) cycle
                if(node%name/='char'.and.node%name/='achar') cycle
                found=found+1
                typ=query_resolved_type(front%arena,i)
                if(.not.typ%found.or.typ%type_kind/=TCHAR.or.typ%kind_value/=kind_value.or.typ%rank/=rank) then
                    print *,expression,typ%found,typ%type_kind,typ%kind_value,typ%rank
                    error stop 'CHAR/ACHAR producer type/kind/rank differs'
                end if
            end select
        end do
        if(found/=1) error stop 'CHAR/ACHAR producer node missing or duplicated'
        checks=checks+1
    end subroutine
    subroutine check_declarations(declaration,first_rank,second_rank)
        character(*),intent(in)::declaration
        integer,intent(in)::first_rank,second_rank
        integer::i,first_count,second_count,expected_rank
        call compile(declaration)
        first_count=0;second_count=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(declaration_node)
                if(.not.allocated(node%var_name)) cycle
                select case(node%var_name)
                case('first');first_count=first_count+1;expected_rank=first_rank
                case('second');second_count=second_count+1;expected_rank=second_rank
                case default;cycle
                end select
                if(.not.node%is_parameter.or..not.node%has_initializer.or.node%initializer_index<=0) &
                    error stop 'parameter initializer lost in multi-entity declaration'
                if(.not.node%has_character_length.or..not.allocated(node%character_length_expr)) &
                    error stop 'assumed length selector metadata missing'
                if(node%character_length_expr/='*') error stop 'assumed length selector metadata differs'
                typ=query_resolved_type(front%arena,i)
                if(.not.typ%found.or.typ%type_kind/=TCHAR.or.typ%rank/=expected_rank) then
                    print *,node%var_name,typ%found,typ%type_kind,typ%rank,expected_rank
                    error stop 'multi-entity declaration type/rank differs'
                end if
            end select
        end do
        if(first_count/=1.or.second_count/=1) then
            print *,declaration,first_count,second_count
            error stop 'multi-entity declaration lost or duplicated an entity'
        end if
        checks=checks+1
    end subroutine
end program
