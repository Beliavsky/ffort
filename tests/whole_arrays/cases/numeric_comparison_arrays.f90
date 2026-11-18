program probe
implicit none
integer :: a(3), b(3)
logical :: c(3)
a(1)=1
a(2)=2
a(3)=3
b(1)=3
b(2)=2
b(3)=1
c=a<b
print *, c,a<=b,a==b,a/=b,a>b,a>=b
end program probe
