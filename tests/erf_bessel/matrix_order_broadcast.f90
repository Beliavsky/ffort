program p
implicit none
integer::n(2,2)
n=reshape([0,1,5,32],[2,2])
print *,bessel_jn(x=32d0,n=n)
print *,bessel_yn(n,32d0)
end program
