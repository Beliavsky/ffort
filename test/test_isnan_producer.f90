! SPDX-License-Identifier: MIT
program test_isnan_producer
    use fortfront_compiler
    use fortfront_ast,only:call_or_subscript_node
    implicit none
    character(*),parameter::nl=new_line('a')
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    type(resolved_type_query_t)::typ
    integer::checks,family
    character(:),allocatable::name,source
    opts%input_mode=INPUT_MODE_STANDARD
    opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.;checks=0
    call intrinsic('isnan','isnan(2.)',TLOGICAL,4,0)
    call intrinsic('isnan','isnan(x=2d0)',TLOGICAL,4,0)
    call intrinsic('isnan','isnan([1.,2.])',TLOGICAL,4,1)
    call intrinsic('isnan','isnan(a)',TLOGICAL,4,2,'real(8)::a(2,2)')
    call intrinsic('isnan','isnan(x=a)',TLOGICAL,4,3,'real(8)::a(2,1,2)')
    name='isnan'
    source='program p'//nl//'integer::isnan(2)'//nl//'print *,isnan(1)'//nl//'end program'
    call inspect(source,name,TINT,4,0,.false.,.true.)
    source='program p'//nl//'implicit none'//nl//'print *,isnan(1)'//nl//'contains'//nl// &
        'integer function isnan(x)'//nl//'integer,intent(in)::x'//nl//'isnan=x'//nl// &
        'end function'//nl//'end program'
    call inspect(source,name,TINT,4,0,.false.,.false.)
    print *,'PASS: independent ISNAN producer cases:',checks
contains
    subroutine intrinsic(name,expression,t,k,r,declarations)
        character(*),intent(in)::name,expression
        integer,intent(in)::t,k,r
        character(*),optional,intent(in)::declarations
        character(:),allocatable::s
        s='program p'//nl//'implicit none'//nl
        if(present(declarations))s=s//declarations//nl
        s=s//'print *,'//expression//nl//'end program'
        call inspect(s,name,t,k,r,.true.,.false.)
    end subroutine
    subroutine inspect(source,name,t,k,r,is_intrinsic,is_array)
        character(*),intent(in)::source,name
        integer,intent(in)::t,k,r
        logical,intent(in)::is_intrinsic,is_array
        integer::i,found
        call compile_frontend_from_string(source,front,opts)
        if(.not.front%success())then
            if(allocated(front%error_msg))print *,front%error_msg
            error stop 'ISNAN producer compile failed'
        end if
        found=0
        do i=1,front%arena%entry_count
            if(.not.front%arena%has_node_at(i))cycle
            select type(node=>front%arena%entries(i)%node)
            type is(call_or_subscript_node)
                if(.not.allocated(node%name))cycle
                if(node%name/=name)cycle
                found=found+1;typ=query_resolved_type(front%arena,i)
                if(.not.typ%found.or.typ%type_kind/=t.or.typ%kind_value/=k.or.typ%rank/=r.or. &
                   (node%is_intrinsic.neqv.is_intrinsic).or.(node%is_array_access.neqv.is_array))then
                    print *,source,typ%found,typ%type_kind,typ%kind_value,typ%rank,node%is_intrinsic,node%is_array_access
                    error stop 'ISNAN producer metadata differs'
                end if
            end select
        end do
        if(found/=1)error stop 'ISNAN producer call missing or duplicated'
        checks=checks+1
    end subroutine
end program
