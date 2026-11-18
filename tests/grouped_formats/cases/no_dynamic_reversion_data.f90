program main
implicit none
integer::a(2),n
a=[1,2]
n=2
print '(i0,2("tail"))',a(:n)
end program
