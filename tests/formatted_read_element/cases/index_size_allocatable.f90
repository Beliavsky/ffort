program p
implicit none
integer::u,ios
character(2)::a(3)
integer,allocatable::b(:)
u=27
a='--'
allocate(b(2))
read(u,'(a)',iostat=ios)a(size(b))
if(ios/=0)stop 1
if(a(1)/='--'.or.a(2)/='xy'.or.a(3)/='--')stop 2
print '(a)',a(2)
end program
