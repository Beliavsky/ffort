program p

implicit none
character(0)::s(1,1,1)
write(s(1,1,1),'(a)')''
if(maskr(0)/=0)error stop 'zero mask'
print '(a)','['//s(1,1,1)//']' 
end program
