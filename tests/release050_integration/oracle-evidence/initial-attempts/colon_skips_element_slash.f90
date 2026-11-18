program p

implicit none
character(6)::s(1,1)
write(s(1,1),'(z2.2,:,/)')maskr(4)
print '(a)','['//s(1,1)//']' 
end program
