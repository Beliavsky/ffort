program p

implicit none
integer::a(2,1,1),b(1,1,1)
a=0
b=maskr(4)
a([1],:,:)=b
print '(i0)',a(1,1,1)
end program
