program p
implicit none
integer::i,j
i=-4;j=-5
if(len('abc'(4:3))/=0.or.len('abc'(i:j))/=0.or.len('abc'(8:7))/=0) error stop 1
print *, 'empty ranges' 
end program
