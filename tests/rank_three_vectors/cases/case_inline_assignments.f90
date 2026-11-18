program p
implicit none
integer::n,v
v=0
do n=1,4
select case(n)
case(1);v=v+1
case(2:3);v=v+n
case default;v=v+4
end select
end do
if(v/=10)error stop 1
print '(i0)',1
end program
