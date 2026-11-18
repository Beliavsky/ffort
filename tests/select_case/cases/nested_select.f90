program p
implicit none
integer::i
do i=1,2
select case(i)
case(1)
select case(.true.)
case(.true.)
print *,11
end select
case default
print *,22
end select
end do
end program p
