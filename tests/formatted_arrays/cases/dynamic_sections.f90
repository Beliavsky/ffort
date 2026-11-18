program main
implicit none
integer::a(6)=[1,2,3,4,5,6],i,j
i=2
j=6
print '(2i3)',a(i:j:2)
print '(2i3)',a(j:i:-2)

end program
