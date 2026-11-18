program p

implicit none
character(4)::s(2)
select case(maskr(3))
case(7);write(s(2),'(z2.2)')shiftr(maskl(4),28)
case default;error stop 'wrong branch'
end select
print '(a)','['//s(2)//']' 
end program
