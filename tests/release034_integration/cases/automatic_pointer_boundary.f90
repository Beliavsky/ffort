module m
implicit none
contains
pure integer function extent(n) result(v)
integer,intent(in)::n
v=n
end function
subroutine prefix(x,n)
integer,intent(in)::n
integer,intent(inout)::x(0:n-1)
x=x+100
end subroutine
subroutine visit(char)
integer,allocatable,intent(inout)::char(:)
integer,target::work(lbound(char,1):ubound(char,1))
integer::flat(extent(size(char))),entry
integer,pointer::view(:)
character(len=size(char))::label
integer,save::calls=0
calls=calls+1
entry=size(char)
work=calls
flat=entry
label='a b '
view=>work
deallocate(char)
allocate(char(1))
char=99
call prefix(work,min(2,entry))
if(size(work)/=entry.or.size(flat)/=entry.or.len(label)/=entry) error stop 1
write(*,'("visit:",4(1x,i0)," [",a,"]")')calls,size(char),size(work),sum(flat),label
write(*,'("view:",2(1x,i0))')view
end subroutine
end module
program main
use m
implicit none
integer,allocatable::data(:)
allocate(data(-2:1))
call visit(data)
call visit(data)
deallocate(data)
allocate(data(0))
call visit(data)
end program
