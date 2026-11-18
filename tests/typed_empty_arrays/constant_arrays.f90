program p
implicit none
integer(8),parameter::a(0)=[integer(8)::]
real(8),parameter::b(0)=[real(8)::]
logical,parameter::c(0)=[logical::]
if(size(a)+size(b)+size(c)/=0) error stop 1
print *, 'PASS' 
end program
