program p
implicit none
integer::n,v
v=0
do n=1,4
select case(n)
case(1);call bump(v,1)
case(2,3);call bump(v,n)
case default;call bump(v,4)
end select
end do
if(v/=10)error stop 1
print '(i0)',1
contains
subroutine bump(v,n)
integer,intent(inout)::v
integer,intent(in)::n
v=v+n
end subroutine
end program
