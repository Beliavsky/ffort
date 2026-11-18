program p
implicit none
integer::i,a(4)
i=50
a=[(i,i=1,2),(i,i=4,5)]
print '(7i3)',a,lbound((a)),ubound((a)),i
end program
