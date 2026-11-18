! SPDX-License-Identifier: MIT
program test_model_decomposition_producer
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
    call intrinsic('fraction','fraction(x=5d0)',TREAL,8,0)
    call intrinsic('fraction','fraction([1.,2.])',TREAL,4,1)
    call intrinsic('exponent','exponent(x=5d0)',TINT,4,0)
    call intrinsic('exponent','exponent(a)',TINT,4,3,'real(8)::a(2,1,2)')
    call intrinsic('set_exponent','set_exponent(i=[1,2],x=5d0)',TREAL,8,1)
    call intrinsic('set_exponent','set_exponent(a,3_8)',TREAL,4,2,'real::a(2,1)')
    call intrinsic('iachar',"iachar('A')",TINT,4,0)
    call intrinsic('iachar',"iachar(kind=8,c=['A','B'])",TINT,8,1)
    call intrinsic('iachar',"iachar(c=a,kind=4+4)",TINT,8,3,'character::a(2,1,2)')
    do family=1,4
        select case(family)
        case(1);name='fraction'
        case(2);name='exponent'
        case(3);name='set_exponent'
        case(4);name='iachar'
        end select
        source='program p'//nl//'integer::'//name//'(2)'//nl//'print *,'//name//'(1)'//nl//'end program'
        call inspect(source,name,TINT,4,0,.false.,.true.)
        source='program p'//nl//'implicit none'//nl//'print *,'//name//'(1)'//nl//'contains'//nl// &
            'integer function '//name//'(x)'//nl//'integer,intent(in)::x'//nl//name//'=x'//nl// &
            'end function'//nl//'end program'
        call inspect(source,name,TINT,4,0,.false.,.false.)
        source='module m'//nl//'implicit none'//nl//'interface '//name//nl// &
            'module procedure f'//nl//'end interface'//nl//'contains'//nl// &
            'integer function f(x)'//nl//'integer,intent(in)::x'//nl//'f=x'//nl//'end function'//nl// &
            'end module'//nl//'program p'//nl//'use m'//nl//'implicit none'//nl// &
            'print *,'//name//'(1)'//nl//'end program'
        call inspect(source,name,TINT,4,0,.false.,.false.)
    end do
    print *,'PASS: independent model decomposition producer cases:',checks
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
            error stop 'model decomposition producer compile failed'
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
                    error stop 'model decomposition producer metadata differs'
                end if
            end select
        end do
        if(found/=1)error stop 'model decomposition producer call missing or duplicated'
        checks=checks+1
    end subroutine
end program
