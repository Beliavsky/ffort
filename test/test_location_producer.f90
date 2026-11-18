! SPDX-License-Identifier: MIT
program test_location_producer
    use fortfront_compiler
    use fortfront_ast,only:call_or_subscript_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    integer::i,found,checks
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.
    opts%run_semantics=.true.
    checks=0
    call check('minloc([3.0d0,1.0d0])',1,4)
    call check('maxloc([3,1],1)',0,4)
    call check('minloc(reshape([3,1,4,2],[2,2]),1)',1,4)
    call check('maxloc(array=[3,1],mask=.true.,kind=8,back=.true.)',1,8)
    call check('minloc([3,1],1,.true.,8,.false.)',0,8)
    call check('maxloc([3,1],.true.,kind=8)',1,8)
    call check('minloc(array=[3,1],kind=2+2)',1,4)
    print *, 'PASS: MINLOC/MAXLOC independent producer metadata:',checks
contains
    subroutine check(expression,rank,kind_value)
        character(*),intent(in)::expression
        integer,intent(in)::rank,kind_value
        call compile_frontend_from_string('program p'//nl//'implicit none'//nl// &
            'print *,'//expression//nl//'end program',front,opts)
        if(.not.front%success()) then
            if(allocated(front%error_msg)) print *,front%error_msg
            error stop 'location producer failure'
        end if
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i)) cycle
            select type(node=>front%arena%entries(i)%node)
            type is(call_or_subscript_node)
                if(.not.allocated(node%name)) cycle
                if(node%name/='minloc'.and.node%name/='maxloc') cycle
                found=found+1
                typ=query_resolved_type(front%arena,i)
                if(.not.typ%found.or.typ%type_kind/=TINT.or.typ%kind_value/=kind_value.or.typ%rank/=rank) then
                    print *,expression,typ%found,typ%type_kind,typ%kind_value,typ%rank
                    error stop 'location producer type/kind/rank differs'
                end if
            end select
        end do
        if(found/=1) error stop 'location producer node missing'
        checks=checks+1
    end subroutine
end program
