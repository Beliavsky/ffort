program p
implicit none
integer::n
n=-3
select case(n)
case default
print *, 'other'
case(:-1)
print *, 'negative'
case(0)
print *, 'zero'
case(1:3)
print *, 'small'
case(4,6,8)
print *, 'even'
case(9:12)
print *, 'medium'
case(13:)
print *, 'large'
end select
end program p
