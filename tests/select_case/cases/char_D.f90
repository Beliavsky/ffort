program p
implicit none
select case('D')
case('A')
print *,'excellent'
case('B':'D')
print *,'passing'
case default
print *,'other'
end select
end program p
