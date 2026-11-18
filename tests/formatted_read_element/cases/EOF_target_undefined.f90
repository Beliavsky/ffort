program main
implicit none
integer::u=27,ios
character(2)::a(2)
a='xx'
read(u,'(a)',iostat=ios)a(1)
print '(a)',a(1)

end program
