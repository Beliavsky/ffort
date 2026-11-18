subroutine true_pos_alloc(tf,ipos)
! return in ipos the true positions of tf(:)
logical, intent(in)               :: tf(:)
integer, intent(out), allocatable :: ipos(:)
integer                           :: jpos(size(tf)),ntrue
call true_pos_count(tf,jpos,ntrue)
allocate (ipos(ntrue))
ipos = jpos(:ntrue)
end subroutine true_pos_alloc
!
