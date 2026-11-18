program p
implicit none
integer::v
v=0
select case(2);case(1);v=1;case(2);v=2;case default;v=3;end select
if(v/=2)error stop 1
print '(i0)',1
end program
