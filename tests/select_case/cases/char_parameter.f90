program p
implicit none
character(3),parameter::c='abcdef'
select case(c)
case('abc')
print *,1
end select
end program p
