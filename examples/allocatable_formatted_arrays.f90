module allocation_output
implicit none
contains
subroutine make(a)
integer,allocatable,intent(out)::a(:)
allocate(a(-1:1))
a=[2,4,6]
end subroutine
subroutine grow(a)
integer,allocatable,intent(inout)::a(:)
a=[a,8]
end subroutine
function selected(a) result(r)
integer,intent(in)::a(:)
integer,allocatable::r(:)
r=pack(a,a>3)
end function
end module
program combined
use allocation_output
implicit none
integer,allocatable::a(:)
character(20)::buffer
call make(a)
print '(3i4)',a
print '(2i4)',lbound(a,1),ubound(a,1)
call grow(a)
print '(2i4)',a
print '(3i4)',selected(a)
write(buffer,'(4i4)')a
print '(a)',buffer
end program
