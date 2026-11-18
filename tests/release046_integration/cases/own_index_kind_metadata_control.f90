program p
implicit none
integer::i,a(4)
a=[(i,i=1,kind(i+1))]
print '(4i3)',a
end program
