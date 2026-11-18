program p
implicit none
integer(8)::i,j
i=2_8;j=3_8
if('abcd'(i:j)/='bc') error stop 1
print *, 'integer eight' 
end program
