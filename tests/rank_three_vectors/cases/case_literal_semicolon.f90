program p
implicit none
character(3)::s
select case('x')
case('x');s='a;b'
case default;s='no!'
end select
if(s/='a;b')error stop 1
print '(i0)',1
end program
