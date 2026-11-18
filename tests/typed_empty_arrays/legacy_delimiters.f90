program p
implicit none
integer::a(0)
real(8)::b(0)
logical::c(0)
a=(/integer::/)
b=(/real(kind=8)::/)
c=(/logical::/)
if(size(a)+size(b)+size(c)/=0) error stop 1
if(kind((/real(8)::/))/=8) error stop 2
print *, 'PASS' 
end program
