program p
implicit none
integer::i,j
i=2;j=4
if ('abcdef'(i:j)/='bcd') error stop 1
print *, 'runtime bounds' 
end program
