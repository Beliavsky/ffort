program p
implicit none
integer::v
v=0
select case(1)
case(1) ! ordinary multiline body
v=7
case default ! not selected
v=9
end select
if(v/=7)error stop 1
print '(i0)',1
end program
