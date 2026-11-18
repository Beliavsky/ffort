function demean_vec(xx,cdemean) result(xdm)
! demean a vector
real(kind=dp), intent(in)           :: xx(:)
real(kind=dp), intent(in), optional :: cdemean
real(kind=dp)                       :: xdm(size(xx))
if (size(xx) > 0) then
   if (present(cdemean)) then
      xdm = xx - cdemean*sum(xx)/size(xx)
   else
      xdm = xx - sum(xx)/size(xx)
   end if
end if
end function demean_vec
!
