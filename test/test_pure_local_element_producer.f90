! Unbuilt proposal: run only after reviewed producer correction.
program test_pure_local_element_producer
    use fortfront_compiler, only: compiler_frontend_options_t,compiler_frontend_result_t, &
        compile_frontend_from_string,INPUT_MODE_STANDARD,OPERATING_MODE_STRICT
    implicit none
    type(compiler_frontend_options_t)::opts
    type(compiler_frontend_result_t)::front
    character(*),parameter::nl=new_line('a')
    character(:),allocatable::source
    integer::checks
    checks=0
    opts%input_mode=INPUT_MODE_STANDARD;opts%operating_mode=OPERATING_MODE_STRICT
    opts%standardize=.false.;opts%run_semantics=.true.
    call test('character(8)::a(2)'//nl//'integer::i'//nl//'i=2'//nl// &
        'a(2)="71"'//nl//'read(a(i),*)n',.true.,'local CHARACTER element')
    call test('integer::u'//nl//'u=12'//nl//'read(u,*)n',.false.,'external INTEGER unit')
    call test('read(*,*)n',.false.,'external star unit')
    call test('character(8)::a'//nl//'a="71"'//nl//'read(a,*)n',.false., &
        'preexisting scalar context remains unchanged')
    call test('character(8),save::a(2)'//nl//'read(a(1),*)n',.false.,'saved array excluded')
    call test('character(8),pointer::a(:)'//nl//'read(a(1),*)n',.false.,'pointer array excluded')
    call test('character(8)::a(2)'//nl//'read(a(1:2),*)n',.false.,'section index')
    call test('character(8)::a(2)'//nl//'read(a(abs(1)),*)n',.false.,'intrinsic index call')
    call test('character(8)::a(2)'//nl//'integer::i(2)'//nl//'read(a(i(1)),*)n', &
        .false.,'nested array index')
    call test('character(8)::a(2)'//nl//'read(a(1.0),*)n',.false.,'real index')
    call test('character(8)::a(2)'//nl//'read(a(1),"(i2)")n',.false.,'formatted non-list')
    call test('character(8)::a(2)'//nl//'read(a(1),*,iomsg=a(2))n',.false.,'extra control')
    call test('character(8)::a(2)'//nl//'integer::i'//nl//'i=1'//nl// &
        'read(a(-(i-2)),*)n',.true.,'arithmetic index')
    call test('character(8)::a(2)'//nl//'read(a(2),*)n',.true.,'simple integer literal')
    call storage_case('integer::host_n','integer,intent(out)::n','', &
        'read(a(1),*)host_n',.false.,'host target')
    call storage_case('integer::host_ios','integer,intent(out)::n','', &
        'read(a(1),*,iostat=host_ios)n',.false.,'host status')
    call storage_case('','integer,intent(in)::n','', &
        'read(a(1),*)n',.false.,'INTENT IN target')
    call storage_case('','integer,intent(out)::n','integer,save::m', &
        'read(a(1),*)m',.false.,'saved target')
    call storage_case('','integer,intent(out)::n','integer,pointer::m', &
        'read(a(1),*)m',.false.,'pointer target')
    call storage_case('','integer,intent(inout)::n','', &
        'read(a(1),*)n',.true.,'INTENT INOUT target')
    call storage_case('','integer,intent(out)::n','integer::m,ios', &
        'read(a(1),*,iostat=ios)m',.true.,'local target and status')
    call storage_case('','integer,intent(out)::n','integer,save::ios', &
        'read(a(1),*,iostat=ios)n',.false.,'saved status')
    call storage_case('','integer,intent(out)::n','real::ios', &
        'read(a(1),*,iostat=ios)n',.false.,'noninteger status')
    call storage_case('type::box'//nl//'integer::i'//nl//'end type', &
        'integer,intent(out)::n','type(box)::m', &
        'read(a(1),*)m',.false.,'derived target')
    print *, 'PURE local element producer checks: ',checks
contains
    subroutine storage_case(outer, dummy, local, stmt, want, label)
        character(*),intent(in)::outer,dummy,local,stmt,label
        logical,intent(in)::want
        source='program p'//nl//'implicit none'//nl//outer//nl//'contains'//nl// &
            'pure subroutine s(n)'//nl//dummy//nl//'character(8)::a(2)'//nl// &
            local//nl//stmt//nl//'end subroutine'//nl//'end program'
        call compile_frontend_from_string(source,front,opts)
        if(front%success().neqv.want)then
            print *, 'FAIL: ',label
            stop 1
        end if
        checks=checks+1
    end subroutine
    subroutine test(body,want,label)
        character(*),intent(in)::body,label
        logical,intent(in)::want
        source='program p'//nl//'implicit none'//nl//'contains'//nl// &
            'pure subroutine s(n)'//nl//'integer,intent(out)::n'//nl//body//nl// &
            'end subroutine'//nl//'end program'
        call compile_frontend_from_string(source,front,opts)
        if(front%success().neqv.want)then
            print *, 'FAIL: ',label
            stop 1
        end if
        checks=checks+1
    end subroutine
end program
