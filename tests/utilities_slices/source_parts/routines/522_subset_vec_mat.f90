subroutine subset_vec_mat(sym_find,sym,xmat,sym_found,ymat)
! return in sym_found the elements of sym_find found in sym and in ymat the corresponding columns of xmat
character (len=*), intent(in)               :: sym_find(:)
character (len=*), intent(in)               :: sym(:)       ! (nsym)
real(kind=dp)    , intent(in)               :: xmat(:,:)    ! (n,nsym)
character (len=*), intent(out), allocatable :: sym_found(:) ! (nfound)
real(kind=dp)    , intent(out), allocatable :: ymat(:,:)    ! (n,nfound)
integer                       , allocatable :: iuse(:)
integer                                     :: ipos(size(sym_find))
ipos = sym_find .posin. sym
call set_alloc(true_pos(ipos > 0), iuse)
call set_alloc(sym_find(iuse),sym_found)
call set_alloc(xmat(:,pack(ipos,ipos>0)),ymat)
end subroutine subset_vec_mat
!
