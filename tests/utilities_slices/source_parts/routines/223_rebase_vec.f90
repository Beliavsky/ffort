function rebase_vec(xx,method,base) result(yy)
real(kind=dp)    , intent(in) :: xx(:)
character (len=*), intent(in) :: method
real(kind=dp)    , intent(in), optional   :: base
real(kind=dp)                 :: yy(size(xx))
if (size(xx) < 1) return
if (method == "shift") then
   yy = xx - default(xx(1),base)
else if (method == "divide") then
   yy = xx / default(xx(1),base)
else
   yy = xx
end if
end function rebase_vec
!
