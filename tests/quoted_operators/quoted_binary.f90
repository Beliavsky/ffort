program p
implicit none
character(10)::c
c='x'//'+'//'-'//'*'//'/'//'**'//'//'
if(c/='x+-*/**//') error stop 1
print *, 'quoted binary' 
end program
