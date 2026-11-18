program p
implicit none
integer::a(2,2)
a=reshape([1,2,3,4],[2,2])
print '(*(o2.2))',a
end program
