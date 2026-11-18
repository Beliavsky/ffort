function true_pos_few(npos,tf) result(ipos)
! return in ipos(1:npos) the positions of the first npos true elements in tf(:)
integer, intent(in) :: npos
logical, intent(in) :: tf(:)
integer             :: ipos(npos)
integer             :: i,j,ntf
ipos = 0
j    = 0
ntf  = size(tf)
if (npos < 1) return
do i=1,ntf
   if (tf(i)) then
      j = j + 1
      ipos(j) = i
      if (j == npos) return
   end if
end do
end function true_pos_few
!
