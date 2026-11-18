function common_value(ivec,idef) result(jj)
! if all elements of ivec(:) have the same value, return it; otherwise return a default value
integer, intent(in)           :: ivec(:)
integer, intent(in), optional :: idef
integer                       :: jj
jj = merge(minval(ivec),default(0,idef),minval(ivec)==maxval(ivec))
end function common_value
!
