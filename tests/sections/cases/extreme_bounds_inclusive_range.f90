program probe
implicit none
integer :: a(-2147483647:(-2147483647+2)),b(2147483645:2147483647)
a=3
b(2147483647:2147483645:-1)=a(:)
print *, a(::2),b(2147483647:2147483645:-2)
end program probe
