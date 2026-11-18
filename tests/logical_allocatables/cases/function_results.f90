program p
logical,allocatable::a(:),b(:,:),c(:,:,:)
a=vec();b=mat();c=tensor(2)
print *,a,b,c,lbound(c,3)
c=tensor(0)
print *,allocated(c),size(c),size(c,1),size(c,2),size(c,3)
contains
function vec() result(x)
logical,allocatable::x(:)
x=[.true.,.false.]
end function
function mat() result(x)
logical,allocatable::x(:,:)
allocate(x(1,2));x=.false.
end function
function tensor(n) result(x)
integer,intent(in)::n
logical,allocatable::x(:,:,:)
allocate(x(2,1,7:6+n));x=.true.
end function
end program
