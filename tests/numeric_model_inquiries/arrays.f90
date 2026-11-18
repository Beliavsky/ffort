program model_arrays
implicit none
real :: a(3),b(2,3),c(1,2,3),empty(0)
real(8) :: d(2,2)
integer(8) :: ia(2,2,2)
integer :: idx
print *,epsilon(a),tiny(b),huge(c),radix(ia)
print *,epsilon(empty),tiny(empty),huge(empty),radix(empty)
print *,epsilon(a(idx:idx)),tiny(b(:,idx)),huge(c(:,idx,:)),radix(ia(idx,:,:))
print *,epsilon(d+1.0d0),tiny([1.0,2.0]),huge(ia+1_8),radix(d)
print *,size([epsilon(a),tiny(b),huge(c)]),size([radix(ia)])
print *,kind(epsilon(d)),kind(huge(ia)),kind(radix(d))
end program
