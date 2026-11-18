program main
implicit none
character(3),allocatable::a(:)
a=make()
print *,len(a),lbound(a,1),size(a)
print '(2a4)',a
contains
function make() result(x)
character(3),allocatable::x(:)
allocate(x(-2:-1));x='hi'
end function

end program
