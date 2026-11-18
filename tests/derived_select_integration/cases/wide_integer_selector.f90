program integrated_wide
implicit none
integer(kind=8) :: n
n=9007199254740993_8
select case(n)
case(9007199254740992_8)
 stop 'rounded selector'
case(9007199254740993_8)
 print '(a)', 'exact wide case'
case default
 stop 'no wide match'
end select
end program
