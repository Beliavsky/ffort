subroutine fill_vec(good,xvec,nfilled,fill_initial)
! fill data in xvec(:) using earlier data when data is not good
logical      , intent(in)    :: good(:)
real(kind=dp), intent(inout) :: xvec(:)
integer      , intent(out), optional :: nfilled ! # of values filled
integer                      :: i,i1,n
real(kind=dp)                :: xgood
logical, intent(in), optional :: fill_initial
logical                      :: found_good_value
nfilled = 0
n = size(good)
if (size(xvec) /= n) then
   write (*,*) "in fill_vec, size(good), size(xvec) =",size(good),size(xvec)," must be equal, STOPPING"
   stop
end if
found_good_value = .false.
if (default(.false.,fill_initial)) then
   i1 = first_true(good)
   if (i1 > 1) then
      xgood = xvec(i1)
      xvec(1:i1-1) = xgood
      nfilled = nfilled + i1 - 1
      found_good_value = .true.
   else
      i1 = 1
   end if
else
   i1 = 1
end if
do i=i1,n
   if (good(i)) then
      xgood = xvec(i)
      found_good_value = .true.
   else
      if (i > 1 .and. found_good_value) then
         xvec(i) = xgood
         nfilled = nfilled + 1
      end if
   end if
end do
end subroutine fill_vec
!
