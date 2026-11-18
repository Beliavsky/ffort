program probe
implicit none
integer :: a(2),b(2)
a=1
b(1)=1
b(2)=0
print *,99
print *,"partial",a,a/b
end program probe
