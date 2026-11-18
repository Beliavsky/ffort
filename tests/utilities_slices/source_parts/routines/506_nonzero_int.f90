function nonzero_int(ii) result(inz)
! return the nonzero values of ii(:)
integer, intent(in)  :: ii(:)
integer, allocatable :: inz(:)
call set_alloc(pack(ii,ii/=0.0_dp),inz)
end function nonzero_int
!
