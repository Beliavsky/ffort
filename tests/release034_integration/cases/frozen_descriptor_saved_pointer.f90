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
subroutine visit(char,storage)
integer,allocatable,intent(inout)::char(:)
integer::work(lbound(char,1):ubound(char,1))
integer,intent(out)::storage(4)
integer::flat(extent(size(char))),entry
character(len=size(char))::label
integer,save::calls=0
calls=calls+1
entry=size(char)
work=calls
flat=entry
label='a b '
deallocate(char)
allocate(char(1))
char=99
call prefix(work,min(2,entry))
storage=0
storage(1:entry)=work
if(size(work)/=entry.or.size(flat)/=entry.or.len(label)/=entry) error stop 1
write(*,'("visit:",4(1x,i0)," [",a,"]")')calls,size(char),size(work),sum(flat),label
end subroutine
end module
program main
use m
implicit none
integer,allocatable::data(:)
integer,target::storage(4)
integer,pointer::view(:)
allocate(data(-2:1))
view=>storage
call visit(data,storage)
write(*,'("view:",2(1x,i0))')view
view=>storage(1:1)
call visit(data,storage)
write(*,'("view:",2(1x,i0))')view
deallocate(data)
allocate(data(0))
view=>storage(1:0)
call visit(data,storage)
write(*,'("view:",2(1x,i0))')view
end program
