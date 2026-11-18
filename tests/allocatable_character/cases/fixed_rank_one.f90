program main
implicit none
character(4),allocatable::a(:),b(:)
allocate(a(-2:0))
a=[character(6)::'abcdef','xy','z']
b=a
print '(3a6)',a
print *,len(b),lbound(b,1),ubound(b,1)
a(0:-2:-1)=a
print '(3a6)',a

end program
