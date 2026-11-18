program main
implicit none
integer::u=27,ios
character(4)::a(2)
read(u,'(a)',iostat=ios)a(idx())
print '(a)',a(2)
contains
pure integer function idx()
idx=2
end function
end program
