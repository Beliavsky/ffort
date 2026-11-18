program p
implicit none
integer::i,a(3)
i=40
a=[(i+observe(),i=1,3)]
print '(4i4)',a,i
contains
integer function observe()
observe=i
end function
end program
