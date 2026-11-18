program integrated_wide
implicit none
integer(kind=8) :: n
n=-9223372036854775807_8-1_8
select case(n)
case(:-9223372036854775807_8)
 print '(a)', 'lower wide range'
case default
 stop 'no lower match'
end select
n=9223372036854775807_8
select case(n)
case(9223372036854775806_8:)
 print '(a)', 'upper wide range'
case default
 stop 'no upper match'
end select
end program
