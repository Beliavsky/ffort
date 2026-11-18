program p
implicit none
integer::i
i=2
if('0123456789'(max(1,i-1):mod(i+3,7))/='01234') error stop 1
print *, 'arithmetic bounds' 
end program
