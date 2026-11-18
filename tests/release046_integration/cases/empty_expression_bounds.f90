program p
implicit none
real::a(0,3)
print '(4i3)',lbound(a+norm2([3.,4.])),ubound(a+norm2([3.,4.]))
end program
