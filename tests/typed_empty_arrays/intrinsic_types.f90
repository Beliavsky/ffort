program p
implicit none
integer::a(0)
integer(8)::b(0)
real::c(0)
real(8)::d(0)
logical::e(0)
character(3)::f(0)
a=[integer::]
b=[integer(8)::]
c=[real::]
d=[real(kind=8)::]
e=[logical::]
f=[character(3)::]
if(size(a)+size(b)+size(c)+size(d)+size(e)+size(f)/=0) error stop 1
if(kind([integer::])/=4.or.kind([integer(8)::])/=8) error stop 2
if(kind([real::])/=4.or.kind([real(8)::])/=8) error stop 3
if(kind([logical::])/=4.or.len([character(3)::])/=3) error stop 4
print *, 'PASS' 
end program
