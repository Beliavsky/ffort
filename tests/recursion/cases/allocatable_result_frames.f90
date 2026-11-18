program p
implicit none
integer,allocatable::a(:)
a=make(5)
print *,a
a=make(0)
print *,size(a)
contains
recursive function make(n) result(a)
integer,intent(in)::n
integer,allocatable::a(:),b(:)
if(n==0) then
allocate(a(0))
else
b=make(n-1)
a=[b,n]
end if
end function
end program
