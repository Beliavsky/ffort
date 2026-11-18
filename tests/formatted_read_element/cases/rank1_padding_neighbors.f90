program main
implicit none
integer::u=27,ios
character(4)::a(3)
a(1)='KEEP';a(3)='LAST'
read(u,'(a)',iostat=ios)a(2)
if(ios/=0)stop 1
print '(a)',a

end program
