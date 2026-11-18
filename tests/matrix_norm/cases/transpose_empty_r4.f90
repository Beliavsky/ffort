program p
implicit none
real::a(2,0),b(0,2)
b=transpose(matrix=a)
if(any(shape(transpose(a))/=[0,2]).or.size(b)/=0) error stop 1
end program
