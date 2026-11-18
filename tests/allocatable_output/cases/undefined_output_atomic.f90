program combined
implicit none
integer,allocatable::a(:),b(:)
a=[1,2]
allocate(b(1))
print '(2i4)',a,b
end program
