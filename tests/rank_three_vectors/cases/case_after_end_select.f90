program p
implicit none
integer::v
v=0
select case(1)
case(1);v=7
case default;v=9
end select;v=v+1
if(v/=8)error stop 1
print '(i0)',1
end program
