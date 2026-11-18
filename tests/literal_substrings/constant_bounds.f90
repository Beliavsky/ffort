program p
implicit none
if ('abcdef'(2:4)/='bcd') error stop 1
print *, 'constant bounds' 
end program
