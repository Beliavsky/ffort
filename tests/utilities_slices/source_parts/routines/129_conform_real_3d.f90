function conform_real_3d(xx,yy) result(tf)
! check that two matrices are conformable
real(kind=dp), intent(in) :: xx(:,:,:),yy(:,:,:)
logical                   :: tf
tf = all(shape(xx) == shape(yy))
end function conform_real_3d
!
