program p
implicit none
select case('abcd')
case(:'a')
print *,0
case('aa':)
print *,1
end select
end program p
