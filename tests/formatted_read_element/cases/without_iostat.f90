program main
implicit none
integer::u=27,ios
character(4)::a(2)
a(1)='KEEP'
read(u,'(a)')a(2)
print '(a)',a

end program
