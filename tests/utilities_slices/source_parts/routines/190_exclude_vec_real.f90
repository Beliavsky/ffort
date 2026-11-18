function exclude_vec_real(ivec,iexcl) result(jvec)
! return in jvec the elements in ivec except those in position iexcl(:)
real(kind=dp), intent(in)            :: ivec(:)
integer      , intent(in), optional  :: iexcl(:)
real(kind=dp), allocatable :: jvec(:)
integer              :: i,n,nuse,iuse(size(ivec))
n  = size(ivec)
if (present(iexcl)) then
   nuse = 0
   do i=1,n
      if (all(iexcl /= i)) then
         nuse = nuse + 1
         iuse(nuse) = i
      end if
   end do
   call copy_alloc_vec_real(ivec(iuse(:nuse)),jvec)
else
   allocate (jvec(n))
   jvec = ivec
end if
end function exclude_vec_real
!
! function exclude_matrix_int(imat,irow_excl,icol_excl) result(jmat)
! integer, intent(in)           :: imat(:,:)
! integer, intent(in), optional :: irow_excl(:),icol_excl(:)
! integer, allocatable          :: jmat(:,:)
! call copy_alloc_matrix_int(imat,jmat, &
!      exclude_vec_int(irange(1,size(imat,1)),irow_excl),exclude_vec_int(irange(1,size(imat,2)),icol_excl))
! end function exclude_matrix_int
!
