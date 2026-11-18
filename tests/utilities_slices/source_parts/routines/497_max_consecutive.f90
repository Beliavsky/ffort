function max_consecutive(tf) result(nmax)
logical, intent(in) :: tf(:)
integer             :: nmax
integer             :: i,ntrue
nmax = 0
ntrue = 0
do i=1,size(tf)
   if (tf(i)) then
      ntrue = ntrue + 1
   else
      ntrue = 0
   end if
   nmax = max(nmax,ntrue) 
end do
end function max_consecutive
!
