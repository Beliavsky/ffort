module loops
implicit none
contains
integer function compute(n) result(r)
integer,intent(in)::n
integer::i,j
r=0
outer: do i=1,n
j=0
do while(j<2)
j=j+1
r=r+i
if(r>=3)return
end do
end do outer
end function
end module
program main
use loops
implicit none
print '(i0,1x,i0)',compute(3),compute(1)
end
