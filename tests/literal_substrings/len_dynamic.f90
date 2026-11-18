program p
implicit none
integer::i,j
i=2;j=4
if(len('abcdef'(i:j))/=3.or.len('abc'(j:i))/=0) error stop 1
print *, 'len dynamic' 
end program
