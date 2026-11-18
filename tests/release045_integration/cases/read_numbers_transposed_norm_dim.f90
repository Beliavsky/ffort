program p
implicit none
integer::s
character(60)::line
real(8)::a(2,2),b(2,2)
line='3 4 5 12'
read(line,*,iostat=s)a
if(s/=0)error stop 1
b=transpose(a)
print '(2f8.2)',norm2(b,dim=2)
end program
