subroutine get_sub_vec_real(xx,iget,yy,ygood,xgood)
! set yy = xx(iget) where iget is in bounds and xgood is .true.
real(kind=dp), intent(in)           :: xx(:)    ! (n)
integer      , intent(in)           :: iget(:)  ! (nget)
logical      , intent(in), optional :: xgood(:) ! (n)
real(kind=dp), intent(out)          :: yy(:)    ! (nget)
logical      , intent(out)          :: ygood(:) ! (nget)
integer                             :: i,iuse,nget,n
character (len=*), parameter        :: msg="in get_sub_vec_real, "
logical      , allocatable          :: xgood_(:)
n    = size(xx)
nget = size(iget)
if (size(yy) /= nget .or. size(ygood) /= nget) then
   print*,msg,"size(iget), size(yy), size(ygood) =",nget,size(yy),size(ygood)," should all be equal, STOPPING"
   stop
else if (present(xgood)) then
   if (size(xgood) /= n) then
      print*,msg,"size(xx), size(xgood) =",n,size(xgood)," should be equal, STOPPING"
      stop
   end if
end if
if (present(xgood)) then
   call set_alloc(xgood,xgood_)
else
   allocate (xgood_(n))
   xgood_ = .true.
end if
do i=1,nget
   ygood(i) = .false.
   iuse = iget(i)
   if (iuse > 0 .and. iuse <= n) then
      if (xgood_(iuse)) then
         yy(i) = xx(iuse)
         ygood(i) = .true.
      end if
   end if
end do
end subroutine get_sub_vec_real
!
