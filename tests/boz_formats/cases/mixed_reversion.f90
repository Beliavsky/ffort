program p
implicit none
integer::a(3)
a=[1,15,16]
print '(i3,1x,z2.2,1x,b5.5)',a(1),a(2),a(3),a(3),a(2),a(1)
end program
