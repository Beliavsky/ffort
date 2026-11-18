! SPDX-License-Identifier: MIT
! Independent adapter agreement and public-runtime malformed-IR boundary tests.
program test_allocatable_character_lengths
    use, intrinsic :: iso_fortran_env, only: output_unit, error_unit
    use fi_ir
    use fi_parser, only: parse_subset
    use fi_frontend, only: verify_frontend
    use fi_runtime, only: execute_program
    implicit none
    character(*), parameter :: nl=new_line('a')
    character(*), parameter :: source='module m'//nl//'implicit none'//nl//'contains'//nl// &
        'subroutine fill(a,n)'//nl//'integer,intent(in)::n'//nl// &
        'character(len=max(n,1)),allocatable,intent(out)::a(:)'//nl// &
        'allocate(a(1))'//nl//'a="abcd"'//nl// &
        'if(len(a)/=4.or.a(1)/="abcd") error stop 1'//nl// &
        'end subroutine'//nl//'end module'//nl// &
        'program main'//nl//'use m'//nl//'implicit none'//nl// &
        'character(4),allocatable::x(:)'//nl//'call fill(n=4,a=x)'//nl// &
        'if(len(x)/=4.or.size(x)/=1.or.x(1)/="abcd") error stop 2'//nl//'end program'
    type(program_t) :: p,q
    type(diagnostic_t) :: d
    integer :: dummy,owner,root,arg,literal,which,checks,j,ios,repeat,pos
    character(160) :: label
    character(80) :: output_line
    character(:),allocatable :: altered,minimal

    checks=0
    close(output_unit)
    open(unit=output_unit,status='scratch',action='readwrite',form='formatted')
    call parse_subset(source,p,d)
    call expect(d%code==0,'baseline parse')
    dummy=0
    do j=1,p%ns
        if(p%symbols(j)%name=='a'.and.p%symbols(j)%is_dummy) dummy=j
    end do
    call expect(dummy>0,'find explicit-length allocatable dummy')
    owner=p%symbols(dummy)%scope
    root=p%symbols(dummy)%length_expr
    call expect(root>0.and.root<=p%ne,'find length expression')
    call expect(allocated(p%expressions(root)%args),'find MAX arguments')
    call expect(size(p%expressions(root)%args)==2,'MAX has two arguments')
    arg=p%expressions(root)%args(1)
    literal=p%expressions(root)%args(2)
    call expect(valid_character_length_dummy(p,dummy),'honest explicit-length dummy gate')
    call verify_frontend(source,p,d)
    call expect(d%code==0,'baseline independent adapter')
    do repeat=1,3
        d=diagnostic_t()
        call clear_output()
        call execute_program(p,d)
        call expect(d%code==0,'fresh activation baseline')
        call expect_empty_output('baseline is silent')
    end do

    do which=1,30
        q=p
        select case(which)
        case(1);q%symbols(dummy)%length_expr=q%ne+1;label='out-of-range length expression'
        case(2);q%symbols(dummy)%length_expr=-1;label='negative length expression'
        case(3);q%expressions(root)%args(1)=root;label='cyclic length expression'
        case(4);q%expressions(root)%typ=ty_real;label='non-INTEGER length expression'
        case(5);q%expressions(root)%rank=1;label='nonscalar length expression'
        case(6);q%expressions(root)%scope=0;label='wrong expression scope'
        case(7);q%expressions(root)%real_kind=16;label='unsupported expression kind'
        case(8);q%expressions(arg)%symbol=0;label='missing input binding'
        case(9);q%expressions(arg)%symbol=q%ns+1;label='out-of-range input binding'
        case(10);q%symbols(dummy)%character_len=4;label='fixed and dynamic length both supplied'
        case(11);q%symbols(dummy)%deferred_character=.true.;label='deferred dynamic dummy'
        case(12);q%symbols(dummy)%is_optional=.true.;label='optional dynamic dummy'
        case(13);q%symbols(dummy)%is_allocatable=.false.;label='nonallocatable dynamic dummy'
        case(14);q%symbols(dummy)%rank=0;label='scalar allocatable dummy'
        case(15);q%symbols(dummy)%rank=4;label='rank-four allocatable dummy'
        case(16);q%symbols(dummy)%dummy_intent=0;label='missing intent'
        case(17);q%symbols(dummy)%dummy_intent=4;label='invalid intent'
        case(18);q%symbols(dummy)%scope=0;label='missing procedure owner'
        case(19);q%symbols(dummy)%scope=q%np+1;label='out-of-range procedure owner'
        case(20);q%procedures(owner)%args=[p%expressions(arg)%symbol];label='dummy omitted from owner arguments'
        case(21);q%symbols(dummy)%initializer_expr=literal;label='dummy initializer'
        case(22);q%symbols(dummy)%is_dummy=.false.;label='dummy flag removed'
        case(23);q%symbols(dummy)%real_kind=8;label='nondefault CHARACTER kind'
        case(24);q%symbols(dummy)%is_automatic=.true.;label='automatic allocatable dummy'
        case(25);q%symbols(dummy)%assumed_shape=.true.;label='assumed-shape allocatable dummy'
        case(26);q%symbols(dummy)%is_pointer=.true.;label='pointer allocatable dummy'
        case(27);q%symbols(dummy)%is_saved=.true.;label='saved allocatable dummy'
        case(28);q%symbols(dummy)%is_parameter=.true.;label='parameter allocatable dummy'
        case(29);q%symbols(dummy)%is_class=.true.;label='class CHARACTER dummy'
        case(30);q%symbols(dummy)%is_intrinsic=.true.;label='intrinsic dummy'
        end select
        call expect(.not.valid_character_length_dummy(q,dummy),trim(label)//' gate')
        d=diagnostic_t()
        call verify_frontend(source,q,d)
        call expect(d%code==1,trim(label)//' adapter')
        d=diagnostic_t()
        call clear_output()
        call execute_program(q,d)
        call expect(d%code==2,trim(label)//' direct runtime')
        call expect(allocated(d%message),trim(label)//' runtime diagnostic exists')
        call expect_empty_output(trim(label)//' is silent')
    end do

    ! Removing the length root produces the existing legal assumed-length IR.
    ! Source/IR agreement must reject it, but runtime cannot infer discarded text.
    q=p
    q%symbols(dummy)%length_expr=0
    call expect(.not.valid_character_length_dummy(q,dummy),'missing dynamic root gate')
    d=diagnostic_t()
    call verify_frontend(source,q,d)
    call expect(d%code==1,'source agreement rejects missing length root')

    ! This different source gives the same length for n=4. Adapter identity must
    ! be structural, not a one-input evaluation comparison. Honest changed source
    ! is parsed independently to prove it is otherwise accepted.
    altered=source
    pos=index(altered,'max(n,1)')
    call expect(pos>0,'locate source length expression')
    altered(pos:pos+7)='max(n,0)'
    d=diagnostic_t()
    call verify_frontend(altered,p,d)
    call expect(d%code==1,'same-valued changed source text rejected')
    d=diagnostic_t()
    call parse_subset(altered,q,d)
    call expect(d%code==0,'changed source independently parses')
    call verify_frontend(altered,q,d)
    call expect(d%code==0,'changed source independent adapter baseline')
    call clear_output()
    d=diagnostic_t()
    call execute_program(q,d)
    call expect(d%code==0,'changed source has same runtime value')
    call expect_empty_output('changed-source baseline is silent')

    ! A body that never reads the dummy prevents body-expression validation
    ! from hiding a positive cached-length bypass in association preflight.
    minimal='module z'//nl//'implicit none'//nl//'contains'//nl// &
        'subroutine unused(a,n)'//nl//'integer,intent(in)::n'//nl// &
        'character(len=n),allocatable,intent(out)::a(:)'//nl// &
        'return'//nl//'end subroutine'//nl//'end module'//nl// &
        'program main'//nl//'use z'//nl//'implicit none'//nl// &
        'character(4),allocatable::x(:)'//nl//'call unused(x,4)'//nl//'end program'
    d=diagnostic_t()
    call parse_subset(minimal,p,d)
    call expect(d%code==0,'unused-dummy baseline parse')
    call verify_frontend(minimal,p,d)
    call expect(d%code==0,'unused-dummy baseline adapter')
    dummy=0
    do j=1,p%ns
        if(p%symbols(j)%name=='a'.and.p%symbols(j)%is_dummy) dummy=j
    end do
    call expect(dummy>0,'find unused allocatable dummy')
    call expect(valid_character_length_dummy(p,dummy),'unused dynamic dummy gate')
    call clear_output()
    d=diagnostic_t()
    call execute_program(p,d)
    call expect(d%code==0,'unused-dummy baseline runtime')
    call expect_empty_output('unused-dummy baseline is silent')
    q=p
    q%symbols(dummy)%character_len=4
    call expect(.not.valid_character_length_dummy(q,dummy),'unused positive-cache mutation gate')
    d=diagnostic_t()
    call verify_frontend(minimal,q,d)
    call expect(d%code==1,'unused positive-cache mutation adapter')
    d=diagnostic_t()
    call clear_output()
    call execute_program(q,d)
    call expect(d%code==2,'unused positive-cache mutation direct runtime')
    call expect_empty_output('unused positive-cache mutation is silent')

    close(output_unit)
    write(error_unit,'(a,i0,a)') 'PASS: ',checks,' explicit-length allocatable CHARACTER checks'
contains
    subroutine expect(ok,description)
        logical,intent(in) :: ok
        character(*),intent(in) :: description
        checks=checks+1
        if(.not.ok) then
            write(error_unit,'(a)') 'FAIL: '//description
            if(allocated(d%message)) write(error_unit,'(a)') d%message
            error stop 1
        end if
    end subroutine
    subroutine clear_output()
        rewind(output_unit)
        endfile(output_unit)
        rewind(output_unit)
    end subroutine
    subroutine expect_empty_output(description)
        character(*),intent(in) :: description
        rewind(output_unit)
        read(output_unit,'(a)',iostat=ios) output_line
        call expect(ios<0,description)
    end subroutine
end program
