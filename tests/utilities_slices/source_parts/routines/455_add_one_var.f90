subroutine add_one_var(nvar,iuse_init,iuse)
integer, intent(in)               :: nvar
integer, intent(in)               :: iuse_init(:)
integer, intent(out), allocatable :: iuse(:,:)
integer                           :: ivar,ncomb,juse(nvar,size(iuse_init)+1)
! print*,"iuse_init=",iuse_init," shape(juse)=",shape(juse) !! debug
ncomb = 0
do ivar=1,nvar
   if (all(iuse_init /= ivar)) then
      ncomb = ncomb + 1
      juse(ncomb,:) = [iuse_init,ivar]
   end if
end do
call set_alloc(juse(:ncomb,:),iuse)
end subroutine add_one_var
!
