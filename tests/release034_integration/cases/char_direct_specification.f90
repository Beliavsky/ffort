module m
implicit none
contains
pure integer function char(n) result(v)
integer,intent(in)::n
v=n+1
end function
subroutine report(values)
integer,allocatable,intent(in)::values(:)
integer::work(char(size(values)))
character(len=char(size(values)))::word
work=7
word='a b '
write(*,'("word=[",a,"]")')word
write(*,'("values:",2(1x,i0))')work
end subroutine
end module
program main
use m
implicit none
integer,allocatable::data(:)
allocate(data(3))
call report(data)
deallocate(data)
allocate(data(0))
call report(data)
end program
