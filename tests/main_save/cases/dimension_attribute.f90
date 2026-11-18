program p
implicit none
integer,dimension(-1:0,2:3),save :: a=reshape([1,2,3,4],[2,2])
a=a+1
print *,a,lbound(a,1),lbound(a,2),ubound(a,1),ubound(a,2)
end program
