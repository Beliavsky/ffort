module matrix_storage
implicit none
integer,allocatable::a(:,:)
contains
subroutine reset()
a=reshape([1,2,3,4,5,6],[2,3])
end subroutine
end module
program combined
use matrix_storage
implicit none
call reset()
print '(3i4)',a
print '(2i4)',a(2:1:-1,3:1:-1)
print '(3i4)',sum(a,dim=1)
print '(2i4)',minloc(a),maxloc(a)
deallocate(a)
print '(l2)',allocated(a)
end program
