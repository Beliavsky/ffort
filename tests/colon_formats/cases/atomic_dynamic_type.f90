program p
implicit none
integer::a(2),n
n=2
a=[1,2]
print '("PREFIX",i0:,a)',a(:n)
end program
