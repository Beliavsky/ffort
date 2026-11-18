program p
implicit none
integer::u,ios
character(2)::a(3)
real,parameter::r=2
u=27
a='--'
read(u,'(a)',iostat=ios)a(int(r))
if(ios/=0)stop 1
if(a(1)/='--'.or.a(2)/='xy'.or.a(3)/='--')stop 2
print '(a)',a(2)
end program
