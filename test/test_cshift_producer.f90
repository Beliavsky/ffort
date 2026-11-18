! SPDX-License-Identifier: MIT
program test_cshift_producer
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
    call intrinsic('cshift','cshift([1,2,3],1)',TINT,4,1)
    call intrinsic('cshift','cshift([1_8,2_8],-1_8)',TINT,8,1)
    call intrinsic('cshift','cshift(array=a,shift=1,dim=2)',TREAL,8,2,'real(8)::a(2,3)')
    call intrinsic('cshift','cshift(dim=2,shift=[1,0],array=a)',TREAL,4,2,'real::a(2,3)')
    call intrinsic('cshift','cshift(a,1)',TLOGICAL,4,1,'logical::a(3)')
    call intrinsic('cshift','cshift(a,[0,1],2)',TCHAR,1,2,'character(3)::a(2,3)')
    name='cshift'
    source='program p'//nl//'integer::cshift(2)'//nl//'print *,cshift(1)'//nl//'end program'
    call inspect(source,name,TINT,4,0,.false.,.true.)
    source='program p'//nl//'implicit none'//nl//'print *,cshift(1)'//nl//'contains'//nl// &
        'integer function cshift(x)'//nl//'integer,intent(in)::x'//nl//'cshift=x'//nl// &
        'end function'//nl//'end program'
    call inspect(source,name,TINT,4,0,.false.,.false.)
    print *,'PASS: independent CSHIFT producer cases:',checks
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
            error stop 'CSHIFT producer compile failed'
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
                    error stop 'CSHIFT producer metadata differs'
                end if
            end select
        end do
        if(found/=1)error stop 'CSHIFT producer call missing or duplicated'
        checks=checks+1
    end subroutine
end program
