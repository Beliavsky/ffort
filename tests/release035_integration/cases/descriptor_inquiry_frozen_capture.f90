module composition
implicit none
contains
subroutine host(values)
integer,allocatable,intent(inout)::values(:)
integer::work(size(values)),entry
integer,save::calls=0
entry=size(values)
calls=calls+1
work=calls
call child()
deallocate(values)
allocate(values(1))
values=99
call child()
write(*,'("frozen:",4(1x,i0))')calls,entry,size(work),sum(work)
contains
subroutine child()
work=work+1
end subroutine
end subroutine
end module
program main
use composition
implicit none
integer,allocatable::a(:)
allocate(a(-2:0))
call host(a)
call host(a)
deallocate(a)
allocate(a(0))
call host(a)
end program
