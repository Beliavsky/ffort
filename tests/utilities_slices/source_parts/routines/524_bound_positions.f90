pure subroutine bound_positions(xpos,min_pos,max_pos,max_gross)
! bound indvidual positions between min_pos and max_pos and the gross position below max_gross
real(kind=dp), intent(inout)        :: xpos(:)
real(kind=dp), intent(in), optional :: min_pos,max_pos
real(kind=dp), intent(in), optional :: max_gross
real(kind=dp)                       :: gross_pos
if (present(min_pos)) xpos = max(min_pos,xpos)
if (present(max_pos)) xpos = min(max_pos,xpos)
if (present(max_gross)) then
   if (max_gross > 0.0_dp) then
      gross_pos = sum(abs(xpos))
      if (gross_pos > max_gross) xpos = xpos*max_gross/gross_pos
   else
      xpos = 0.0_dp
   end if
end if
end subroutine bound_positions
!
