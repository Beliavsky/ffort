program p
implicit none
integer::a(0)
real(8)::b(0)
logical::c(0)
a=7+[integer::]*2
b=[real(8)::]+(-0.0d0)
c=[logical::].or..true.
if(size(a)+size(b)+size(c)/=0) error stop 1
if(size(abs([real(8)::]))/=0) error stop 2
print *, 'PASS' 
end program
