program p
implicit none
character(2)::c
c="-"//"x"
if(c/='-x') error stop 1
print *, 'minus concat' 
end program
