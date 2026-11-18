program p
implicit none
select case('AA')
case('A')
print *,'excellent'
case('B':'D')
print *,'passing'
case default
print *,'other'
end select
end program p
