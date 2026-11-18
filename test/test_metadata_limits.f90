! SPDX-License-Identifier: MIT
program test_metadata_limits
    use fi_ir, only: program_t, diagnostic_t
    use fi_limits, only: max_symbols, max_procedures, max_generics, max_access_names, max_only_names
    use fi_parser, only: parse_subset
    use fi_driver, only: compile_program
    use fi_frontend, only: verify_frontend
    implicit none
    type(program_t) :: p,bad
    type(diagnostic_t) :: d
    character(:),allocatable :: source
    character(*),parameter :: nl=new_line('a')
    integer :: n,j
    do n=max_symbols-1,max_symbols+1
        source='program main'//nl
        do j=1,n
            source=source//'integer :: v'//number(j)//nl
        end do
        source=source//'end'//nl
        call parse_subset(source,p,d)
        call expect(n<=max_symbols,'Symbol limit exceeded')
    end do
    do n=max_procedures-1,max_procedures+1
        source=procedures(n)
        call parse_subset(source,p,d)
        call expect(n<=max_procedures,'Procedure limit exceeded')
    end do
    do n=max_generics-1,max_generics+1
        source='module library'//nl
        do j=1,n
            source=source//'interface g'//number(j)//nl//'module procedure worker'//nl//'end interface'//nl
        end do
        source=source//'contains'//nl//'subroutine worker()'//nl//'end subroutine'//nl// &
            'end module'//nl//'program main'//nl//'end'//nl
        call parse_subset(source,p,d)
        call expect(n<=max_generics,'Generic interface limit exceeded')
    end do
    ! Overflow must fail before a declaration or an array store is attempted.
    do n=max_access_names-1,max_access_names+1
        source='module library'//nl
        do j=1,n
            source=source//'public :: p'//number(j)//nl
        end do
        source=source//'contains'//nl
        do j=1,min(n,max_procedures)
            source=source//'subroutine p'//number(j)//'()'//nl//'end subroutine'//nl
        end do
        source=source//'end module'//nl//'program main'//nl//'end'//nl
        call parse_subset(source,p,d)
        call expect(n<=max_access_names.and.n<=max_procedures,'Accessibility name limit exceeded')
    end do
    ! Repeated valid ONLY names isolate the list cap from unrelated metadata caps.
    do n=max_only_names-1,max_only_names+1
        source='module library'//nl//'contains'//nl//'subroutine worker()'//nl//'end subroutine'//nl// &
            'end module'//nl//'program main'//nl//'use library, only: worker'
        do j=2,n
            source=source//', &'//nl//'worker'
        end do
        source=source//nl//'end'//nl
        call parse_subset(source,p,d)
        call expect(n<=max_only_names,'ONLY list limit exceeded')
    end do
    ! The sparse traversal must still detect long and disconnected cycles and
    ! propagate ordinary-function external-effect restrictions transitively.
    source=procedures(80,.true.)
    call parse_subset(source,p,d)
    call expect(.false.,'Recursive module function cycles')
    source='module library'//nl//'contains'//nl//'integer function outer()'//nl//'call middle()'//nl// &
        'outer=1'//nl//'end function'//nl//'subroutine middle()'//nl//'call last()'//nl//'end subroutine'//nl// &
        'subroutine last()'//nl//'print *,1'//nl//'end subroutine'//nl//'end module'//nl// &
        'program main'//nl//'end'//nl
    call parse_subset(source,p,d)
    call expect(.false.,'External side effects')
    source='module library'//nl//'interface dispatch'//nl//'module procedure worker'//nl//'end interface'//nl// &
        'contains'//nl//'subroutine worker()'//nl//'end subroutine'//nl//'end module'//nl// &
        'program main'//nl//'use library, only: dispatch'//nl//'call dispatch()'//nl//'end'//nl
    call compile_program(source,p,d)
    call expect(.true.,'')
    bad=p;deallocate(bad%generics)
    d=diagnostic_t();call verify_frontend(source,bad,d)
    call expect(.false.,'generic storage missing')
    bad=p;deallocate(bad%generics);allocate(bad%generics(0))
    d=diagnostic_t();call verify_frontend(source,bad,d)
    call expect(.false.,'generic storage too short')
    bad=p;deallocate(bad%only_names)
    d=diagnostic_t();call verify_frontend(source,bad,d)
    call expect(.false.,'USE ONLY storage missing')
    bad=p;deallocate(bad%only_names);allocate(bad%only_names(1,0))
    d=diagnostic_t();call verify_frontend(source,bad,d)
    call expect(.false.,'USE ONLY storage too short')
    call compile_program('program main'//nl//'end'//nl,p,d)
    call expect(.true.,'')
    print '(a)','PASS: 23 metadata boundary, graph, storage and recovery checks'
contains
    function number(i) result(text)
        integer,intent(in)::i
        character(:),allocatable::text
        character(20)::buffer
        write(buffer,'(i0)') i
        text=trim(buffer)
    end function
    function procedures(n,cycle) result(text)
        integer,intent(in)::n
        logical,intent(in),optional::cycle
        character(:),allocatable::text
        integer::i,target
        text='module library'//nl//'contains'//nl
        do i=1,n
            text=text//'subroutine p'//number(i)//'()'//nl
            if(present(cycle)) then
                if(cycle) then
                    target=mod(i,n)+1
                    text=text//'call p'//number(target)//'()'//nl
                end if
            end if
            text=text//'end subroutine'//nl
        end do
        text=text//'end module'//nl//'program main'//nl//'end'//nl
    end function
    subroutine expect(success,fragment)
        logical,intent(in)::success
        character(*),intent(in)::fragment
        if(success.and.d%code==0) return
        if(.not.success.and.d%code==1) then
            if(index(d%message,fragment)>0) return
        end if
        if(allocated(d%message)) print *,d%message
        error stop 'metadata limit assertion failed'
    end subroutine
end program
