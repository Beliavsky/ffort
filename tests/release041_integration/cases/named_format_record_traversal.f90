program p
implicit none
character(len=*),parameter::ordinary='(g0)'
character(len=*),parameter::multiple='(*("p",g0,"s"))'
print ordinary,1,2,3
write(*,multiple) 1,2
end program
