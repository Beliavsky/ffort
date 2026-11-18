function indexx_order_real(xx,order) result(iord)
! return iord(:) such that xx(iord) has specified order
real(kind=dp)    , intent(in)           :: xx(:)
character (len=*), intent(in), optional :: order ! "a" for ascending, "d" for descending, "" or "none" for original ordering
integer                                 :: iord(size(xx))
integer                                 :: i
character (len=1)                       :: ch
forall (i=1:size(xx)) iord(i) = i
if (.not. present(order)) return
if (order == "" .or. order == "none") return
ch = order(1:1)
if (ch == "a" .or. ch == "A") then
   iord = indexx(xx)
else if (ch == "d" .or. ch == "D") then
   iord = indexx(-xx)
end if
end function indexx_order_real
!
