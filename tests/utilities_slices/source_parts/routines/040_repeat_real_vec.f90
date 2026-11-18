pure function repeat_real_vec(n,x) result(xvec)
! repeat 1-D array of real variables with x repeated n times
integer, intent(in)       :: n
real(kind=dp), intent(in) :: x(:)
real(kind=dp)             :: xvec(n*size(x))
integer                   :: i,j,k
i = 0
do j=1,n
   do k=1,size(x)
      i = i + 1
      xvec(i) = x(k)
   end do
end do
end function repeat_real_vec
!
