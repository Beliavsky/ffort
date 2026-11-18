program probe
implicit none
integer :: a(3),lo,hi,s
a=1
lo=3
hi=0
s=-1
print *, a(lo:hi:s)
end program probe
