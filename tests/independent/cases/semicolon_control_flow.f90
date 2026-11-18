program probe
  implicit none
  integer :: i, s
  s=0; do i=1,3; if (i>1) then; s=s+i; else; s=s+10; end if; end do; print *,s,i
end program probe
