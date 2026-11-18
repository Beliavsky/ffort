program p
implicit none
real(8)::x(0),y(0)
y=bessel_yn(999,x)+1d0
print *,size(y),kind(y)
end program
