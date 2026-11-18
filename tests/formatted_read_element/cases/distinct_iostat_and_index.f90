program main
implicit none
integer::u=27,ios,i=2
character(2)::a(3)
a='--'
read(u,'(a)',iostat=ios)a(i)
if(ios/=0.or.i/=2)stop 1
print '(a)',a
end program
