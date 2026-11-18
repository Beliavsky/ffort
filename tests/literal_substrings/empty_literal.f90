program p
implicit none
integer::i
i=1
if(len(''(:))/=0.or.len(''(i:0))/=0) error stop 1
print *, 'empty literal' 
end program
