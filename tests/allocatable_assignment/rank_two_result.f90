program probe
implicit none
integer, allocatable :: a(:,:)
a=make()
print *,size(a,1),size(a,2),lbound(a,1),lbound(a,2),a
contains
function make() result(z)
integer,allocatable :: z(:,:)
allocate(z(-1:0,3:4))
z=reshape([1,2,3,4],[2,2])
end function
end program
