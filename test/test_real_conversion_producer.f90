! SPDX-License-Identifier: MIT
program test_real_conversion_producer
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
    call intrinsic('real','real(1d0)',TREAL,4,0)
    call intrinsic('real','real(1_8)',TREAL,4,0)
    call intrinsic('real','real(a=5d0,kind=8)',TREAL,8,0)
    call intrinsic('real','real(kind=8,a=[1.,2.])',TREAL,8,1)
    call intrinsic('real','real(a,4)',TREAL,4,3,'real(8)::a(2,1,2)')
    call intrinsic('real','real(kind=4,a=a)',TREAL,4,3,'integer(8)::a(2,1,2)')
    call intrinsic('real','real(a)',TREAL,4,2,'real(8)::a(2,1)')
    call intrinsic('real','real(kind=4+4,a=1.5)',TREAL,8,0)
    call intrinsic('real','real(kind=dp,a=1)',TREAL,8,0,'integer,parameter::dp=kind(1d0)')
    call intrinsic('real','real(a,kind=8)',TREAL,8,2,'integer::a(0,2)')
    print *,'PASS: independent REAL conversion producer cases:',checks
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
            error stop 'REAL conversion producer compile failed'
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
                    error stop 'REAL conversion producer metadata differs'
                end if
            end select
        end do
        if(found/=1)error stop 'REAL conversion producer call missing or duplicated'
        checks=checks+1
    end subroutine
end program
