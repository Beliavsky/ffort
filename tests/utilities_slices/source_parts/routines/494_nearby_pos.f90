pure recursive function nearby_pos(ivec,bad_val,method) result(jvec)
! return in jvec(:) the values in ivec(:), replacing bad values with ones found nearby
integer          , intent(in) :: ivec(:)
integer          , intent(in) :: bad_val
character (len=*), intent(in) :: method
integer                       :: jvec(size(ivec))
integer                       :: i,j,n
if (method == "earlier_then_later") then
   jvec = nearby_pos(nearby_pos(ivec,bad_val,"earlier"),bad_val,"later")
   return
end if
n = size(ivec)
jvec = ivec
do i=1,n
   if (ivec(i) == bad_val) then
      if (method == "earlier") then
         do j=i-1,1,-1
            if (ivec(j) /= bad_val) then
               jvec(i) = ivec(j)
               exit
            end if
         end do
      else if (method == "later") then
         do j=i+1,n
            if (ivec(j) /= bad_val) then
               jvec(i) = ivec(j)
               exit
            end if
         end do
      end if
   end if
end do
end function nearby_pos
!
