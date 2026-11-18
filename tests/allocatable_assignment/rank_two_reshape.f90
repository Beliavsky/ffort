program probe
implicit none
integer, allocatable :: a(:,:),b(:,:)
allocate(b(-2:-1,5:7))
b=reshape([1,2,3,4,5,6],[2,3])
a=b
print *,lbound(a,1),ubound(a,1),lbound(a,2),ubound(a,2),a
a=reshape([1,2,3,4,5,6],[3,2])
print *,lbound(a,1),ubound(a,1),lbound(a,2),ubound(a,2),a
end program
