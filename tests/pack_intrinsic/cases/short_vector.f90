program main
implicit none
integer :: a(3)=[1,2,3],v(2)=[4,5]
logical :: m(3)
m=.true.
print *,pack(a,m,v)
end program
