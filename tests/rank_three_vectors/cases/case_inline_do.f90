program p
implicit none
integer::v,j
v=0
select case(1)
case(1);do j=1,3
v=v+j
end do
case default;v=9
end select
if(v/=6)error stop 1
print '(i0)',1
end program
