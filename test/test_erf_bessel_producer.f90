! SPDX-License-Identifier: MIT
program test_erf_bessel_producer
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
    call intrinsic('erf','erf(2.)',TREAL,4,0)
    call intrinsic('erf','erf(x=2d0)',TREAL,8,0)
    call intrinsic('erf','erf([1.,2.])',TREAL,4,1)
    call intrinsic('erf','erf(a)',TREAL,8,2,'real(8)::a(2,2)')
    call intrinsic('erf','erf(x=a)',TREAL,8,3,'real(8)::a(2,1,2)')
    name='erf'
    source='program p'//nl//'integer::erf(2)'//nl//'print *,erf(1)'//nl//'end program'
    call inspect(source,name,TINT,4,0,.false.,.true.)
    call intrinsic('bessel_j0','bessel_j0(2.)',TREAL,4,0)
    call intrinsic('bessel_j0','bessel_j0(x=2d0)',TREAL,8,0)
    call intrinsic('bessel_j0','bessel_j0([1.,2.])',TREAL,4,1)
    call intrinsic('bessel_j0','bessel_j0(a)',TREAL,8,2,'real(8)::a(2,2)')
    call intrinsic('bessel_j0','bessel_j0(x=a)',TREAL,8,3,'real(8)::a(2,1,2)')
    name='bessel_j0'
    source='program p'//nl//'integer::bessel_j0(2)'//nl//'print *,bessel_j0(1)'//nl//'end program'
    call inspect(source,name,TINT,4,0,.false.,.true.)
    call intrinsic('bessel_j1','bessel_j1(2.)',TREAL,4,0)
    call intrinsic('bessel_j1','bessel_j1(x=2d0)',TREAL,8,0)
    call intrinsic('bessel_j1','bessel_j1([1.,2.])',TREAL,4,1)
    call intrinsic('bessel_j1','bessel_j1(a)',TREAL,8,2,'real(8)::a(2,2)')
    call intrinsic('bessel_j1','bessel_j1(x=a)',TREAL,8,3,'real(8)::a(2,1,2)')
    name='bessel_j1'
    source='program p'//nl//'integer::bessel_j1(2)'//nl//'print *,bessel_j1(1)'//nl//'end program'
    call inspect(source,name,TINT,4,0,.false.,.true.)
    call intrinsic('bessel_jn','bessel_jn(2,2.)',TREAL,4,0)
    call intrinsic('bessel_jn','bessel_jn(x=2d0,n=2_8)',TREAL,8,0)
    call intrinsic('bessel_jn','bessel_jn(2,[1.,2.])',TREAL,4,1)
    call intrinsic('bessel_jn','bessel_jn(2,a)',TREAL,8,2,'real(8)::a(2,2)')
    call intrinsic('bessel_jn','bessel_jn(x=a,n=2_8)',TREAL,8,3,'real(8)::a(2,1,2)')
    call intrinsic('bessel_jn','bessel_jn(n,2d0)',TREAL,8,2,'integer::n(2,2)')
    name='bessel_jn'
    source='program p'//nl//'integer::bessel_jn(2)'//nl//'print *,bessel_jn(1)'//nl//'end program'
    call inspect(source,name,TINT,4,0,.false.,.true.)
    call intrinsic('bessel_y0','bessel_y0(2.)',TREAL,4,0)
    call intrinsic('bessel_y0','bessel_y0(x=2d0)',TREAL,8,0)
    call intrinsic('bessel_y0','bessel_y0([1.,2.])',TREAL,4,1)
    call intrinsic('bessel_y0','bessel_y0(a)',TREAL,8,2,'real(8)::a(2,2)')
    call intrinsic('bessel_y0','bessel_y0(x=a)',TREAL,8,3,'real(8)::a(2,1,2)')
    name='bessel_y0'
    source='program p'//nl//'integer::bessel_y0(2)'//nl//'print *,bessel_y0(1)'//nl//'end program'
    call inspect(source,name,TINT,4,0,.false.,.true.)
    call intrinsic('bessel_y1','bessel_y1(2.)',TREAL,4,0)
    call intrinsic('bessel_y1','bessel_y1(x=2d0)',TREAL,8,0)
    call intrinsic('bessel_y1','bessel_y1([1.,2.])',TREAL,4,1)
    call intrinsic('bessel_y1','bessel_y1(a)',TREAL,8,2,'real(8)::a(2,2)')
    call intrinsic('bessel_y1','bessel_y1(x=a)',TREAL,8,3,'real(8)::a(2,1,2)')
    name='bessel_y1'
    source='program p'//nl//'integer::bessel_y1(2)'//nl//'print *,bessel_y1(1)'//nl//'end program'
    call inspect(source,name,TINT,4,0,.false.,.true.)
    call intrinsic('bessel_yn','bessel_yn(2,2.)',TREAL,4,0)
    call intrinsic('bessel_yn','bessel_yn(x=2d0,n=2_8)',TREAL,8,0)
    call intrinsic('bessel_yn','bessel_yn(2,[1.,2.])',TREAL,4,1)
    call intrinsic('bessel_yn','bessel_yn(2,a)',TREAL,8,2,'real(8)::a(2,2)')
    call intrinsic('bessel_yn','bessel_yn(x=a,n=2_8)',TREAL,8,3,'real(8)::a(2,1,2)')
    call intrinsic('bessel_yn','bessel_yn(n,2d0)',TREAL,8,2,'integer::n(2,2)')
    name='bessel_yn'
    source='program p'//nl//'integer::bessel_yn(2)'//nl//'print *,bessel_yn(1)'//nl//'end program'
    call inspect(source,name,TINT,4,0,.false.,.true.)
    print *,'PASS: independent ERF/Bessel producer cases:',checks
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
            error stop 'ERF/Bessel producer compile failed'
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
                    error stop 'ERF/Bessel producer metadata differs'
                end if
            end select
        end do
        if(found/=1)error stop 'ERF/Bessel producer call missing or duplicated'
        checks=checks+1
    end subroutine
end program
