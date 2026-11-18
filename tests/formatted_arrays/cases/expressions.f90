program main
implicit none
integer::a(5)=[1,2,3,4,5]
print '(2i4)',2*a+1
print '(2i4)',pack(a,a>2)
print '(2i4)',[9,a,8]

end program
