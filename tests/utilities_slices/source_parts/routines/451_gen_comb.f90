subroutine gen_comb(n,k,imat)
! generate in rows of imat(:,:) all combinations of k things out of n
integer, intent(in)               :: n,k
integer, intent(out), allocatable :: imat(:,:)
if (k > n) then
   if (allocated(imat)) deallocate(imat)
   allocate (imat(0,k))
   return
end if
call combos(n,k)
call set_alloc(comb_mat,imat)
end subroutine gen_comb
!
