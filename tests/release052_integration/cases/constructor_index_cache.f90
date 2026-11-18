program main
implicit none
character(3)::x(3)
integer::a(3),i
x=['axx','bxb','xxc']
i=9
a=[(index(x([i]),'x'),i=1,3)]
print '(3(i0,1x),i0)',a,i
end program
