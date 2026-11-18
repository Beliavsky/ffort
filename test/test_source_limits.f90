! SPDX-License-Identifier: MIT
program test_source_limits
    use fi_ir, only: program_t, diagnostic_t
    use fi_limits, only: max_source_bytes, max_tokens
    use fi_parser, only: parse_subset
    use fi_driver, only: compile_program
    implicit none
    type(program_t) :: prog
    type(diagnostic_t) :: diag
    character(:), allocatable :: source
    character(*), parameter :: nl=new_line('a'), base='program p'//nl//'end'//nl
    integer :: n

    ! Direct library callers must obey exactly the same byte limit as the CLI.
    do n=max_source_bytes-1,max_source_bytes+1
        source=padded(n)
        call parse_subset(source,prog,diag)
        call expect(n<=max_source_bytes,'parser source boundary','Source exceeds')
    end do
    source=padded(max_source_bytes)
    call compile_program(source,prog,diag)
    call expect(.true.,'full frontend at exact byte boundary','')
    source=padded(max_source_bytes+1)
    call compile_program(source,prog,diag)
    call expect(.false.,'compile API above byte boundary','Source exceeds')

    ! BASE has five real tokens, one synthetic EOL and one EOF. Every leading
    ! newline contributes one token, so these are exact token boundary probes.
    do n=max_tokens-1,max_tokens+1
        source=repeat(nl,n-7)//base
        call parse_subset(source,prog,diag)
        call expect(n<=max_tokens,'parser token boundary','Token limit exceeded')
    end do

    ! A previous limit error must not poison a later compilation in this process.
    call compile_program(base,prog,diag)
    call expect(.true.,'recovery after limit error','')
    print '(a)','PASS: 9 direct source/token boundary and recovery checks'
contains
    function padded(n) result(text)
        integer, intent(in) :: n
        character(:), allocatable :: text
        integer :: remaining
        character(*), parameter :: comment='!'//repeat('x',127)//nl
        remaining=n-len(base)
        text=repeat(comment,remaining/len(comment))
        remaining=mod(remaining,len(comment))
        if(remaining==1) text=text//nl
        if(remaining>1) text=text//'!'//repeat('x',remaining-2)//nl
        text=text//base
        if(len(text)/=n) error stop 'source boundary fixture size is wrong'
    end function

    subroutine expect(success,label,fragment)
        logical, intent(in) :: success
        character(*), intent(in) :: label,fragment
        if(success.and.diag%code==0) return
        if(.not.success.and.diag%code==1) then
            if(index(diag%message,fragment)>0) return
        end if
        print *, label,': ',diag%code,diag%message
        error stop 'source/token boundary assertion failed'
    end subroutine
end program
