program p
implicit none
integer::a(3)
a=cshift(make(3,4),1)
if(any(a/=[6,7,5])) error stop 1
print *, "PASS"
contains
recursive function make(n,k) result(r)
integer,intent(in)::n,k
integer::r(n),i
do i=1,n
r(i)=i
end do
if(k>0) r=make(n,k-1)+1
end function
end program
