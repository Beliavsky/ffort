program main
implicit none
real::a(3)
integer::n
a=[1.0,2.0,3.0]
n=3
print '(2(i0))',a(:n)
end program
