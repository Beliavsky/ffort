program main
implicit none
real(8)::a(0,2,3),b(0,2,3),s
integer::e(0,2,3)
character(1)::c(0,2,3)
logical::mask(0,2,3)
s=0d0
b=nearest(set_exponent(fraction(a),huge(0_8)),s)
e=exponent(spacing(b))
mask=isnan(b)
write(*,'("empty:",8(1x,i0))')size(b,1),size(b,2),size(b,3),size(e),size(iachar(c,8)),count(mask(:,:,1)),sum(e(:,:,1)),kind(b)
end program
