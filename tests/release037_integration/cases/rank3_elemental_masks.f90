program main
implicit none
real(8)::a(2,1,2),b(2,1,2)
integer::e(2,1,2),codes(2,1,2)
character(1)::c(2,1,2)
logical::mask(2,1,2)
a(:,1,1)=[1d0,2d0]
a(:,1,2)=[4d0,8d0]
e=exponent(a)
b=set_exponent(fraction(a),e)
c(:,1,1)=['A','B']
c(:,1,2)=['C','D']
codes=iachar(c)
mask=isnan(nearest(a,1d0))
write(*,'("rank3:",7(1x,i0))')size(b,1),size(b,2),size(b,3),count(b(:,:,1)==a(:,:,1))+count(b(:,:,2)==a(:,:,2)), &
sum(e(:,:,1))+sum(e(:,:,2)),sum(codes(:,:,1))+sum(codes(:,:,2)),count(mask(:,:,1))+count(mask(:,:,2))
end program
