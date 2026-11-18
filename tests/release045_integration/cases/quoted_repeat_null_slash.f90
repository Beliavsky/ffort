program p
implicit none
integer::s
character(100)::line
character(5)::a(3)
real(8)::v(2)
a='keep'
v=0
line='3 4 2*"a,b", /'
read(line,*,iostat=s)v,a
if(s/=0)error stop 1
print '(3(a,1x),f4.1)',a,norm2(v)
end program
