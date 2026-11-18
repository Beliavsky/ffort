program p
implicit none
character(3)::s='abcdef'(2:4)
if(s/='bcd') error stop 1
print *, 'initializer' 
end program
