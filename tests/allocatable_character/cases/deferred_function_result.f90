program main
implicit none
character(:),allocatable::a(:)
a=make()
print *,len(a),lbound(a,1),size(a)
print '(2a5)',a
contains
function make() result(x)
character(:),allocatable::x(:)
x=[character(4)::'ab','cdef']
end function

end program
