program p
implicit none
print *,erf(2d0),bessel_jn(3,2d0)
contains
real(8) function erf(x)
real(8),intent(in)::x
erf=x+1d0
end function
real(8) function bessel_jn(n,x)
integer,intent(in)::n
real(8),intent(in)::x
bessel_jn=n+x
end function
end program
