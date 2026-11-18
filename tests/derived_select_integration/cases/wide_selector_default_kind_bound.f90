program integrated_wide
implicit none
integer(kind=8) :: n
n=3_8
select case(n)
case(1:3)
 print '(a)', 'cross-kind bound'
case default
 stop 'wrong branch'
end select
end program
