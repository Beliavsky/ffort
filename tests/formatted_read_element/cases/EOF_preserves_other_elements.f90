program main
implicit none
integer::u=27,ios
character(4)::a(3)
a='KEEP'
read(u,'(a)',iostat=ios)a(2)
if(ios>=0)stop 1
print '(a)',a(1),a(3)

end program
